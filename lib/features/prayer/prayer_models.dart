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
  });
  final DateTime date;
  final UserLocation location;
  final List<PrayerTime> times;
  final bool isFallback;

  /// Hicri tarih ('1 Rebiülevvel 1448'); yalnızca Aladhan şemasında dolur.
  final String? hijriDate;

  PrayerTime? get next {
    final now = DateTime.now();
    for (final time in times) {
      if (time.dateTime.isAfter(now)) return time;
    }
    return null;
  }
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
