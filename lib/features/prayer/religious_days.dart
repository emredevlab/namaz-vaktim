import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Hicri dini günler verisi ve eşleştirme motoru.
/// Kaynak: Diyanet İşleri Başkanlığı dini günler listesi.
final class ReligiousDayInfo {
  const ReligiousDayInfo({
    required this.month,
    required this.day,
    required this.title,
    required this.message,
    required this.dua,
    this.daySpan = 1,
    this.isNightObserved = false,
  });

  final int month;
  final int day;
  final String title;
  final String message;
  final String dua;

  /// Bayramlar birden fazla gün sürer; [daySpan] ile kapsanır.
  final int daySpan;

  /// Kandil geceleri gün batımıyla başlar, sabah namazıyla biter:
  /// banner'ı gündüz göstermemek için işaretlenir.
  final bool isNightObserved;
}

const List<ReligiousDayInfo> kReligiousDays = [
  ReligiousDayInfo(
    month: 1,
    day: 1,
    daySpan: 1,
    title: 'Hicri Yıl Başı',
    message: 'Yeni hicri yıl hayırlara vesile olsun.',
    dua:
        'Yâ Rabbî! Bu yeni hicrî yılı imanımızı tazelememize ve salih amellere vesile eyle. Geçmiş günahlarımızı affet, yeni yılımızı hayırlı kıl. Âmin.',
  ),
  ReligiousDayInfo(
    month: 1,
    day: 10,
    daySpan: 1,
    title: 'Aşure Günü',
    message: 'Aşure Günü\'nde zikir, sadaka ve akraba ziyareti tavsiye edilir.',
    dua:
        'Hasbünallâhü ve ni\'mel-vekîl. Elhamdü lillâhi alâ külli hâlin. Yâ Rabbî! Bugünü huzurunda geçirmemizi kıymetli kıl, dualarımızı kabul eyle. Âmin.',
  ),
  ReligiousDayInfo(
    month: 3,
    day: 12,
    isNightObserved: true,
    title: 'Mevlid Kandili',
    message:
        'Sevgili Peygamberimizin (s.a.v.) dünyaya teşrif ettiği mübarek gece. Salavat-ı şerife getirin, Kur\'an okuyun.',
    dua:
        'Yâ Rabbî! Sevgili Peygamberine ümmet olma şerefine erdirdiğin için sana hamd olsun. Onun şefaatine nail eyle ve güzel ahlakıyla ahlaklanmayı bizlere nasip et. Âmin.',
  ),
  ReligiousDayInfo(
    month: 7,
    day: 27,
    isNightObserved: true,
    title: 'Miraç Kandili',
    message:
        'Miraç Kandili\'nde namaz kılıp zikretmek, tövbe ve istiğfar etmek müstehaptır.',
    dua:
        'Sübhânallâhi ve\'l-hamdü lillâhi ve lâ ilâhe illallâhü vallâhü ekber. Yâ Rabbî! Miraç gecesinin feyzinden bizleri de nasiplendir. Âmin.',
  ),
  ReligiousDayInfo(
    month: 8,
    day: 15,
    isNightObserved: true,
    title: 'Berat Kandili',
    message: 'Berat Kandili\'nde af dilemek ve Kur\'an tilaveti etmek müstehaptır.',
    dua:
        'Allahümme inneke afüvvün kerîmün tühibbü\'l-afve fa\'fu annî. Yâ Rabbî! Bu mübarek gecede günahlarımızı affet, kalplerimizi temizle. Âmin.',
  ),
  ReligiousDayInfo(
    month: 9,
    day: 27,
    isNightObserved: true,
    title: 'Kadir Gecesi',
    message:
        'Bin aydan hayırlı olan bu gecede Peygamberimizin okuttuğu dua şudur:',
    dua:
        'Allahümme inneke afüvvün kerîmün tühibbü\'l-afve fa\'fu annî. Yâ Rabbî! Kadir Gecesi\'nin kıymetini bilebilmeyi, dualarımızın kabulünü nasip et. Âmin.',
  ),
  ReligiousDayInfo(
    month: 10,
    day: 1,
    daySpan: 3,
    title: 'Ramazan Bayramı',
    message: 'Ramazan Bayramınız mübarek olsun!',
    dua:
        'Yâ Rabbî! Ramazan orucumuz ve ibadetlerimizi kabul eyle. Bayramınız hayırlara vesile olsun. Âmin.',
  ),
  ReligiousDayInfo(
    month: 12,
    day: 9,
    daySpan: 1,
    title: 'Arefe Günü',
    message: 'Arefe gününde kelime-i tevhidi bolca zikretmek faziletlidir.',
    dua:
        'Lâ ilâhe illallâhü vahdehû lâ şerîke leh. Lehü\'l-mülkü ve lehü\'l-hamdü ve hüve alâ külli şey\'in kadîr. Yâ Rabbî! dualarımızı kabul eyle. Âmin.',
  ),
  ReligiousDayInfo(
    month: 12,
    day: 10,
    daySpan: 4,
    title: 'Kurban Bayramı',
    message: 'Kurban Bayramınız mübarek olsun!',
    dua:
        'Yâ Rabbî! Kurban ibadetlerimizi kabul eyle; bayramınızı kardeşlik ve bereketle yaşat. Âmin.',
  ),
];

