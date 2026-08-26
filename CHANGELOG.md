# Changelog

Tüm önemli değişiklikler bu dosyada belgelenir. Sürümler [SemVer](https://semver.org/) ilkelerini izler; tarihler YYYY-MM-DD biçimindedir.

## 2.2.4+32 - 2026-08-26

### Güneş vakti kaldırıldı, yedek bildirim görevi düzeltildi

- **Güneş kaldırıldı:** Güneş namaz vakti olmadığından (astronomik bilgi) vakit listesinden, sıradaki vakit geri sayımından ve tüm bildirimlerden çıkarıldı. Artık yalnızca beş vakit: İmsak, Öğle, İkindi, Akşam, Yatsı.
- **Yedek bildirim görevi çalışmıyordu (kritik):** Görev, v4 temizliğinde silinen eski `prayer_times_v2ezan_vakit` kanalına gönderim yapıyordu; Android 8+ var olmayan kanala giden bildirimi sessizce düşürür. Artık ana zamanlayıcıyla aynı `v4` kanalını kullanır ve kanal yoksa göndermeden önce oluşturur.
- **Yedek görev Güneş'i de duyuruyordu:** Gece alınan "Güneş vakti girdi" bildirimi alarm katmanından değil, bu yedek görevden geliyordu — döngü tüm vakit türlerini kapsıyordu. Güneş artık atlanır.
- Yedek görev kullanıcı tercihlerine saygı duyar: bildirimler kapalıysa veya "vakit girişinde bildir" kapalıysa sessiz kalır.
- Gece yarısı bildirimleri cihaz üreticisi kısıtından etkilenebilir; pil optimizasyonunda uygulamaya "kısıtlama yok" verilmesi önerilir. Alarm düşerse 15 dakikalık yedek görev telafi eder.

## 2.2.3+31 - 2026-08-26

### Test bildirimi ve ses akışı düzeltmeleri

- **5 saniyelik test bildirimi artık silinmiyor:** Dakikalık otomatik yenileme her çalıştığında `cancelAll` ile TÜM planlı bildirimler iptal ediliyor, yeni planlanan test bildirimini de öldürüyordu. Artık yalnızca planner'ın yönettiği id'ler (vakitler, +50 vakit girişleri, günlük hatırlatma) iptal edilir; test bildirimi (id=999) korunur.
- **Zil sesleri sessiz kalan cihazlarda düzeltildi:** Tüm sesler alarm sesi akışına bağlıydı; alarm sesi kısık/sessiz olan telefonlarda (ör. Android 11) bildirim sadece titreşimle geliyordu. Zil sesleri artık bildirim sesi akışından çalar; ezan sesleri sessiz modda bile duyulsun diye alarm akışında kalır.
- Kanal şeması `v4`'e taşındı; eski v2/v3 kanalları açılışta temizlenir.
- 5 sn test planlaması teşhis olay kaydına yazılır (hedef saat + ses).

## 2.2.2+30 - 2026-08-26

### Bildirim sesleri ve test bildirimi düzeltmeleri

- **Ezan okunmama sorunu giderildi:** Android 8+ kanal ayarları ilk yaratılışta sabitlendiğinden, eski sürümlerde sessiz/yanlış yaratılan bildirim kanalları güncellemeyle düzelmiyordu. Kanal şeması `v3`'e taşındı; eski `prayer_times`/`prayer_times_v2*` kanalları açılışta silinir.
- **Vakit yaklaşınca ses seçenekleri genişletildi:** "Vakit girince" bölümündeki tüm zil ve ezan sesleri artık "Vakit yaklaşırken" bölümünde de seçilebilir (2 zil + 5 ezan + sistem sesi).
- **5 saniyelik test bildirimi sağlamlaştırıldı:** Buton önce Android 13+ bildirim iznini kontrol edip ister; planlama sonrası bildirimin sistemde kaydedildiği doğrulanır, olmazsa hata ekranda gösterilir.
- Teşhis metnine alarm ses seviyesi notu eklendi: sesler ALARM seviyesinden çalar, alarm sesi kısık/sessizse ezan duyulmaz.

## 1.5.0+7 - 2026-08-24

### Premium tasarım sistemi

- Zümrüt yeşili + altın paletle premium tasarım sistemi: `AppTheme` üzerinden birleşik renk kartları, tipografi ve bileşen stilleri.
- Ana ekran, vakitler, kıble, dualar, şehir seçimi ve bildirim ayarları ekranları yeni tasarım diline uyarlandı.

## 1.4.0 - 2026-08-24

### Vakit girdi bildirimi, gerçek şehir adı, app open reklam

- **Vakit girdi bildirimi:** Hatırlatmanın yanına ek olarak, seçilen vaktin girdiği anda ikinci bir bildirim gönderilir ("... vakti girdi.").
- **Gerçek şehir adı (reverse geocoding):** GPS ile konum belirlendiğinde koordinatlar ters geocoding ile şehir adına çözülür; ana ekran ve kıble ekranında gerçek şehir adı gösterilir.
- **App open reklam:** `AppOpenAdManager` ile uygulama açılışına/önplana dönüşte tek kaynaktan (`assets/config/app.production.json`) yönetilen açılış reklamı eklendi.

## 1.3.1 - 2026-08-23

- Portre kilidi: uygulama dikey yönde kilitlendi (`screenOrientation="portrait"`).
- Tematik uygulama ikonu: tüm `mipmap-*` yoğunluklarına programatik üretilmiş PNG'ler + `mipmap-anydpi-v26` uyarlamalı ikon.
- Mağaza listing paketi: `store/` altında listing metinleri, gizlilik politikası taslağı, grafik gereksinim listesi.

## 1.3.0 - 2026-08-23

- **Yarının vakitleri:** Gece yarısını geçince ertesi günün vakitlerini görüntüleme.
- R8 küçültme: release derlemede `minifyEnabled` + `shrinkResources` etkinleştirildi.
- Dinamik sürüm bilgisi: Hakkında bölümünde sürüm adı/build numarası `package_info_plus` ile okunur.

## 1.2.0 - 2026-08-23

- Dark theme: sistem temasını izleyen koyu tema desteği (`ThemeMode.system`).
- Kalıcı izin akışı: kalıcı olarak reddedilen konum/bildirim izinlerinde ayarlara yönlendirme.
- Kıble GPS yedeği: sensör yokluğunda konum tabanlı kıble hesabı.
- Dualar: 12 dua + metin kopyalama; Hakkında bölümü.
- Widget testleri genişletildi.

## 1.1.0+2 - 2026-08-23

- Son-bilinen-iyi-değer cache: ağ hatasında önbellekten vakit gösterimi.
- Parser sağlamlaştırma: ISO/HH:mm zaman formatları, eksik alan toleransı.
- Feature-first klasör yapısına refactor.
- GitHub Actions CI (analyze + test, core deposu için `CORE_REPO_TOKEN` fallback).

## 1.0.0+1 - 2026-08-23

### İlk yayın — Android MVP

- Günlük namaz vakitleri (İmsak–Yatsı), sıradaki vakte geri sayım.
- WMM2025 manyetik sapma modeliyle hassas kıble pusulası (sensör füzyonu).
- Vakit öncesi hatırlatma bildirimleri (10/15/30 dk) + günlük imsak bildirimi.
- Release altyapısı: imza yapılandırması, AdMob tek-kaynak yapılandırması, uygulama ikonları.
