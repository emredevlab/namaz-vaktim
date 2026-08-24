import 'package:flutter_test/flutter_test.dart';
import 'package:kapadokya_mobile_core/kapadokya_mobile_core.dart';
import 'package:namaz_vaktim/features/prayer/prayer_models.dart';
import 'package:namaz_vaktim/features/prayer/prayer_repository.dart';

class FakeNetworkClient implements NetworkClient {
  FakeNetworkClient({this.response, this.error});

  Result<String>? response;
  Object? error;
  final List<Uri> requests = <Uri>[];

  @override
  Future<Result<String>> get(
    Uri uri, {
    Duration timeout = const Duration(seconds: 15),
    Map<String, String> headers = const {},
    CancellationToken? cancellationToken,
  }) async {
    requests.add(uri);
    final thrown = error;
    if (thrown != null) throw thrown;
    return response!;
  }

  @override
  Future<Result<String>> post(
    Uri uri, {
    Object? body,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String> headers = const {},
    CancellationToken? cancellationToken,
  }) async {
    throw UnimplementedError();
  }
}

const _location = UserLocation(city: 'Nevşehir', latitude: 38.62, longitude: 34.71);
final _date = DateTime(2026, 8, 23);

const _englishTimes = '"fajr":"04:21","sunrise":"05:54","dhuhr":"12:48",'
    '"asr":"16:27","maghrib":"19:31","isha":"20:58"';
const _turkishTimes = '"imsak":"04:10","gunes":"05:45","ogle":"12:40",'
    '"ikindi":"16:10","aksam":"19:15","yatsi":"20:40"';

const _singleTime = '"fajr":"06:07"';

final _defaultEndpoint =
    Uri.parse('https://api.example.com/v1/prayer-times');

final _aladhanEndpoint = Uri.parse('https://api.aladhan.com');

/// Gerçek Aladhan yanıtı (24-08-2026, Nevşehir, method=13);
/// saat değerlerinde ' (TRT)' soneki var.
const _aladhanBody = '{"code":200,"status":"OK","data":{'
    '"timings":{'
    '"Fajr":"04:21 (TRT)","Sunrise":"06:01 (TRT)","Dhuhr":"13:07 (TRT)",'
    '"Asr":"16:47 (TRT)","Maghrib":"19:32 (TRT)","Isha":"21:07 (TRT)",'
    '"Imsak":"04:15 (TRT)","Sunset":"19:48 (TRT)","Midnight":"00:54 (TRT)"},'
    '"date":{"readable":"24 Aug 2026","gregorian":{"date":"24-08-2026"},'
    '"hijri":{"date":"01-03-1448","day":"01",'
    '"month":{"number":3,"en":"Rabi al-awwal","ar":"ربيع الأول"},'
    '"year":"1448"}}}}';

ApiPrayerTimesRepository _repo(FakeNetworkClient client, {Uri? endpoint}) =>
    ApiPrayerTimesRepository(
      network: client,
      endpoint: endpoint ?? _defaultEndpoint,
    );

