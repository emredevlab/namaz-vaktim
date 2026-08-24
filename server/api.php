<?php
/**
 * Namaz Vaktim - Tek dosyalik Aladhan proxy'si (Kapadokya Bilisim)
 *
 * Kullanim:
 *   api.php?latitude=38.6244&longitude=34.7239[&date=DD-MM-YYYY]
 *
 * - date verilmezse bugunun tarihi kullanilir (sunucu saat dilimi).
 * - Yukari akis SABIT: https://api.aladhan.com/v1/timings/{date}?method=13
 *   (disaridan URL/path enjeksiyonu mumkun degildir).
 * - Yanit Aladhan'dan OLDUGU GIBI gecirilir (passthrough); uygulamanin
 *   cift semali parser'i Aladhan semasini dogrudan anlar.
 * - Ayni gun + koordinat istekleri 3 saat boyunca disk cache'ten
 *   servis edilir (sys_get_temp_dir altinda md5 anahtarli dosya).
 * - Gereksinimler: PHP 7.4+, cURL uzantisi (outbound HTTPS izinli).
 */

declare(strict_types=1);

/* ---------------------------------------------------------------------------
 | Yapilandirma
 ------------------------------------------------------------------------- */

const NV_UPSTREAM_BASE = 'https://api.aladhan.com/v1/timings/';
const NV_CALC_METHOD   = '13';    // 13 = Diyanet Isleri Baskanligi (Turkiye)
const NV_CACHE_TTL     = 10800;   // 3 saat (saniye)
const NV_CURL_TIMEOUT  = 10;      // saniye
const NV_UA            = 'NamazVaktim-Proxy/1.0 (+https://kapadokyabulut.com.tr)';

/* ---------------------------------------------------------------------------
 | Basliklar (her yanitta)
 ------------------------------------------------------------------------- */

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: no-referrer');

// CORS: mobil uygulama icin zararsiz; web istemcileri de dogrudan cagirabilir.
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Max-Age: 86400');

// Preflight
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    header('Cache-Control: no-store');
    http_response_code(204);
    exit;
}

// CDN/tarayici seviyesinde 1 saat onbellek (sunucu disi)
header('Cache-Control: public, max-age=3600');

/* ---------------------------------------------------------------------------
 | Yardimci fonksiyonlar
 ------------------------------------------------------------------------- */

/**
 * Standart JSON hata govdesi yazip cikar.
 */
function nvJsonError(string $message, int $httpCode): void
{
    http_response_code($httpCode);
    echo json_encode(
        array(
            'code'   => $httpCode,
            'status' => 'ERROR',
            'error'  => $message,
        ),
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
    );
    exit;
}

/**
 * Float parametreyi dogrular (-90..90 / -180..180 araligi dahil).
 */
function nvValidateFloat(string $raw, string $name, float $min, float $max): float
{
    if ($raw === '' || !is_numeric($raw)) {
        nvJsonError($name . ' parametresi sayisal olmalidir.', 400);
    }

    $value = (float) $raw;

    if (!is_finite($value) || $value < $min || $value > $max) {
        nvJsonError(
            $name . ' parametresi ' . $min . ' ile ' . $max . ' arasinda olmalidir.',
            400
        );
    }

    return $value;
}

/**
 * Upstream'e sabit URL uzerinden cURL ile baglanir.
 * Donus: [gövde (string), httpDurumu (int)]
 */
function nvFetchUpstream(string $url): array
{
    if (!function_exists('curl_init')) {
        nvJsonError('Sunucuda cURL uzantisi yuklu degil. Yoneticiyle gorusun.', 500);
    }

    $ch = curl_init($url);
    if ($ch === false) {
        nvJsonError('cURL baslatilamadi.', 500);
    }

    curl_setopt_array(
        $ch,
        array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_CONNECTTIMEOUT => NV_CURL_TIMEOUT,
            CURLOPT_TIMEOUT        => NV_CURL_TIMEOUT,
            CURLOPT_USERAGENT      => NV_UA,
            CURLOPT_HTTPHEADER     => array('Accept: application/json'),
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
        )
    );

    $body = curl_exec($ch);

    if (!is_string($body)) {
        $reason = curl_error($ch);
        curl_close($ch);
        nvJsonError('Aladhan servisine ulasilamadi: ' . $reason, 502);
    }

    $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return array($body, $status);
}

