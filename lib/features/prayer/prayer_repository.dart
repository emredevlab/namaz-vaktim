import 'dart:convert';

import 'package:kapadokya_mobile_core/kapadokya_mobile_core.dart';

import 'prayer_models.dart';

abstract interface class PrayerTimesRepository {
  Future<DailyPrayerTimes> getDaily(UserLocation location, DateTime date);
}

final class ApiPrayerTimesRepository implements PrayerTimesRepository {
  const ApiPrayerTimesRepository(
      {required this.network, required this.endpoint});

  final NetworkClient network;
  final Uri endpoint;

  @override
  Future<DailyPrayerTimes> getDaily(
      UserLocation location, DateTime date) async {
    final query = <String, String>{
      'city': location.city,
      'date': _dateOnly(date),
    };
    if (location.latitude != null) query['latitude'] = '${location.latitude}';
    if (location.longitude != null) {
      query['longitude'] = '${location.longitude}';
    }
    final result = await network.get(endpoint.replace(queryParameters: query));
    return result.fold(
      success: (body) => _parse(body, location, date),
      failure: (failure) => throw StateError(failure.message),
    );
  }

  DailyPrayerTimes _parse(String body, UserLocation location, DateTime date) {
    try {
      final decoded = jsonDecode(body);
      final root = decoded is Map<String, dynamic> && decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : Map<String, dynamic>.from(decoded as Map);
      final rawTimes = root['times'] ?? root['prayerTimes'];
      if (rawTimes is! Map) throw const FormatException('times missing');
      final times = <PrayerTime>[];
      for (final type in PrayerType.values) {
        final value = rawTimes[type.name] ?? rawTimes[_apiKey(type)];
        if (value == null) continue;
        times.add(PrayerTime(type: type, dateTime: _parseTime(value, date)));
      }
      if (times.isEmpty) throw const FormatException('empty times');
      return DailyPrayerTimes(date: date, location: location, times: times);
    } on FormatException catch (error) {
      throw StateError('Namaz vakitleri yanıtı geçersiz: $error');
    } on TypeError catch (error) {
      throw StateError('Namaz vakitleri yanıtı geçersiz: $error');
    }
  }

  DateTime _parseTime(Object value, DateTime date) {
    if (value is String && value.contains('T')) {
      return DateTime.parse(value).toLocal();
    }
    final text = '$value';
    final parts = text.split(':');
    if (parts.length < 2) throw const FormatException('invalid time');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _apiKey(PrayerType type) => switch (type) {
        PrayerType.imsak => 'fajr',
        PrayerType.gunes => 'sunrise',
        PrayerType.ogle => 'dhuhr',
        PrayerType.ikindi => 'asr',
        PrayerType.aksam => 'maghrib',
        PrayerType.yatsi => 'isha',
      };

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

final class ResilientPrayerTimesRepository implements PrayerTimesRepository {
  const ResilientPrayerTimesRepository(
      {required this.primary,
      this.fallback = const DemoPrayerTimesRepository()});

  final PrayerTimesRepository primary;
  final PrayerTimesRepository fallback;

  @override
  Future<DailyPrayerTimes> getDaily(
      UserLocation location, DateTime date) async {
    try {
      return await primary.getDaily(location, date);
    } catch (_) {
      return fallback.getDaily(location, date);
    }
  }
}

final class DemoPrayerTimesRepository implements PrayerTimesRepository {
  const DemoPrayerTimesRepository();

  @override
  Future<DailyPrayerTimes> getDaily(
      UserLocation location, DateTime date) async {
    DateTime at(int hour, int minute) =>
        DateTime(date.year, date.month, date.day, hour, minute);
    return DailyPrayerTimes(
      date: date,
      location: location,
      isFallback: true,
      times: [
        PrayerTime(type: PrayerType.imsak, dateTime: at(4, 21)),
        PrayerTime(type: PrayerType.gunes, dateTime: at(5, 54)),
        PrayerTime(type: PrayerType.ogle, dateTime: at(12, 48)),
        PrayerTime(type: PrayerType.ikindi, dateTime: at(16, 27)),
        PrayerTime(type: PrayerType.aksam, dateTime: at(19, 31)),
        PrayerTime(type: PrayerType.yatsi, dateTime: at(20, 58)),
      ],
    );
  }
}
