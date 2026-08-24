# Deploy Kiti — api.kapadokyabulut.com.tr

Bu klasör, `api.kapadokyabulut.com.tr` adresini kendi sunucunuzda
(**5.9.8.232** / `server1.kapadokyabilisim.com`) yayına almak için gereken her şeyi içerir.

| Dosya | Amaç |
|---|---|
| `api.php` | Tek dosyalık PHP proxy'si (PHP 7.4+). Aladhan'ı çağırır, yanıtı olduğu gibi geçirir, 3 saat disk cache kullanır. |
| `nginx.conf.example` | Bare nginx kurulumları için vhost örneği (Plesk/cPanel'de gerekmez, panel kullanın). |

**Proxy'nin yaptığı iş:** Uygulamanın parser'ı Aladhan şemasını
(`data.timings.Fajr...`, `data.date.hijri...`) zaten anlıyor (çift şemalı).
`api.php` yanıtı **değiştirmeden geçirdiği** için uygulamada tek yapılması
gereken API adresini bu domaine yönlendirmektir — kod değişikliği yoktur.

---

## a) DNS / Subdomain

**Plesk (önerilen yol):**
1. Abonelik: `kapadokyabulut.com.tr` → **Websites & Domains → Add Subdomain**.
2. Subdomain adı: `api`, belge kökü örn. `/httpdocs/api` (aşağıda tutarlı olanı kullanın).
3. Plesk DNS kaydını otomatik oluşturur.

**cPanel:**
1. **Domains → Create A New Domain** → `api.kapadokyabulut.com.tr`,
   belge kökü: `~/public_html/api`.

**Elle DNS (bare sunucu):**
```
api.kapadokyabulut.com.tr.    IN  A  5.9.8.232
```

Doğrulama (yayılmadan hemen önce/sonra):
```bash
nslookup api.kapadokyabulut.com.tr
# -> Address: 5.9.8.232 olmali
```

## b) TLS (Let's Encrypt)

**Plesk:** Subdomain sayfasında → **SSL/TLS Certificates → Install a free basic certificate (Let's Encrypt)** → sadece `api.kapadokyabulut.com.tr` seçili olsun → **Install/Renew**. "Redirect to https" kutusunu işaretleyin.

**Bare nginx:**
```bash
certbot --nginx -d api.kapadokyabulut.com.tr
```
Certbot vhost'taki `ssl_certificate` satırlarını doldurur ve yenileme timer'ını kurar (`systemctl list-timers | grep certbot` ile doğrulayın).

## c) api.php'yi Yerleştirme + Sözdizimi Kontrolü

1. `server/api.php` dosyasını subdomain'in **belge köküne** yükleyin:
   - Plesk: `/var/www/vhosts/kapadokyabulut.com.tr/httpdocs/api/api.php`
   - cPanel: `~/public_html/api/api.php`
   - Bare nginx: `nginx.conf.example` içindeki `root ...` yoluyla aynı yer.
2. İzinler: `644` dosya; klasör `755`. Sahibi web kullanıcısı olsun.
3. Sunucuda sözdizimini doğrulayın:
   ```bash
   php -l /path/to/httpdocs/api/api.php
   # -> "No syntax errors detected" beklenir
   ```
4. PHP sürümü: panelde subdomain için **PHP 7.4 veya üstü** seçin (8.x önerilir) ve `curl` uzantısının etkin olduğunu kontrol edin:
   ```bash
   php -m | grep -i curl
   ```

## d) Test

```bash
curl -i 'https://api.kapadokyabulut.com.tr/api.php?latitude=38.6244&longitude=34.7239&date=24-08-2026'
```

Beklenen:
- `HTTP/2 200`, `Content-Type: application/json; charset=utf-8`
- İlk istekte `X-Cache: MISS`, sonraki 3 saat içindeki aynı istekte `X-Cache: HIT`
- Gövde Aladhan JSON'u: `{"code":200,"status":"OK","data":{"timings":{"Fajr":"04:39",...}}}`

Hata yolları da test edin:

```bash
# Koordinat eksik -> HTTP 400 + {"error": "..."}
curl -i 'https://api.kapadokyabulut.com.tr/api.php'

# Gecersiz enlem -> HTTP 400
curl -i 'https://api.kapadokyabulut.com.tr/api.php?latitude=999&longitude=10'

# Gecersiz tarih bicimi -> HTTP 400
curl -i 'https://api.kapadokyabulut.com.tr/api.php?latitude=38.6244&longitude=34.7239&date=2026-08-24'
```

Cache'i elle temizlemek gerekirse (sunucuda):
```bash
rm -f "$(php -r 'echo sys_get_temp_dir();')"/nv_proxy_*.json
```

## e) Uygulamaya Geçiş (tek satır)

`assets/config/app.production.json` dosyasında:

```json
"endpoints": {
  "api": "https://api.kapadokyabulut.com.tr",
  ...
}
```

> Not: Bu depoda `assets/config/app.production.json` **zaten** bu adresi
> gösteriyor; ek değişiklik gerekmez. Başka bir değer yazılıysa tek satır
> olarak yukarıdaki gibi güncelleyin. Parser, proxy passthrough'undan gelen
> Aladhan şemasını doğrudan anlar.

Sonrasında uygulamayı normal akışla derleyin/yayınlayın.

## f) Sorun Giderme

| Belirti | Olası neden | Çözüm |
|---|---|---|
| `403 Forbidden` (WAF/ModSecurity) | Panel WAF'ı sorgu desenini yanlışlıkla engelliyor | Plesk: Web Application Firewall → kural beyaz listesi; ModSecurity loglarına bakın (`/var/log/modsec_audit.log`). `api.kapadokyabulut.com.tr` için kural istisnası ekleyin |
| Kod düz metin basıyor / `<?` kaynakta görünüyor | Kısa etiket/PHP işlenmiyor | `api.php` `<?php` ile başlar (short tag kullanmaz); PHP'nin çalıştığını ve dosyanın `.php` uzantılı olduğunu doğrulayın |
| `Aladhan servisine ulasilamadi: Could not resolve host` | Outbound DNS kapalı | `/etc/resolv.conf`'a `nameserver 8.8.8.8` ekleyin veya hosting sağlayıcısına başvurun |
| `Aladhan servisine ulasilamadi: Connection timed out` / cURL yok | Outbound cURL/HTTPS engelli (paylaşımlı hosting'te yaygın) | Panelde "outbound PHP connections" iznini açtırın; açtıramıyorsanız sağlayıcının HTTP proxy'sini `CURLOPT_PROXY` ile eklemek tek alternatif |
| `502 Yukari akis servisi (Aladhan) 429 dondurdu` | Aladhan hız limiti | Normal koşullarda cache (3 saat) bunu önler; ani trafikte CDN (Cloudflare) arkasına alın |
| `500 Sunucuda cURL uzantisi yuklu degil` | PHP curl eklentisi kapalı | `php -m \| grep -i curl`; Plesk/cPanel PHP ayarlarından `curl` uzantısını etkinleştirin |
| Sertifika hatası (`SSL certificate problem: unable to get local issuer certificate`) | Sunucunun CA paketi eski/eksik (api.php TLS doğrulamasını **bilerek** kapatmaz) | Debian/Ubuntu: `apt-get install --reinstall ca-certificates`; ayrıca `php.ini`'de `curl.cainfo=/etc/ssl/certs/ca-certificates.crt` ayarlanabilir |
| Cache hiç HIT olmuyor | Temp dizini yazılabilir değil | `sys_get_temp_dir()` çıktısının yazılabilirliğini `is_writable()` ile test edin; `open_basedir` kısıtını kontrol edin |

---

## Özet Kontrol Listesi

- [ ] DNS: `api.kapadokyabulut.com.tr` → `5.9.8.232`
- [ ] TLS: Let's Encrypt kurulu, HTTPS redirect açık
- [ ] `api.php` belge kökünde, `php -l` temiz
- [ ] `curl` testi 200 + `X-Cache: HIT` veriyor
- [ ] `assets/config/app.production.json` → `endpoints.api` doğru (zaten doğru)
- [ ] Uygulama yeniden derlendi/yayınlandı