/* ---------------------------------------------------------------------------
 | 1) Parametre dogrulama
 ------------------------------------------------------------------------- */

$latitudeRaw  = isset($_GET['latitude'])  ? trim((string) $_GET['latitude'])  : '';
$longitudeRaw = isset($_GET['longitude']) ? trim((string) $_GET['longitude']) : '';

if ($latitudeRaw === '' || $longitudeRaw === '') {
    nvJsonError(
        'latitude ve longitude zorunludur. Ornek: '
            . 'api.php?latitude=38.6244&longitude=34.7239',
        400
    );
}

$latitude  = nvValidateFloat($latitudeRaw,  'latitude',  -90.0, 90.0);
$longitude = nvValidateFloat($longitudeRaw, 'longitude', -180.0, 180.0);

// date: bos ise bugun; yoksa katı DD-MM-YYYY + gercek tarih kontrolu
$dateRaw = isset($_GET['date']) ? trim((string) $_GET['date']) : '';
if ($dateRaw === '') {
    $dateRaw = date('d-m-Y');
}

if (!preg_match('/^[0-9]{2}-[0-9]{2}-[0-9]{4}$/', $dateRaw)) {
    nvJsonError('date parametresi DD-MM-YYYY biciminde olmalidir (ornek: 24-08-2026).', 400);
}

$parsedDate = DateTime::createFromFormat('!d-m-Y', $dateRaw);
if ($parsedDate === false || $parsedDate->format('d-m-Y') !== $dateRaw) {
    nvJsonError('date parametresi gecersiz bir tarihe isaret ediyor: ' . $dateRaw, 400);
}

/* ---------------------------------------------------------------------------
 | 2) Dosya onbellek (md5 anahtarli, 3 saat TTL)
 |    Anahtar girisleri float'a normalize edilmis degerlerden uretilir:
 |    "38.62440" ile "38.6244" ayni anahtari uretir.
 ------------------------------------------------------------------------- */

$cacheKey  = md5('nv-proxy-v1|' . $dateRaw . '|' . $latitude . '|' . $longitude . '|' . NV_CALC_METHOD);
$cacheFile = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'nv_proxy_' . $cacheKey . '.json';

clearstatcache(true, $cacheFile);

if (is_file($cacheFile)) {
    $mtime = @filemtime($cacheFile);
    if ($mtime !== false && (time() - $mtime) < NV_CACHE_TTL) {
        $cachedBody = @file_get_contents($cacheFile);
        if (is_string($cachedBody) && $cachedBody !== '') {
            header('X-Cache: HIT');
            echo $cachedBody;
            exit;
        }
    }
}

/* ---------------------------------------------------------------------------
 | 3) Upstream cagrisi + passthrough
 |    Sadece gecerli HTTP 200 + JSON yanitlar onbelleklenir; gecici
 |    Aladhan hatalari 3 saatligine onbellege yazilmaz.
 ------------------------------------------------------------------------- */

$query = http_build_query(
    array(
        'latitude'  => $latitude,
        'longitude' => $longitude,
        'method'    => NV_CALC_METHOD,
    )
);

// $dateRaw regex + gercek-tarih kontrolunden gecti; rawurlencode ek guvence.
$url = NV_UPSTREAM_BASE . rawurlencode($dateRaw) . '?' . $query;

list($responseBody, $upstreamStatus) = nvFetchUpstream($url);

if ($upstreamStatus !== 200) {
    nvJsonError(
        'Yukari akis servisi (Aladhan) ' . $upstreamStatus . ' dondurdu.',
        502
    );
}

json_decode($responseBody);
if (json_last_error() !== JSON_ERROR_NONE) {
    nvJsonError('Yukari akis servisi gecersiz JSON dondurdu.', 502);
}

@file_put_contents($cacheFile, $responseBody, LOCK_EX); // en iyi caba; hata olursa sessiz gec

header('X-Cache: MISS');
echo $responseBody;
exit;
