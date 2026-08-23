import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_vaktim/core/notification_service.dart';
import 'package:namaz_vaktim/features/prayer/prayer_controller.dart';
import 'package:namaz_vaktim/features/prayer/prayer_models.dart';
import 'package:namaz_vaktim/features/prayer/prayer_repository.dart';

final class _StubRepository implements PrayerTimesRepository {
  _StubRepository(this._responses);

  /// Sıradaki çağrının döneceği yanıtlar; kuyruk boşsa hata fırlatır.
  final List<DailyPrayerTimes> _responses;
  final locations = <UserLocation>[];
  int callCount = 0;

  void addResponse(DailyPrayerTimes response) => _responses.add(response);

  @override
  Future<DailyPrayerTimes> getDaily(
      UserLocation location, DateTime date) async {
    callCount++;
    locations.add(location);
    if (_responses.isEmpty) {
      throw StateError('network down');
    }
    return _responses.removeAt(0);
  }
}

DailyPrayerTimes _times(UserLocation location) => DailyPrayerTimes(
      date: DateTime(2026, 8, 22),
      location: location,
      times: [
        PrayerTime(
          type: PrayerType.imsak,
          dateTime: DateTime(2026, 8, 22, 4, 21),
        ),
        PrayerTime(
          type: PrayerType.gunes,
          dateTime: DateTime(2026, 8, 22, 5, 55),
        ),
      ],
    );

void main() {
  test('periodic refresh reuses the last requested location', () async {
    final izmirTimes = _times(const UserLocation(city: 'İzmir'));
    final repository = _StubRepository([izmirTimes, izmirTimes]);
    final controller = PrayerController(
      repository: repository,
      notificationScheduler: const NoopNotificationScheduler(),
    );
    addTearDown(controller.dispose);

    await controller.load(
      location: const UserLocation(
        city: 'İzmir',
        latitude: 38.4237,
        longitude: 27.1428,
      ),
    );

    // Dakikalık timer'ı simüle et: load() parametresiz çağrılır.
    await controller.load();

    expect(repository.locations, hasLength(2));
    expect(repository.locations.last.city, 'İzmir');
    expect(repository.locations.last.latitude, 38.4237);
    expect(controller.state.data?.location.city, 'İzmir');
  });

  test('silent refresh keeps existing data visible and does not flash loading',
      () async {
    final repository = _StubRepository([
      _times(const UserLocation(city: 'Ankara')),
      _times(const UserLocation(city: 'Ankara')),
    ]);
    final controller = PrayerController(
      repository: repository,
      notificationScheduler: const NoopNotificationScheduler(),
    );
    addTearDown(controller.dispose);

    await controller.load(location: const UserLocation(city: 'Ankara'));
    expect(controller.state.isLoading, isFalse);

    var sawLoading = false;
    controller.addListener(() {
      if (controller.state.isLoading) sawLoading = true;
    });
    await controller.load();

    expect(sawLoading, isFalse,
        reason: 'Veri varken sessiz yenileme spinner göstermemeli.');
    expect(controller.state.data?.location.city, 'Ankara');
  });

  test('failed silent refresh keeps stale data instead of error screen',
      () async {
    final repository = _StubRepository([
      _times(const UserLocation(city: 'Bursa')),
    ]);
    final controller = PrayerController(
      repository: repository,
      notificationScheduler: const NoopNotificationScheduler(),
    );
    addTearDown(controller.dispose);

    await controller.load(location: const UserLocation(city: 'Bursa'));
    await controller.load(); // stub ikinci çağrıda hata fırlatır

    expect(controller.state.error, isNull);
    expect(controller.state.data?.location.city, 'Bursa');
  });

  test('first load failure reports error and retry uses same location',
      () async {
    final repository = _StubRepository([]);
    final controller = PrayerController(
      repository: repository,
      notificationScheduler: const NoopNotificationScheduler(),
    );
    addTearDown(controller.dispose);

    await controller.load(location: const UserLocation(city: 'Konya'));
    expect(controller.state.error, isNotNull);
    expect(controller.state.data, isNull);

    // Retry butonu parametresiz load() çağırır; konum korunmalı.
    repository.addResponse(_times(const UserLocation(city: 'Konya')));
    await controller.load();
    expect(controller.state.error, isNull);
    expect(repository.locations.last.city, 'Konya');
  });
}
