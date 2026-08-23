# namaz-vaktim — Release Checklist

Play Store'a sürüm çıkmadan önce aşağıdaki maddelerin tamamının kontrol edilmesi gerekir.

## 1. İmza (Keystore)

- İmza dosyası: `android/key.jks` — **zaten üretilmiş durumda** (`alias=namaz-vaktim`).
- Şifreler ve alias bilgisi `android/key.properties` içindedir.
- **BU DOSYALARI ASLA PAYLAŞMA / COMMIT ETME.** Her ikisi de `android/.gitignore` kapsamındadır (`key.properties`, `**/*.jks`, `**/*.keystore`).
- `key.properties` silinirse build otomatik olarak **debug imzaya düşer** (`android/app/build.gradle` içindeki fallback davranışı bilinçlidir). Bu durumda derleme başarılı görünür ama APK Play Store'a yüklenemez — release öncesi imzayı mutlaka doğrula.
- **Keystore'u kaybedersen uygulama Play Store'da asla güncellenemez; yeni bir uygulama kimliğiyle yeniden yayınlanması gerekir.** `android/key.jks` + `android/key.properties` kopyalarını güvenli bir yerde (şifreli yedek, şirket kasası vb.) sakla.

## 2. AdMob Kimlikleri

Gerçek kimliklerin girileceği **tek yer**: `assets/config/app.production.json`

| Alan | Açıklama | Format |
|---|---|---|
| `ads.androidAppId` | Uygulama kimliği | `ca-app-pub-XXXX~YYYY` (`~` ile) |
| `ads.appOpenId` | App Open reklam birimi | `ca-app-pub-XXXX/YYYY` (`/` ile) |
| `ads.bannerId` | Banner reklam birimi | `ca-app-pub-XXXX/YYYY` (`/` ile) |

Davranış:

- `androidAppId` **test kimliğiyle başlıyorsa** (`ca-app-pub-3940256099942544` öneki) Gradle manifest'e otomatik olarak Google test kimliğini yazar.
- Gerçek kimlik girildiğinde `manifestPlaceholders` üzerinden (`adsApplicationId`) otomatik olarak `AndroidManifest.xml`'e enjekte edilir — manifest'e elle dokunma.
- Reklam **birim kimliklerini** (`appOpenId`, `bannerId`) da testten gerçeğe çevirmeyi unutma; bunların çevrilmesi tamamen bu JSON dosyasına bağlıdır.

Kontrol: release öncesi `assets/config/app.production.json` içinde hiçbir değer `ca-app-pub-3940256099942544` ile başlamamalı.

## 3. Uygulama İkonu

- `android/app/src/main/res` altındaki tüm `mipmap-*` PNG'leri programatik üretildi (logo SVG'si — `assets/config/namaz_vaktim_logo.svg` — ile aynı tasarım).
- Tasarım ekibi yeni ikon verirse: aynı klasör yollarına, aynı boyutlarda PNG koyması yeterli:

```text
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png
├── mipmap-hdpi/ic_launcher.png
├── mipmap-xhdpi/ic_launcher.png
├── mipmap-xxhdpi/ic_launcher.png
└── mipmap-xxxhdpi/ic_launcher.png
```

- Uyarlamalı ikon (Android 8+) ek olarak şu dosyaları kullanır; ikon değişirse bunlar da güncellenmelidir:
  - `mipmap-*/ic_launcher_foreground.png` (ön plan katmanı, aynı yoğunluk seti)
  - `mipmap-anydpi-v26/ic_launcher.xml` (katman tanımı)

- Play Store listing ikonu (512×512): `store/icon-512.png`

## 4. WMM Manyetik Sapma Modeli

- Dosya: `lib/features/prayer/magnetic_declination.dart`
- Kullanılan model: **WMM2025** (NOAA NCEI, doi:10.25921/aqfd-sd83)
- Geçerlilik aralığı: **2025.0 – 2030.0**
- **2030'dan sonra** model WMM2030 katsayılarıyla güncellenmelidir. Güncellerken test dosyasındaki NOAA referans sapma değerlerini de yeni modele göre yenile.

## 5. Derleme ve İmza Doğrulama

```powershell
# Release APK
flutter build apk --release
```

- Çıktı: `build\app\outputs\flutter-apk\app-release.apk`
- **İlk derlemeden sonra imzayı doğrula** (debug imzalı fallback'i yakalamak için):

```bash
$ANDROID_HOME/build-tools/<surum>/apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

Sertifika parmak izinin keystore'a ait olduğunu teyit et; "debug" sertifikası görünüyorsa `key.properties` eksik demektir.

### mapping.txt Arşivi (R8)

Release derlemesi `minifyEnabled true` + `shrinkResources true` ile derlenir; bu yüzden her release için üretilen **ProGuard/R8 eşleme dosyası** saklanmalıdır:

- Çıktı: `build\app\outputs\mapping\release\mapping.txt`
- Play Console'da çökme/ANR raporlarının okunabilir olması için sürüm çıkarırken aynı dosyayı Play Console > Sürüm > App Bundle Explorer / Deobfuscation files bölümüne yükle.
- Ayrıca yerel arşiv kopyası al: örn. `store/mapping/mapping-v<surum>+<build>.txt` olarak sürüm numarasıyla sakla (her yeni sürümün mapping'i bir öncekinin üzerine YAZILMAZ — klasör içinde ayrı dosya tutulur).
- mapping.txt kaybedilirse o sürümün obfiske çökme raporları çözülemez; bu yüzden yükleme + yerel yedek ikisi de zorunludur.

## 6. Play Store Notları

- **targetSdk:** 36
- **İzin listesi (minimal):**
  - `INTERNET`
  - `ACCESS_NETWORK_STATE`
  - `ACCESS_COARSE_LOCATION`
  - `ACCESS_FINE_LOCATION`
  - `POST_NOTIFICATIONS`
  - `SCHEDULE_EXACT_ALARM`
- **Kamera / mikrofon izni YOK** — Play Console'daki izin beyanlarında buna göre doldur.
