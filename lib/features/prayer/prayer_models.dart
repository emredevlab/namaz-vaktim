enum PrayerType { imsak, gunes, ogle, ikindi, aksam, yatsi }

class PrayerTime {
  const PrayerTime({required this.type, required this.dateTime});
  final PrayerType type;
  final DateTime dateTime;
}

class DailyPrayerTimes {
  const DailyPrayerTimes({
    required this.date,
    required this.location,
    required this.times,
    this.isFallback = false,
    this.hijriDate,
    this.hijriDay = 0,
    this.hijriMonth = 0,
  });
  final DateTime date;
  final UserLocation location;
  final List<PrayerTime> times;
  final bool isFallback;

  /// Hicri tarih ('1 Rebiülevvel 1448'); yalnızca Aladhan şemasında dolur.
  final String? hijriDate;

  /// Hicri gün/ay numaraları; dini gün eşleştirmesi için (yoksa 0).
  final int hijriDay;
  final int hijriMonth;

  /// Güneş çıkarılmış BEŞ vakit: Güneş namaz vakti değildir (astronomik
  /// bilgi); kullanıcı talebiyle listeden, geri sayımdan ve bildirimlerden
  /// çıkarıldı. Ham [times] API uyumu için güneşi içerir.
  List<PrayerTime> get prayerTimes =>
      times.where((time) => time.type != PrayerType.gunes).toList(
            growable: false,
          );

  /// Sıradaki NAMAZ vakti; güneşe denk gelirse bir sonrakine geçer.
  PrayerTime? get next {
    final now = DateTime.now();
    for (final time in prayerTimes) {
      if (time.dateTime.isAfter(now)) return time;
    }
    return null;
  }
}

/// Hicri tarih bilgisi: ayrı gün/ay alanları dini gün eşleştirmesi içindir.
class HijriDateInfo {
  const HijriDateInfo({
    required this.day,
    required this.month,
    required this.year,
    required this.formatted,
  });
  final int day;
  final int month;
  final int year;
  final String formatted;
}

class UserLocation {
  const UserLocation({required this.city, this.latitude, this.longitude});
  final String city;
  final double? latitude;
  final double? longitude;
}

class PrayerHomeState {
  const PrayerHomeState({
    this.data,
    this.tomorrow,
    this.isLoading = false,
    this.error,
  });
  final DailyPrayerTimes? data;
  final DailyPrayerTimes? tomorrow;
  final bool isLoading;
  final String? error;

  PrayerHomeState copyWith(
          {DailyPrayerTimes? data,
          DailyPrayerTimes? tomorrow,
          bool? isLoading,
          String? error}) =>
      PrayerHomeState(
        data: data ?? this.data,
        tomorrow: tomorrow ?? this.tomorrow,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
