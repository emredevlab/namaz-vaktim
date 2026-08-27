import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_vaktim/core/notification_service.dart';
import 'package:namaz_vaktim/features/prayer/prayer_controller.dart';
import 'package:namaz_vaktim/features/prayer/prayer_models.dart';
import 'package:namaz_vaktim/features/prayer/prayer_repository.dart';

final class _RecordingScheduler implements LocalNotificationScheduler {
  final entries = <({int id, String title, String body, DateTime time})>[];
  final dailyAnchors = <DateTime>[];
  int cancelCount = 0;

  Iterable<int> get ids => entries.map((entry) => entry.id);

  @override
  Future<void> cancelAll() async => cancelCount++;

  @override
  Future<void> cancelByIds(Set<int> ids) async => cancelCount++;

  @override
  Future<void> schedulePrayer({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    String? sound,
  }) async =>
      entries.add((id: id, title: title, body: body, time: time));

  @override
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime anchor,
  }) async =>
      dailyAnchors.add(anchor);

  @override
  Future<void> scheduleTestNotification({String? sound}) async {}

  @override
  Future<void> showTestNotificationNow() async {}
  @override
  Future<void> showSoundPreview(String sound) async {}

  @override
  Future<bool?> canScheduleExactAlarms() async => null;

  @override
  Future<List<String>> eventLog() async => const [];

  @override
  Future<List<ScheduledNotificationInfo>> pendingNotifications() async =>
      const [];

  @override
  String? get lastError => null;

  @override
  Future<String?> initialPayload() async => null;
}

final class _StubRepository implements PrayerTimesRepository {
  _StubRepository(this._responses);

  /// Sıradaki çağrının döneceği yanıtlar; kuyruk boşsa hata fırlatır.
  final List<DailyPrayerTimes> _responses;

  /// Tarih bazlı sabit yanıtlar; eşleşirse kuyruğa bakılmadan döner.
  final _scheduledByDate = <DateTime, DailyPrayerTimes>{};

  /// Bu tarihlerdeki çağrılar hata fırlatmaya zorlanır.
  final _failingDates = <DateTime>{};
  final locations = <UserLocation>[];
  final dates = <DateTime>[];
  int callCount = 0;

  void addResponse(DailyPrayerTimes response) => _responses.add(response);

  /// Belirli bir güne sabit yanıt tanımlar (tarih duyarlı stub).
  void addResponseForDate(DateTime date, DailyPrayerTimes response) =>
      _scheduledByDate[_day(date)] = response;

  /// Belirli gün için yapılan çağrının hata vermesini sağlar.
  void failOnDate(DateTime date) => _failingDates.add(_day(date));

  @override
  Future<DailyPrayerTimes> getDaily(
      UserLocation location, DateTime date) async {
    callCount++;
    locations.add(location);
    final key = _day(date);
    dates.add(key);
    if (_failingDates.contains(key)) {
      throw StateError('network down');
    }
    final scheduled = _scheduledByDate[key];
    if (scheduled != null) {
      return scheduled;
    }
    if (_responses.isEmpty) {
      throw StateError('network down');
    }
    return _responses.removeAt(0);
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);
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

/// Verilen günün tamamı (6 vakit) için yanıt üretir; imsak dakikası
/// parametrik olduğu için sessiz yenileme testlerinde değişim izlenebilir.
DailyPrayerTimes _timesOn(
  DateTime date,
  UserLocation location, {
  int imsakMinute = 30,
}) =>
    DailyPrayerTimes(
      date: date,
      location: location,
      times: [
        for (final type in PrayerType.values)
          PrayerTime(
            type: type,
            dateTime: DateTime(date.year, date.month, date.day,
                _hourOf(type), type == PrayerType.imsak ? imsakMinute : 0),
          ),
      ],
    );

int _hourOf(PrayerType type) => switch (type) {
      PrayerType.imsak => 4,
      PrayerType.gunes => 6,
      PrayerType.ogle => 13,
      PrayerType.ikindi => 16,
      PrayerType.aksam => 19,
      PrayerType.yatsi => 21,
    };

void main() {
  test('periodic refresh reuses the last requested location', () async {
    final izmirTimes = _times(const UserLocation(city: 'İzmir'));
    final repository = _StubRepository([]);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Her yükleme bugün + yarın olmak üzere iki istek gönderir.
    repository.addResponseForDate(today, izmirTimes);
    repository.addResponseForDate(
        today.add(const Duration(days: 1)), izmirTimes);
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

    expect(repository.locations, hasLength(4));
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

  test('load fetches today first and then tomorrow', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final ankara = const UserLocation(city: 'Ankara');
    final repository = _StubRepository([]);
    repository.addResponseForDate(today, _timesOn(today, ankara));
    repository.addResponseForDate(tomorrow, _timesOn(tomorrow, ankara));
    final controller = PrayerController(
      repository: repository,
      notificationScheduler: const NoopNotificationScheduler(),
    );
    addTearDown(controller.dispose);

    await controller.load(location: ankara);

    expect(repository.callCount, 2,
        reason: 'Bugün ve yarın için ayrı birer istek atılmalı.');
    expect(repository.dates.first, today,
        reason: 'İstek sırası önce bugün olmalı.');
    expect(repository.dates.last, tomorrow);
    expect(controller.state.data?.date, today);
    expect(controller.state.data?.location.city, 'Ankara');
    expect(controller.state.tomorrow?.date, tomorrow);
    expect(controller.state.tomorrow?.location.city, 'Ankara');
  });

  test('tomorrow failure keeps today visible without error', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final ankara = const UserLocation(city: 'Ankara');
    final repository = _StubRepository([]);
    repository.addResponseForDate(today, _timesOn(today, ankara));
    repository.failOnDate(tomorrow);
    final controller = PrayerController(
      repository: repository,
      notificationScheduler: const NoopNotificationScheduler(),
    );
    addTearDown(controller.dispose);

    await controller.load(location: ankara);

    expect(repository.callCount, 2);
    expect(controller.state.error, isNull,
        reason: 'Yarın başarısız olsa bile hata ekranı gösterilmemeli.');
    expect(controller.state.data?.date, today);
    expect(controller.state.data?.location.city, 'Ankara');
    expect(controller.state.tomorrow, isNull);
  });

  test('silent refresh updates tomorrow prayer times', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final ankara = const UserLocation(city: 'Ankara');
    final repository = _StubRepository([]);
    repository.addResponseForDate(today, _timesOn(today, ankara));
    repository.addResponseForDate(tomorrow, _timesOn(tomorrow, ankara));
    final controller = PrayerController(
      repository: repository,
      notificationScheduler: const NoopNotificationScheduler(),
    );
    addTearDown(controller.dispose);

    await controller.load(location: ankara);
    final imsakBefore = controller.state.tomorrow?.times
        .firstWhere((time) => time.type == PrayerType.imsak);
    expect(imsakBefore?.dateTime.minute, 30);

    repository.addResponseForDate(
        tomorrow, _timesOn(tomorrow, ankara, imsakMinute: 45));

    var sawLoading = false;
    controller.addListener(() {
      if (controller.state.isLoading) sawLoading = true;
    });
    await controller.load();

    expect(sawLoading, isFalse);
    expect(controller.state.data?.date, today,
        reason: 'Sessiz yenileme bugünün verisini korumalı.');
    final imsakAfter = controller.state.tomorrow?.times
        .firstWhere((time) => time.type == PrayerType.imsak);
    expect(imsakAfter?.dateTime.minute, 45,
        reason: 'Sessiz yenileme yarının vakitlerini de güncellemeli.');
  });