/// Bugüne denk gelen dini günü bulur (bayramlar gün aralığıyla kapsanır).
ReligiousDayInfo? matchSpecialDay(int hijriMonth, int hijriDay) {
  if (hijriMonth <= 0 || hijriDay <= 0) return null;
  for (final info in kReligiousDays) {
    if (info.month != hijriMonth) continue;
    final offset = hijriDay - info.day;
    if (offset >= 0 && offset < info.daySpan) return info;
  }
  return null;
}

/// Cuma günü içeriği.
const String fridayTitle = 'Cuma Mübarek Olsun';
const String fridayMessage =
    'Bugün Cuma. Kehf Suresi okuyun, bolca salavat getirin.';
const String fridayDua =
    'Allahümme salli alâ Muhammedin ve alâ âli Muhammed. Yâ Rabbî! Cuma '
    'gününün bereketini üzerimize indir, dualarımızı kabul eyle. Âmin.';

bool isFriday(DateTime date) => date.weekday == DateTime.friday;

/// Dini gün / Cuma banner'ında kullanılan birleşik içerik.
final class SpecialDayContent {
  const SpecialDayContent({
    required this.title,
    required this.message,
    required this.dua,
    required this.isFriday,
  });

  final String title;
  final String message;
  final String dua;
  final bool isFriday;
}

/// Hicri tarih + miladi günden bugünün özel içeriğini döndürür.
/// Sıra: dini gün -> arifesi (yarın dini gün) -> Cuma. Hiçbiri değilse null.
///
/// [fajrTime]: bugünün imsak vakti. Kandil geceleri sabah namazıyla
/// bittiğinden, gündüz geldiyse kandil banner'ı gösterilmez.
SpecialDayContent? specialContentFor({
  required int hijriMonth,
  required int hijriDay,
  required DateTime gregorianDate,
  DateTime? fajrTime,
}) {
  final special = matchSpecialDay(hijriMonth, hijriDay);
  if (special != null) {
    if (special.isNightObserved &&
        fajrTime != null &&
        gregorianDate.isAfter(fajrTime)) {
      return null; // Kandil gecesi sabah namazıyla sona erdi.
    }
    return SpecialDayContent(
      title: special.title,
      message: special.message,
      dua: special.dua,
      isFriday: false,
    );
  }
  // Arifesi: yarın dini gün mü? (ay sonu 29/30 için ay devri de denenir)
  final tomorrowSpecial = matchSpecialDay(hijriMonth, hijriDay + 1) ??
      matchSpecialDay(hijriMonth + 1, 1);
  if (tomorrowSpecial != null) {
    // Hicri gün gün batımında başlar: ikindiden sonraki saatlerde kandil
    // gecesi zaten yaşanıyor -> 'Bu gece'; daha erken saatlerde 'Yarın'.
    final isEvening = gregorianDate.hour >= 16;
    final prefix = isEvening ? 'Bu gece' : 'Yarın';
    return SpecialDayContent(
      title: '$prefix ${tomorrowSpecial.title}',
      message: '$prefix ${tomorrowSpecial.title}. ${tomorrowSpecial.message}',
      dua: tomorrowSpecial.dua,
      isFriday: false,
    );
  }
  if (isFriday(gregorianDate)) {
    return const SpecialDayContent(
      title: fridayTitle,
      message: fridayMessage,
      dua: fridayDua,
      isFriday: true,
    );
  }
  return null;
}

