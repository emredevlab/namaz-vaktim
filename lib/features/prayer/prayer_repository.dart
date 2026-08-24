import 'dart:convert';

import 'package:kapadokya_mobile_core/kapadokya_mobile_core.dart';

import 'prayer_models.dart';
import 'prayer_times_cache.dart';

abstract interface class PrayerTimesRepository {
  Future<DailyPrayerTimes> getDaily(UserLocation location, DateTime date);
}

final class ApiPrayerTimesRepository implements PrayerTimesRepository {
  const ApiPrayerTimesRepository(
      {required this.network, required this.endpoint});

  final NetworkClient network;
  final Uri endpoint;

  /// Aladhan uç noktası (api.aladhan.com) için yol tabanlı istek kurulur;
  /// kendi API'miz eski generic şemayla çalışmayı sürdürür.
  bool get _isAladhanEndpoint => endpoint.host.endsWith('aladhan.com');

  @override
  Future<DailyPrayerTimes> getDaily(
      UserLocation location, DateTime date) async {
    final requestUri = _isAladhanEndpoint
        ? _buildAladhanUri(location, date)
        : _buildLegacyUri(location, date);
    final result = await network.get(requestUri);
    return result.fold(
      success: (body) => _parse(body, location, date),
      failure: (failure) => throw StateError(failure.message),
    );
  }

  Uri _buildAladhanUri(UserLocation location, DateTime date) {
    final latitude = location.latitude;
    final longitude = location.longitude;
    if (latitude == null || longitude == null) {
      // ResilientPrayerTimesRepository bunu yakalayıp demo yedeğine düşer.
      throw StateError('Namaz vakitleri için konum koordinatları gerekli.');
    }
    final base = endpoint.toString().replaceAll(RegExp('/+\$'), '');
    final path =
        '$base/v1/timings/${_aladhanDate(date)}';
    return Uri.parse(path).replace(queryParameters: <String, String>{
      ...endpoint.queryParameters,
      'latitude': '$latitude',
      'longitude': '$longitude',
      'method': '13',
    });
  }

  Uri _buildLegacyUri(UserLocation location, DateTime date) {
    final query = <String, String>{
      'city': location.city,
      'date': _dateOnly(date),
    };
    if (location.latitude != null) query['latitude'] = '${location.latitude}';
    if (location.longitude != null) {
      query['longitude'] = '${location.longitude}';
    }
    return endpoint.replace(queryParameters: <String, String>{
      ...endpoint.queryParameters,
      ...query,
    });
  }

  DailyPrayerTimes _parse(String body, UserLocation location, DateTime date) {
    try {
      final decoded = jsonDecode(body);
      final root = decoded is Map<String, dynamic> && decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : Map<String, dynamic>.from(decoded as Map);
      // ÖNCE Aladhan şeması: data.timings haritası varsa o yolu izle.
      final aladhanTimings = root['timings'];
      if (aladhanTimings is Map) {
        return _parseAladhan(
          timings: Map<String, dynamic>.from(aladhanTimings),
          dataRoot: root,
          location: location,
          date: date,
        );
      }
      // Değilse MEVCUT generic şema (gelecekteki kendi API'miz).
      final rawTimes = root['times'] ?? root['prayerTimes'];
      if (rawTimes is! Map) throw const FormatException('times missing');
      final times = <PrayerTime>[];
      for (final type in PrayerType.values) {
        final value = rawTimes[type.name] ?? rawTimes[_apiKey(type)];
        if (value == null || (value is String && value.trim().isEmpty)) {
          continue;
        }
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

  DailyPrayerTimes _parseAladhan({
    required Map<String, dynamic> timings,
    required Map<String, dynamic> dataRoot,
    required UserLocation location,
    required DateTime date,
  }) {
    final times = <PrayerTime>[];
    for (final type in PrayerType.values) {
      final value = timings[_aladhanKey(type)];
      if (value == null || (value is String && value.trim().isEmpty)) {
        continue;
      }
      times.add(PrayerTime(
        type: type,
        dateTime: _parseTime(_stripTimezoneSuffix(value), date),
      ));
    }
    if (times.isEmpty) throw const FormatException('empty times');
    final aladhanDate = dataRoot['date'];
    return DailyPrayerTimes(
      date: date,
      location: location,
      times: times,
      hijriDate: _parseHijri(
        aladhanDate is Map ? aladhanDate['hijri'] : null,
      ),
    );
  }

  /// '"04:21 (TRT)'"' gibi değerlerdeki parantezli saat dilimi sonekini atar.
  static String _stripTimezoneSuffix(Object value) =>
      '$value'.trim().replaceFirst(
            RegExp(r'\s*\([^)]*\)\s*$'),
            '',
          );

  static const List<String> _hijriMonths = [
    'Muharrem',
    'Safer',
    'Rebiülevvel',
    'Rebiiülahır',
    'Cemaziyelevvel',
    'Cemaziyelahir',
    'Recep',
    'Şaban',
    'Ramazan',
    'Şevval',
    'Zilkade',
    'Zilhicce',
  ];

  String? _parseHijri(Object? hijri) {
    if (hijri is! Map) return null;
    final day = int.tryParse('${hijri['day']}');
    final month = hijri['month'];
    final monthNumber = month is Map ? int.tryParse('${month['number']}') : null;
    final year = int.tryParse('${hijri['year']}');
    if (day == null ||
        year == null ||
        monthNumber == null ||
        monthNumber < 1 ||
        monthNumber > 12) {
      return null;
    }
    return '$day ${_hijriMonths[monthNumber - 1]} $year';
  }

  String _aladhanKey(PrayerType type) => switch (type) {
        PrayerType.imsak => 'Fajr',
        PrayerType.gunes => 'Sunrise',
        PrayerType.ogle => 'Dhuhr',
        PrayerType.ikindi => 'Asr',
        PrayerType.aksam => 'Maghrib',
        PrayerType.yatsi => 'Isha',
      };

  String _aladhanDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.year.toString().padLeft(4, '0')}';

  DateTime _parseTime(Object value, DateTime date) {
    final text = value is String ? value.trim() : '$value';
    if (_isoPattern.hasMatch(text)) {
      return DateTime.parse(text.replaceFirst(' ', 'T')).toLocal();
    }
    final parts = text.split(':');
    if (parts.length < 2) throw FormatException('invalid time "$text"');
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw FormatException('invalid time "$text"');
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static final RegExp _isoPattern =
      RegExp(r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(:\d{2})?');

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
  const ResilientPrayerTimesRepository({
    required this.primary,
    this.fallback = const DemoPrayerTimesRepository(),
    this.cache,
  });

  final PrayerTimesRepository primary;
  final PrayerTimesRepository fallback;
  final KeyValueStorage? cache;

  @override
  Future<DailyPrayerTimes> getDaily(
      UserLocation location, DateTime date) async {
    final KeyValueStorage? storage = cache;
    final store = storage == null ? null : PrayerTimesCache(storage: storage);
    try {
      final result = await primary.getDaily(location, date);
      if (store != null && !result.isFallback) await store.write(result);
      return result;
    } catch (_) {
      final cached = await store?.read(location.city, date);
      if (cached != null) return cached;
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
