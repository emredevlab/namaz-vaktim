# Dini İçerik Kaynakları

Uygulamadaki dini içeriklerin (dua, sure, Kuran-ı Kerim) kaynak stratejisi.

## Mevcut strateji (kısa vade): statik gömülü içerik

- Dualar ve kısa sureler uygulamaya **gömülü** (`duas_screen.dart`, `religious_days.dart`).
- Avantaj: çevrimdışı çalışır, anlık erişilir, üçüncü parti bağımlılığı yoktur.
- İçerik kalitesi: Diyanet İşleri Başkanlığı yayınlarındaki standart metinler
  (dualar ve sureler) esas alınmıştır. **Yayın öncesi din danışmanı onayı önerilir.**
- Dini günler: Hicri takvim sabit günleridir; Aladhan'ın döndürdüğü Hicri tarih
  (`hijriMonth`/`hijriDay`) ile `religious_days.dart` üzerinden eşleştirilir.

## Doğrulanmış API'ler (uzun vade için)

### 1. alquran.cloud — Kuran-ı Kerim + Türkçe mealler ✅ (canlı doğrulandı)
- Sure metni + meal: `https://api.alquran.cloud/v1/surah/{no}/tr.diyanet`
- **tr.diyanet** edition'ı mevcut (Diyanet İşleri Türkçe meal).
- Anahtar gerekmez, ücretsiz; rate limit IP başına makul.
- Örnek doğrulama: `/surah/18/tr.diyanet` → Kehf, 110 ayet, Diyanet meali döndü.
- Kullanım alanı: ileride "Sure Okuma" ekranı eklenirse sure metni + meal buradan.

### 2. Aladhan — Hicri takvim ✅ (canlı doğrulandı)
- Miladi→Hicri: `https://api.aladhan.com/v1/gToH?date=DD-MM-YYYY`
- Hicri→Miladi: `/v1/hToG?date=DD-MM-YYYY`
- Uygulamada vakitlerle birlikte Hicri tarih zaten geliyor (`/v1/timings` yanıtı).

### 3. Diyanet İşleri Başkanlığı
- Resmi açık API yok. Namaz vakitleri için resmi tablolar hesaplama yöntemi
  (method=13) üzerinden Aladhan ile uyumludur.
- Kandil/bayram gün listeleri resmi yayın olarak mevcut; uygulamada statik
  tutlmuştur (`religious_days.dart`).

## Önerilen yol haritası
1. **Şimdi:** statik içerik (mevcut) — güvenilir, offline.
2. **Sure Okuma ekranı** istenirse: alquran.cloud `tr.diyanet` ile sure + meal.
   Offline deneyim için ilk çekimde yerel önbelleğe yaz.
3. **Tam Kuran** istenirse: statik asset olarak gömme (metin ~2-3 MB) veya
   alquran.cloud + agresif cache. Sesli okuma için her bir sure ses dosyası
   ayrıca değerlendirilmeli (boyut büyür).

## Yayın öncesi kontrol listesi
- [ ] Dua/sure metinlerinin din danışmanı onayı
- [ ] Gizlilik politikasında içerik kaynaklarının belirtilmesi (store/privacy-policy.md)
- [ ] Mealli ayetlerin "meal olduğu" ibaresiyle gösterilmesi (Kuran-ı Kerim
      orijinal metni ile karıştırılmamalı)
