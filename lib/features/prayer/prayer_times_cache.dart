import 'dart:convert';

import 'package:kapadokya_mobile_core/kapadokya_mobile_core.dart';

import 'prayer_models.dart';

class PrayerTimesCache {
  const PrayerTimesCache({KeyValueStorage? storage}) : _storage = storage;

  final KeyValueStorage? _storage;

  static String keyFor(String city, DateTime date) =>
      'prayer_cache_${_citySlug(city)}_${_dateKey(date)}';

  Future<DailyPrayerTimes?> read(String city, DateTime date) async {
    final storage = _storage;
    if (storage == null) return null;
    try {
      final raw = await storage.read(keyFor(city, date));
      if (raw == null || raw.isEmpty) return null;
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(DailyPrayerTimes data) async {
    final storage = _storage;
    if (storage == null) return;
    try {
      await storage.write(
        keyFor(data.location.city, data.date),
        jsonEncode(toJson(data)),
      );
    } catch (_) {}
  }

  static String _citySlug(String city) =>
      city.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Map<String, Object?> toJson(DailyPrayerTimes data) =>
      <String, Object?>{
        'date': _dateKey(data.date),
        'location': <String, Object?>{
          'city': data.location.city,
          'latitude': data.location.latitude,
          'longitude': data.location.longitude,
        },
        'isFallback': data.isFallback,
        'times': <Object?>[
          for (final time in data.times)
            <String, Object?>{
              'type': time.type.name,
              'dateTime': time.dateTime.toIso8601String(),
            },
        ],
      };

  static DailyPrayerTimes fromJson(Map<String, dynamic> json) {
    final locationJson = json['location'];
    if (locationJson is! Map) throw const FormatException('location missing');
    final rawDate = json['date'];
    if (rawDate is! String) throw const FormatException('date missing');
    final timesJson = json['times'];
    if (timesJson is! List) throw const FormatException('times missing');
    final times = <PrayerTime>[
      for (final entry in timesJson)
        if (entry is Map)
          PrayerTime(
            type: PrayerType.values.byName(entry['type'] as String),
            dateTime: DateTime.parse(entry['dateTime'] as String),
          ),
    ];
    return DailyPrayerTimes(
      date: DateTime.parse(rawDate),
      location: UserLocation(
        city: '${locationJson['city']}',
        latitude: (locationJson['latitude'] as num?)?.toDouble(),
        longitude: (locationJson['longitude'] as num?)?.toDouble(),
      ),
      isFallback: json['isFallback'] as bool? ?? false,
      times: times,
    );
  }
}