/// Banner ikonu: dini günler cami, cuma güneş.
IconData specialDayIcon(SpecialDayContent content) =>
    content.isFriday ? Icons.wb_sunny_outlined : Icons.mosque_outlined;

/// Dini takvim: gelecekteki dini günlerin Miladi tarihleri Aladhan
/// hToG servisiyle hesaplanır — her yıl otomatik güncel, manuel
/// bakım gerektirmez.
final class UpcomingReligiousDay {
  const UpcomingReligiousDay({
    required this.info,
    required this.gregorianDate,
    required this.hijriYear,
  });

  final ReligiousDayInfo info;
  final DateTime gregorianDate;
  final int hijriYear;

  String get hijriLabel =>
      '${info.day} ${info.title} $hijriYear';
}

typedef HijriDateFetcher = Future<DateTime> Function(
    int hijriYear, int hijriMonth, int hijriDay);

/// Aladhan hToG servisiyle Hicri tarihi Miladi'ye çevirir.
Future<DateTime> fetchGregorianFromAladhan(
    int hijriYear, int hijriMonth, int hijriDay) async {
  final dateParam =
      '${hijriDay.toString().padLeft(2, '0')}-${hijriMonth.toString().padLeft(2, '0')}-${hijriYear.toString().padLeft(4, '0')}';
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(Uri.parse('https://api.aladhan.com/v1/hToG?date=$dateParam'))
      ..headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    if (response.statusCode != 200) {
      throw StateError('Aladhan hToG HTTP ${response.statusCode}');
    }
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final gregorian = decoded['data']?['gregorian']?['date'];
    if (gregorian is! String) {
      throw StateError('Aladhan hToG yanıtı beklenmedik biçimde.');
    }
    final parts = gregorian.split('-');
    if (parts.length != 3) {
      throw StateError('Aladhan hToG tarih biçimi geçersiz: $gregorian');
    }
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  } finally {
    client.close();
  }
}

/// Bugünden itibaren [daysAhead] gün içindeki dini günleri getirir.
/// Hicri yıl [currentHijriYear] ve bir sonraki yıl sorgulanır; sonuç
/// tarihe göre sıralıdır. Tek bir gün başarısız olursa atlanır.
Future<List<UpcomingReligiousDay>> upcomingReligiousDays({
  required int currentHijriYear,
  required DateTime today,
  HijriDateFetcher fetcher = fetchGregorianFromAladhan,
  int daysAhead = 400,
}) async {
  final limit = today.add(Duration(days: daysAhead));
  final result = <UpcomingReligiousDay>[];
  final seen = <String>{};
  for (final info in kReligiousDays) {
    for (final hijriYear in [currentHijriYear, currentHijriYear + 1]) {
      final key = '${info.month}/${info.day}/$hijriYear';
      if (!seen.add(key)) continue;
      try {
        final date = await fetcher(hijriYear, info.month, info.day);
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (dateOnly.isBefore(DateTime(today.year, today.month, today.day))) {
          continue;
        }
        if (dateOnly.isAfter(limit)) continue;
        result.add(UpcomingReligiousDay(
          info: info,
          gregorianDate: date,
          hijriYear: hijriYear,
        ));
      } catch (_) {
        // Tek günün çevirisi başarısızsa takvimin geri kalanı etkilenmez.
      }
    }
  }
  result.sort((a, b) => a.gregorianDate.compareTo(b.gregorianDate));
  return result;
}
