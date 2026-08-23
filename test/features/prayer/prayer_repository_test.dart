import 'package:flutter_test/flutter_test.dart';
import 'package:kapadokya_mobile_core/kapadokya_mobile_core.dart';
import 'package:namaz_vaktim/features/prayer/prayer_models.dart';
import 'package:namaz_vaktim/features/prayer/prayer_repository.dart';
import 'package:namaz_vaktim/features/prayer/prayer_times_cache.dart';

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

class StubRepository implements PrayerTimesRepository {
  StubRepository({this.result, this.error});

  DailyPrayerTimes? result;
  Object? error;

  @override
  Future<DailyPrayerTimes> getDaily(UserLocation location, DateTime date) async {
    final thrown = error;
    if (thrown != null) throw thrown;
    return result!;
  }
}

const _location =
    UserLocation(city: 'Nevşehir', latitude: 38.62, longitude: 34.71);
final _date = DateTime(2026, 8, 23);

const _apiBody = '{"data":{"times":{"fajr":"04:21","sunrise":"05:54",'
    '"dhuhr":"12:48","asr":"16:27","maghrib":"19:31","isha":"20:58"}}}';

final _apiEndpoint = Uri.parse('https://api.example.com/v1/prayer-times');

void main() {
  test('demo repository returns six prayer times', () async {
    final result = await const DemoPrayerTimesRepository().getDaily(
      _location,
      _date,
    );
    expect(result.times, hasLength(6));
    expect(result.location.city, 'Nevşehir');
  });

  group('ResilientPrayerTimesRepository cache', () {
    test(
        'birincil başarı önbelleğe yazılır; sonraki başarısızlıkta önbellekten döner',
        () async {
      final storage = MemoryStorage();
      final client = FakeNetworkClient(response: const Success(_apiBody));
      final repo = ResilientPrayerTimesRepository(
        primary: ApiPrayerTimesRepository(
            network: client, endpoint: _apiEndpoint),
        cache: storage,
      );

      final first = await repo.getDaily(_location, _date);
      expect(first.isFallback, isFalse);
      expect(first.times, hasLength(6));
      expect(client.requests, hasLength(1));

      client.response =
          const Failure(AppFailure('http_503', 'Sunucu isteği tamamlayamadı.'));
      final second = await repo.getDaily(_location, _date);

      expect(client.requests, hasLength(2));
      expect(second.isFallback, isFalse,
          reason: 'önbellekteki gerçek veri dönmeli');
      for (var i = 0; i < second.times.length; i++) {
        expect(second.times[i].type, first.times[i].type);
        expect(second.times[i].dateTime, first.times[i].dateTime);
      }
      expect(second.date, first.date);
      expect(second.location.city, first.location.city);
    });

    test('boş önbellekle birincil hatası demo yedeğine düşer', () async {
      final storage = MemoryStorage();
      final client = FakeNetworkClient(
        response:
            const Failure(AppFailure('timeout', 'Bağlantı zaman aşımına uğradı.')),
      );
      final repo = ResilientPrayerTimesRepository(
        primary: ApiPrayerTimesRepository(
            network: client, endpoint: _apiEndpoint),
        cache: storage,
      );

      final result = await repo.getDaily(_location, _date);
      expect(result.isFallback, isTrue);
      expect(result.times, hasLength(6));
    });

    test('bozuk önbellek içeriği demo yedeğine düşer', () async {
      final storage = MemoryStorage();
      await storage.write(
        PrayerTimesCache.keyFor(_location.city, _date),
        '{bozuk-json',
      );
      final repo = ResilientPrayerTimesRepository(
        primary: StubRepository(error: StateError('ağ yok')),
        cache: storage,
      );

      final result = await repo.getDaily(_location, _date);
      expect(result.isFallback, isTrue);
    });

    test('cache null iken eski davranış korunur', () async {
      final failingRepo = ResilientPrayerTimesRepository(
        primary: StubRepository(error: StateError('ağ yok')),
      );
      final fallbackResult = await failingRepo.getDaily(_location, _date);
      expect(fallbackResult.isFallback, isTrue);
      expect(fallbackResult.times, hasLength(6));

      final successResult = await ResilientPrayerTimesRepository(
        primary: StubRepository(
          result: DailyPrayerTimes(
              date: _date, location: _location, times: const []),
        ),
      ).getDaily(_location, _date);
      expect(successResult.isFallback, isFalse);
    });

    test('isFallback=true sonuç önbelleğe yazılmaz', () async {
      final storage = MemoryStorage();
      final stub = StubRepository(
        result: DailyPrayerTimes(
          date: _date,
          location: _location,
          isFallback: true,
          times: const [],
        ),
      );
      final repo = ResilientPrayerTimesRepository(
          primary: stub, cache: storage);

      await repo.getDaily(_location, _date);
      expect(
        await storage.read(PrayerTimesCache.keyFor(_location.city, _date)),
        isNull,
      );

      stub.error = 'birincil çöktü';
      final result = await repo.getDaily(_location, _date);
      expect(result.isFallback, isTrue, reason: 'demo yedeği kullanılmalı');
    });
  });

  group('PrayerTimesCache', () {
    test('anahtar şehir adını normalize eder', () {
      expect(
        PrayerTimesCache.keyFor(' New York ', _date),
        'prayer_cache_new_york_2026-08-23',
      );
      expect(
        PrayerTimesCache.keyFor('nevşehir', DateTime(2026, 1, 2)),
        'prayer_cache_nevşehir_2026-01-02',
      );
    });

    test('storage null iken tüm işlemler no-op\'tur', () async {
      final cache = const PrayerTimesCache();
      expect(await cache.read('Nevşehir', _date), isNull);
      await cache.write(DailyPrayerTimes(
        date: _date,
        location: _location,
        times: const [],
      ));
      expect(await cache.read('Nevşehir', _date), isNull);
    });

    test('write/read gidiş dönüşü tüm alanları korur', () async {
      final storage = MemoryStorage();
      final cache = PrayerTimesCache(storage: storage);
      final original = DailyPrayerTimes(
        date: _date,
        location: _location,
        isFallback: false,
        times: [
          PrayerTime(type: PrayerType.imsak, dateTime: _date),
          PrayerTime(
              type: PrayerType.aksam,
              dateTime: DateTime(2026, 8, 23, 19, 31)),
        ],
      );

      await cache.write(original);
      final restored = await cache.read('NEVŞEHİR', _date);

      expect(restored, isNotNull);
      expect(restored!.date, original.date);
      expect(restored.isFallback, original.isFallback);
      expect(restored.location.city, original.location.city);
      expect(restored.location.latitude, original.location.latitude);
      expect(restored.location.longitude, original.location.longitude);
      expect(restored.times, hasLength(2));
      expect(restored.times[0].type, PrayerType.imsak);
      expect(restored.times[0].dateTime, original.times[0].dateTime);
      expect(restored.times[1].type, PrayerType.aksam);
      expect(restored.times[1].dateTime, original.times[1].dateTime);
    });

    test('okunmayan şehir/tarih için null döner', () async {
      final cache = PrayerTimesCache(storage: MemoryStorage());
      expect(await cache.read('Ankara', _date), isNull);
    });
  });
}