void main() {
  group('ApiPrayerTimesRepository parsing', () {
    test('{data:{times:{...}}} sarmalayıcısı İngilizce anahtarlarla ayrışır',
        () async {
      final client = FakeNetworkClient(
        response: const Success('{"data":{"times":{$_englishTimes}}}'),
      );
      final result = await _repo(client).getDaily(_location, _date);
      expect(result.times, hasLength(6));
      expect(result.times.map((t) => t.type).toList(),
          PrayerType.values.toList());
      expect(result.times.first.dateTime, DateTime(2026, 8, 23, 4, 21));
      expect(result.times.last.dateTime, DateTime(2026, 8, 23, 20, 58));
      expect(result.isFallback, isFalse);
    });

    test('düz {times:{...}} biçimi ayrışır', () async {
      final client = FakeNetworkClient(
        response: const Success('{"times":{$_turkishTimes}}'),
      );
      final result = await _repo(client).getDaily(_location, _date);
      expect(result.times, hasLength(6));
      expect(result.times.first.type, PrayerType.imsak);
      expect(result.times.last.type, PrayerType.yatsi);
    });

    test('{prayerTimes:{...}} alternatif biçim ayrışır', () async {
      final client = FakeNetworkClient(
        response: const Success('{"prayerTimes":{$_englishTimes}}'),
      );
      final result = await _repo(client).getDaily(_location, _date);
      expect(result.times, hasLength(6));
    });

    test('Türkçe anahtarlar doğru enum değerlerine eşlenir', () async {
      final client = FakeNetworkClient(
        response: const Success('{"data":{"times":{$_turkishTimes}}}'),
      );
      final result = await _repo(client).getDaily(_location, _date);
      expect(
        result.times.map((t) => t.type).toList(),
        [
          PrayerType.imsak,
          PrayerType.gunes,
          PrayerType.ogle,
          PrayerType.ikindi,
          PrayerType.aksam,
          PrayerType.yatsi,
        ],
      );
      expect(result.times[2].dateTime.hour, 12);
      expect(result.times[3].dateTime.minute, 10);
    });

    test('"HH:mm" saati istenen güne sabitlenir', () async {
      final client = FakeNetworkClient(
        response: const Success('{"times":{$_singleTime}}'),
      );
      final result =
          await _repo(client).getDaily(_location, DateTime(2026, 1, 2));
      expect(result.times.single.dateTime, DateTime(2026, 1, 2, 6, 7));
    });

    test('ISO "yyyy-MM-ddTHH:mm:ss" saati ayrışır', () async {
      final client = FakeNetworkClient(
        response: const Success(
            '{"times":{"imsak":"2026-08-23T04:21:00","aksam":"2026-08-23T19:31:00"}}'),
      );
      final result = await _repo(client).getDaily(_location, _date);
      expect(result.times, hasLength(2));
      expect(result.times[0].dateTime, DateTime(2026, 8, 23, 4, 21));
      expect(result.times[1].dateTime, DateTime(2026, 8, 23, 19, 31));
    });
  });

  group('ApiPrayerTimesRepository request building', () {
    test('latitude/longitude query parametreleri URL\'e eklenir', () async {
      final client = FakeNetworkClient(
        response: const Success('{"times":{$_englishTimes}}'),
      );
      await _repo(client).getDaily(_location, _date);
      expect(client.requests, hasLength(1));
      expect(client.requests.single.queryParameters, {
        'city': 'Nevşehir',
        'date': '2026-08-23',
        'latitude': '38.62',
        'longitude': '34.71',
      });
    });

    test('koordinat yoksa latitude/longitude gönderilmez', () async {
      final client = FakeNetworkClient(
        response: const Success('{"times":{$_englishTimes}}'),
      );
      await _repo(client)
          .getDaily(const UserLocation(city: 'Nevşehir'), _date);
      final params = client.requests.single.queryParameters;
      expect(params.containsKey('latitude'), isFalse);
      expect(params.containsKey('longitude'), isFalse);
      expect(params['city'], 'Nevşehir');
    });

    test('endpoint\'teki mevcut query parametreleri korunur', () async {
      final client = FakeNetworkClient(
        response: const Success('{"times":{$_englishTimes}}'),
      );
      await _repo(
        client,
        endpoint:
            Uri.parse('https://api.example.com/v1/prayer-times?key=abc123'),
      ).getDaily(_location, _date);
      final params = client.requests.single.queryParameters;
      expect(params['key'], 'abc123');
      expect(params['city'], 'Nevşehir');
      expect(client.requests.single.path, '/v1/prayer-times');
    });
  });

  group('ApiPrayerTimesRepository error handling', () {
    test('boş times StateError fırlatır', () async {
      final client = FakeNetworkClient(
        response: const Success('{"data":{"times":{}}}'),
      );
      await expectLater(
        _repo(client).getDaily(_location, _date),
        throwsA(isA<StateError>()),
      );
    });

    test('times alanı hiç yoksa StateError fırlatır', () async {
      final client = FakeNetworkClient(response: const Success('{"data":{}}'));
      await expectLater(
        _repo(client).getDaily(_location, _date),
        throwsA(isA<StateError>()),
      );
    });

    test('geçersiz saat değeri (aralık dışı) StateError fırlatır', () async {
      final client = FakeNetworkClient(
        response: const Success('{"times":{"fajr":"25:70"}}'),
      );
      await expectLater(
        _repo(client).getDaily(_location, _date),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('geçersiz'),
        )),
      );
    });

    test('geçersiz saat değeri (sayısal olmayan) StateError fırlatır',
        () async {
      final client = FakeNetworkClient(
        response: const Success('{"times":{"fajr":"sabah"}}'),
      );
      await expectLater(
        _repo(client).getDaily(_location, _date),
        throwsA(isA<StateError>()),
      );
    });

    test('boş string vakit alanı atlanır, diğerleri ayrışır', () async {
      final client = FakeNetworkClient(
        response: const Success(
            '{"times":{"fajr":"","sunrise":"05:54","isha":"20:58"}}'),
      );
      final result = await _repo(client).getDaily(_location, _date);
      expect(result.times.map((t) => t.type.name), ['gunes', 'yatsi']);
    });

    test('Failure sonucu failure.message ile StateError olur', () async {
      final client = FakeNetworkClient(
        response:
            const Failure(AppFailure('http_500', 'Sunucu isteği tamamlayamadı.')),
      );
      await expectLater(
        _repo(client).getDaily(_location, _date),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', 'Sunucu isteği tamamlayamadı.')),
      );
    });

    test('geçersiz JSON gövdesi StateError olur', () async {
      final client = FakeNetworkClient(response: const Success('<html/>'));
      await expectLater(
        _repo(client).getDaily(_location, _date),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ApiPrayerTimesRepository Aladhan şeması', () {
    test('gerçek örnek yanıt 6 vakiti (TRT sonekli) ayrıştırır ve Hicri tarihi çıkarır',
        () async {
      final client = FakeNetworkClient(response: const Success(_aladhanBody));
      final result =
          await _repo(client, endpoint: _aladhanEndpoint).getDaily(
        _location,
        DateTime(2026, 8, 24),
      );
      expect(result.times, hasLength(6));
      expect(result.times.map((t) => t.type).toList(),
          PrayerType.values.toList());
      expect(result.times[0].dateTime, DateTime(2026, 8, 24, 4, 21),
          reason: 'Fajr -> imsak');
      expect(result.times[1].dateTime, DateTime(2026, 8, 24, 6, 1),
          reason: 'Sunrise -> gunes');
      expect(result.times[2].dateTime, DateTime(2026, 8, 24, 13, 7),
          reason: 'Dhuhr -> ogle');
      expect(result.times[3].dateTime, DateTime(2026, 8, 24, 16, 47),
          reason: 'Asr -> ikindi');
      expect(result.times[4].dateTime, DateTime(2026, 8, 24, 19, 32),
          reason: 'Maghrib -> aksam');
      expect(result.times[5].dateTime, DateTime(2026, 8, 24, 21, 7),
          reason: 'Isha -> yatsi');
      expect(result.isFallback, isFalse);
      expect(result.hijriDate, '1 Rebiülevvel 1448',
          reason: '"01" günü 1 olur, ay Türkçe adıyla yazılır');
    });

    test("' (EET)' gibi alternatif parantezli sonekler de temizlenir",
        () async {
      final client = FakeNetworkClient(
        response: const Success(
          '{"data":{"timings":{"Fajr":"05:12 (EET)","Maghrib":"18:44 ( EET )"},'
          '"date":{"hijri":{"day":"15","month":{"number":9},"year":"1447"}}}}',
        ),
      );
      final result =
          await _repo(client, endpoint: _aladhanEndpoint).getDaily(
        _location,
        _date,
      );
      expect(result.times.first.dateTime, DateTime(2026, 8, 23, 5, 12));
      expect(result.times.last.dateTime, DateTime(2026, 8, 23, 18, 44));
      expect(result.hijriDate, '15 Ramazan 1447',
          reason: 'Hicri ay 9 -> Ramazan');
    });

    test('koordinatsız konumda Aladhan yolu StateError fırlatır', () async {
      final client = FakeNetworkClient(response: const Success(_aladhanBody));
      await expectLater(
        _repo(client, endpoint: _aladhanEndpoint)
            .getDaily(const UserLocation(city: 'Nevşehir'), _date),
        throwsA(isA<StateError>()),
      );
      expect(client.requests, isEmpty);
    });

    test('URL {endpoint}/v1/timings/dd-MM-yyyy + method=13 + koordinatlar',
        () async {
      final client = FakeNetworkClient(response: const Success(_aladhanBody));
      await _repo(client, endpoint: _aladhanEndpoint).getDaily(
        _location,
        _date,
      );
      expect(client.requests, hasLength(1));
      final uri = client.requests.single;
      expect(uri.scheme, 'https');
      expect(uri.host, 'api.aladhan.com');
      expect(uri.path, '/v1/timings/23-08-2026',
          reason: 'Aladhan dd-MM-yyyy bekler; çift slash olmamalı');
      expect(uri.queryParameters, {
        'latitude': '38.62',
        'longitude': '34.71',
        'method': '13',
      });
    });

    test('sonunda slash olan endpoint birleştirmede çift slash üretmez',
        () async {
      final client = FakeNetworkClient(response: const Success(_aladhanBody));
      await _repo(
        client,
        endpoint: Uri.parse('https://api.aladhan.com/'),
      ).getDaily(_location, _date);
      expect(client.requests.single.path, '/v1/timings/23-08-2026');
      expect(client.requests.single.toString(), startsWith('https://api.aladhan.com/v1'));
    });

    test('generic şemada hijriDate null kalır', () async {
      final client = FakeNetworkClient(
        response: const Success('{"times":{$_englishTimes}}'),
      );
      final result = await _repo(client).getDaily(_location, _date);
      expect(result.times, hasLength(6));
      expect(result.hijriDate, isNull);
    });

    test('Aladhan gövdesi generic uç noktasından gelirse de ayrışır',
        () async {
      // Gelecekte kendi API'miz Aladhan benzeri yanıt dönerse
      // kod değişikliği gerekmez; ayrıştırma şema tabanlıdır.
      final client = FakeNetworkClient(response: const Success(_aladhanBody));
      final result = await _repo(client).getDaily(
        _location,
        DateTime(2026, 8, 24),
      );
      expect(result.times, hasLength(6));
      expect(result.hijriDate, '1 Rebiülevvel 1448');
    });

    test('Aladhan şemasında geçersiz saat StateError olur', () async {
      final client = FakeNetworkClient(
        response: const Success(
            '{"data":{"timings":{"Fajr":"25:70"},"date":{}}}'),
      );
      await expectLater(
        _repo(client, endpoint: _aladhanEndpoint).getDaily(_location, _date),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('geçersiz'),
        )),
      );
    });
  });
}