  test('tomorrow notifications are scheduled with +200 offset', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final ankara = const UserLocation(city: 'Ankara');
    final repository = _StubRepository([]);
    repository.addResponseForDate(today, _timesOn(today, ankara));
    repository.addResponseForDate(tomorrow, _timesOn(tomorrow, ankara));
    final scheduler = _RecordingScheduler();
    final controller = PrayerController(
      repository: repository,
      notificationScheduler: scheduler,
    );
    addTearDown(controller.dispose);

    await controller.load(location: ankara);

    final tomorrowApproach = scheduler.ids.where((id) => id >= 200 && id < 210);
    final tomorrowOnTime = scheduler.ids.where((id) => id >= 250 && id < 260);
    // Güneş hariç BEŞ vakit: güneş namaz vakti olmadığından planlanmaz.
    expect(tomorrowApproach, hasLength(5),
        reason: 'Yarının 5 vakidi için yaklaşım bildirimi planlanmalı.');
    expect(tomorrowApproach, isNot(contains(201)),
        reason: 'Güneş (index=1) için bildirim planlanmamalı.');
    expect(tomorrowOnTime, hasLength(5),
        reason:
            'notifyAtTime varsayılan açık: yarının 5 vakdinde giriş bildirimi.');
    expect(tomorrowOnTime, isNot(contains(251)),
        reason: 'Güneş (index=1) için giriş bildirimi planlanmamalı.');
    expect(scheduler.ids, containsAll([0, 5, 50, 55]),
        reason: 'Bugünün bildirimleri de planlanmalı.');
    // İlk yüklemede senkron iki kez çalışır (bugün; bugün+yarın) ve günlük
    // hatırlatma iki kez planlanır — cihazda aynı id olduğu için zararsızdır.
    expect(scheduler.dailyAnchors, isNotEmpty);
    expect(scheduler.dailyAnchors.toSet().length, 1,
        reason: 'Günlük hatırlatma aynı imsak saatine bağlanmalı.');
  });

  test('silent refresh keeps tomorrow notifications scheduled', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final ankara = const UserLocation(city: 'Ankara');
    final repository = _StubRepository([]);
    repository.addResponseForDate(today, _timesOn(today, ankara));
    repository.addResponseForDate(tomorrow, _timesOn(tomorrow, ankara));
    final scheduler = _RecordingScheduler();
    final controller = PrayerController(
      repository: repository,
      notificationScheduler: scheduler,
    );
    addTearDown(controller.dispose);

    await controller.load(location: ankara);
    final tomorrowCountAfterFirstLoad =
        scheduler.ids.where((id) => id >= 200).length;
    expect(tomorrowCountAfterFirstLoad, 10);

    // Aynı gün içinde sessiz yenileme: plan imzası değişmediği için
    // iptal/yeniden-planlama HİÇ çalışmaz — ateşlenmek üzere bekleyen
    // yaklaşım alarmı yanlışlıkla silinemez (öğle yaklaşım kaçağı fix'i).
    final entriesBeforeRefresh = scheduler.entries.length;
    final cancelsBeforeRefresh = scheduler.cancelCount;
    await controller.load();

    expect(scheduler.entries.length, entriesBeforeRefresh,
        reason:
            'Plan değişmediğinde dakikalık yenileme bildirimlere dokunmamalı.');
    expect(scheduler.cancelCount, cancelsBeforeRefresh,
        reason: 'Plan imzası aynıysa iptal turu da çalışmamalı.');
    expect(scheduler.ids.where((id) => id >= 200).length, 10,
        reason: 'Yarının 10 bildirimi planlı olarak kalmalı.');
  });
}
