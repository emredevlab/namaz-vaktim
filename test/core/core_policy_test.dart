import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_vaktim/core/permission_manager.dart';
import 'package:namaz_vaktim/core/notification_service.dart';
import 'package:namaz_vaktim/core/web_navigation_policy.dart';
import 'package:namaz_vaktim/features/prayer/prayer_models.dart';

final class _RecordingScheduler implements LocalNotificationScheduler {
  bool cancelled = false;
  final cancelledIds = <int>{};
  final times = <DateTime>[];
  final sounds = <String?>[];
  final requests = <({int id, String title, String body, DateTime time})>[];
  final dailyAnchors = <DateTime>[];

  @override
  Future<void> cancelAll() async => cancelled = true;

  @override
  Future<void> cancelByIds(Set<int> ids) async => cancelledIds.addAll(ids);

@override
  Future<void> schedulePrayer({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    String? sound,
    bool isEntry = false,
  }) async {
    times.add(time);
    sounds.add(sound);
    requests.add((id: id, title: title, body: body, time: time));
  }

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

const _approachBody = 'Namaz vaktiniz yaklaşıyor.';

List<PrayerNotificationRequest> _allPrayerRequests() {
  final base = DateTime(2026, 8, 23, 4);
  return [
    for (final (index, type) in PrayerType.values.indexed)
      PrayerNotificationRequest(
        id: type.index,
        title: 'Vakit $index',
        prayerTime: base.add(Duration(hours: index + 1)),
      ),
  ];
}

void main() {
  group('WebNavigationPolicy', () {
    const policy = WebNavigationPolicy(
      allowedOrigins: {'https://example.com'},
    );

    test('allows HTTPS URLs from configured origins', () {
      expect(
        policy.decide(Uri.parse('https://example.com/page')),
        WebNavigationDecision.internal,
      );
    });

    test('sends HTTPS URLs from other origins externally', () {
      expect(
        policy.decide(Uri.parse('https://other.example/page')),
        WebNavigationDecision.external,
      );
    });

    test('rejects non-HTTPS URLs', () {
      expect(
        policy.decide(Uri.parse('http://example.com/page')),
        WebNavigationDecision.rejected,
      );
    });
  });

  test('notification planner schedules the configured lead time', () async {
    final scheduler = _RecordingScheduler();
    final planner = PrayerNotificationPlanner(scheduler: scheduler);
    final prayerTime = DateTime(2026, 8, 7, 12);

    await planner.synchronize(
      [
        PrayerNotificationRequest(
          id: 1,
          title: 'Öğle vakti',
          prayerTime: prayerTime,
        ),
      ],
      const NotificationPreferences(minutesBefore: 15, notifyAtTime: false),
    );

    expect(scheduler.cancelledIds, isNotEmpty,
        reason: 'Eski planlar id bazlı iptal edilmeli (cancelAll yarışı yok).');
    expect(scheduler.times.single,
        prayerTime.subtract(const Duration(minutes: 15)));
    expect(scheduler.requests.single.body, _approachBody);
  });

  test('planner schedules an on-time notification when notifyAtTime is true',
      () async {
    final scheduler = _RecordingScheduler();
    final planner = PrayerNotificationPlanner(scheduler: scheduler);
    final requests = _allPrayerRequests();

    await planner.synchronize(
        requests, const NotificationPreferences(notifyAtTime: true));

    expect(scheduler.requests.length, PrayerType.values.length * 2);
    for (final request in requests) {
      final approach =
          scheduler.requests.singleWhere((scheduled) => scheduled.id == request.id);
      expect(approach.title, request.title);
      expect(approach.body, _approachBody);
      expect(approach.time,
          request.prayerTime.subtract(const Duration(minutes: 10)));

      final onTime = scheduler.requests
          .singleWhere((scheduled) => scheduled.id == request.id + 50);
      expect(onTime.title, request.title);
      expect(onTime.body, '${request.title} vakti girdi.');
      expect(onTime.time, request.prayerTime);
    }
  });

  test('planner cancels only managed ids and keeps the test notification',
      () async {
    final scheduler = _RecordingScheduler();
    final planner = PrayerNotificationPlanner(scheduler: scheduler);
    final requests = _allPrayerRequests();

    await planner.synchronize(
        requests, const NotificationPreferences(notifyAtTime: true));

    expect(scheduler.cancelledIds, containsAll([0, 5, 50, 55, 100]),
        reason: 'Vakit, vakit girişi (+50) ve günlük hatırlatma id\'leri '
            'iptal kapsamında olmalı.');
    expect(scheduler.cancelledIds, isNot(contains(999)),
        reason: 'Dakikalık yenileme, bekleyen 5 sn test bildirimini '
            '(id=999) silmemeli.');
  });

  test('planner skips on-time notifications when notifyAtTime is false',
      () async {
    final scheduler = _RecordingScheduler();
    final planner = PrayerNotificationPlanner(scheduler: scheduler);
    final requests = _allPrayerRequests();

    await planner.synchronize(
        requests, const NotificationPreferences(notifyAtTime: false));

    expect(scheduler.requests.length, PrayerType.values.length);
    for (final scheduled in scheduler.requests) {
      expect(scheduled.id, lessThan(50));
      expect(scheduled.body, _approachBody);
      final source = requests.singleWhere((request) => request.id == scheduled.id);
      expect(scheduled.time,
          source.prayerTime.subtract(const Duration(minutes: 10)));
    }
  });

  test('notification planner rejects unsupported lead times', () async {
    final scheduler = _RecordingScheduler();

    expect(
      () => PrayerNotificationPlanner(scheduler: scheduler).synchronize(
        const [],
        const NotificationPreferences(minutesBefore: 5),
      ),
      throwsArgumentError,
    );
  });

  test('daily reminder schedules a repeating notification at imsak', () async {
    final scheduler = _RecordingScheduler();
    final planner = PrayerNotificationPlanner(scheduler: scheduler);
    final imsakTime = DateTime(2026, 8, 22, 4, 21);

    await planner.synchronize(
      [
        PrayerNotificationRequest(
          id: PrayerType.imsak.index,
          title: 'İmsak',
          prayerTime: imsakTime,
        ),
        PrayerNotificationRequest(
          id: PrayerType.gunes.index,
          title: 'Güneş',
          prayerTime: imsakTime.add(const Duration(hours: 2)),
        ),
      ],
      const NotificationPreferences(dailyReminder: true),
    );

    expect(scheduler.dailyAnchors.single, imsakTime);
    expect(
      PrayerNotificationPlanner.dailyReminderNotificationId,
      isNot(anyOf(PrayerType.values.map((type) => type.index))),
    );
  });

  test('daily reminder is skipped when notifications are disabled', () async {
    final scheduler = _RecordingScheduler();
    final planner = PrayerNotificationPlanner(scheduler: scheduler);

    await planner.synchronize(
      [
        PrayerNotificationRequest(
          id: PrayerType.imsak.index,
          title: 'İmsak',
          prayerTime: DateTime(2026, 8, 22, 4, 21),
        ),
      ],
      const NotificationPreferences(enabled: false),
    );

    expect(scheduler.times, isEmpty);
    expect(scheduler.dailyAnchors, isEmpty);
  });

  test('permission rationale explains each permission in Turkish', () {
    const policy = PermissionRationalePolicy();

    final notification = policy.forPermission(AppPermission.notification);
    final location = policy.forPermission(AppPermission.location);

    expect(notification.title, 'Bildirim izni gerekli');
    expect(notification.message, contains('hatırlatma'));
    expect(notification.actionLabel, 'Bildirimlere izin ver');
    expect(location.title, 'Konum izni gerekli');
    expect(location.message, contains('namaz vakitlerini'));
    expect(location.actionLabel, 'Konuma izin ver');
    expect(
      policy.permanentlyDeniedMessage(AppPermission.location),
      contains('Android ayarlarından'),
    );
  });

  test('noop permission manager fails closed', () async {
    const manager = NoopPermissionManager();

    expect(
      await manager.status(AppPermission.location),
      PermissionStatus.denied,
    );
    expect(
      await manager.request(AppPermission.notification),
      PermissionStatus.denied,
    );
    expect(await manager.openSettings(), isFalse);
  });
}
