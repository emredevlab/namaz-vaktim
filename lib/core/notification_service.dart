import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../features/prayer/prayer_models.dart';

class NotificationPreferences {
  const NotificationPreferences(
      {this.enabled = true,
      this.minutesBefore = 10,
      this.dailyReminder = true,
      this.notifyAtTime = true,
      this.approachSound = 'notification_chime',
      this.entrySound = 'ezan_mekke'});

  /// Yaklaşım bildirimi sesi: res/raw altındaki dosya adı (uzantısız)
  /// veya 'default' = sistem sesi.
  static const approachSoundOptions = {
    'notification_chime': 'Zil sesi',
    'ezan_mekke': 'Ezan (Mekke)',
    'default': 'Sistem sesi',
  };

  /// Vakit girişi bildirimi sesi.
  static const entrySoundOptions = {
    'ezan_mekke': 'Ezan (Mekke)',
    'ezan_medine': 'Ezan (Medine)',
    'notification_chime': 'Zil sesi',
    'default': 'Sistem sesi',
  };

  final bool enabled;
  final int minutesBefore;
  final bool dailyReminder;
  final bool notifyAtTime;
  final String approachSound;
  final String entrySound;

  NotificationPreferences copyWith(
          {bool? enabled,
          int? minutesBefore,
          bool? dailyReminder,
          bool? notifyAtTime,
          String? approachSound,
          String? entrySound}) =>
      NotificationPreferences(
        enabled: enabled ?? this.enabled,
        minutesBefore: minutesBefore ?? this.minutesBefore,
        dailyReminder: dailyReminder ?? this.dailyReminder,
        notifyAtTime: notifyAtTime ?? this.notifyAtTime,
        approachSound: approachSound ?? this.approachSound,
        entrySound: entrySound ?? this.entrySound,
      );
}

final class NotificationPreferencesStore {
  const NotificationPreferencesStore(this._preferences) : _memory = null;
  NotificationPreferencesStore.memory()
      : _preferences = null,
        _memory = {};

  static const _enabledKey = 'notifications.enabled';
  static const _minutesBeforeKey = 'notifications.minutes_before';
  static const _dailyReminderKey = 'notifications.daily_reminder';
  static const _notifyAtTimeKey = 'notifications.notify_at_time';
  static const _approachSoundKey = 'notifications.approach_sound';
  static const _entrySoundKey = 'notifications.entry_sound';

  final SharedPreferences? _preferences;
  final Map<String, Object?>? _memory;

  Object? _get(String key) => _preferences?.get(key) ?? _memory?[key];

  NotificationPreferences read() => NotificationPreferences(
        enabled: _get(_enabledKey) as bool? ?? true,
        minutesBefore: _get(_minutesBeforeKey) as int? ?? 10,
        dailyReminder: _get(_dailyReminderKey) as bool? ?? true,
        notifyAtTime: _get(_notifyAtTimeKey) as bool? ?? true,
        approachSound:
            _get(_approachSoundKey) as String? ?? 'notification_chime',
        entrySound: _get(_entrySoundKey) as String? ?? 'ezan_mekke',
      );

  Future<void> write(NotificationPreferences value) async {
    if (_preferences case final preferences?) {
      await preferences.setBool(_enabledKey, value.enabled);
      await preferences.setInt(_minutesBeforeKey, value.minutesBefore);
      await preferences.setBool(_dailyReminderKey, value.dailyReminder);
      await preferences.setBool(_notifyAtTimeKey, value.notifyAtTime);
      await preferences.setString(_approachSoundKey, value.approachSound);
      await preferences.setString(_entrySoundKey, value.entrySound);
    } else {
      _memory![_enabledKey] = value.enabled;
      _memory[_minutesBeforeKey] = value.minutesBefore;
      _memory[_dailyReminderKey] = value.dailyReminder;
      _memory[_notifyAtTimeKey] = value.notifyAtTime;
      _memory[_approachSoundKey] = value.approachSound;
      _memory[_entrySoundKey] = value.entrySound;
    }
  }
}

/// Planlanmış bir bildirimin özet bilgisi (teşhis ekranı için).
final class ScheduledNotificationInfo {
  const ScheduledNotificationInfo({
    required this.id,
    required this.title,
    required this.body,
  });

  final int id;
  final String title;
  final String body;
}

abstract interface class LocalNotificationScheduler {
  Future<void> schedulePrayer(
      {required int id,
      required String title,
      required String body,
      required DateTime time,
      String? sound});

  /// [anchor] zamanının saat/dakika bileşeniyle her gün tekrarlanan bildirim.
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime anchor,
  });

  /// Teşhis için: ~5 saniya sonra tetiklenen test bildirimi.
  Future<void> scheduleTestNotification();

  /// Teşhis için: alarm/planlama olmadan HEMEN gösterilen bildirim.
  /// Bu görünürse gösterim katmanı sağlamdır; sorun alarm katmanındadır.
  Future<void> showTestNotificationNow();

  /// Cihaz exact alarm planlayabiliyor mu (Android 12+ izin durumu).
  Future<bool?> canScheduleExactAlarms();

  /// Şu an sistemde planlı bekleyen bildirimlerin özeti.
  Future<List<ScheduledNotificationInfo>> pendingNotifications();

  /// Son planlama hatası; teşhis ekranında gösterilir. Hata yoksa null.
  String? get lastError;

  Future<String?> initialPayload();

  Future<void> cancelAll();
}

final class PrayerNotificationRequest {
  const PrayerNotificationRequest({
    required this.id,
    required this.title,
    required this.prayerTime,
  });

  final int id;
  final String title;
  final DateTime prayerTime;
}

final class PrayerNotificationPlanner {
  const PrayerNotificationPlanner({required this.scheduler});

  final LocalNotificationScheduler scheduler;

  static const int dailyReminderNotificationId = 100;
  static const Set<int> _supportedLeadMinutes = {10, 15, 30};

  Future<void> synchronize(Iterable<PrayerNotificationRequest> requests,
      NotificationPreferences preferences) async {
    await scheduler.cancelAll();
    if (!preferences.enabled) return;
    if (!_supportedLeadMinutes.contains(preferences.minutesBefore)) {
      throw ArgumentError.value(
        preferences.minutesBefore,
        'minutesBefore',
        'Bildirim süresi 10, 15 veya 30 dakika olmalıdır.',
      );
    }
    for (final request in requests) {
      final scheduledTime = request.prayerTime.subtract(
        Duration(minutes: preferences.minutesBefore),
      );
      await scheduler.schedulePrayer(
        id: request.id,
        title: request.title,
        body: 'Namaz vaktiniz yaklaşıyor.',
        time: scheduledTime,
        sound: preferences.approachSound,
      );
      if (preferences.notifyAtTime) {
        await scheduler.schedulePrayer(
          id: request.id + 50,
          title: request.title,
          body: '${request.title} vakti girdi.',
          time: request.prayerTime,
          sound: preferences.entrySound,
        );
      }
    }
    if (preferences.dailyReminder && requests.isNotEmpty) {
      // Günlük hatırlatma, imsak vaktine göre her gün tekrarlanır.
      final anchor = requests
          .firstWhere(
            (request) => request.id == PrayerType.imsak.index,
            orElse: () => requests.first,
          )
          .prayerTime;
      await scheduler.scheduleDailyReminder(
        id: dailyReminderNotificationId,
        title: 'Namaz Vaktim',
        body: 'Günlük namaz vakitlerini görmek için dokun.',
        anchor: anchor,
      );
    }
  }
}

final class AndroidNotificationScheduler implements LocalNotificationScheduler {
  AndroidNotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    void Function(String? payload)? onNotificationTap,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _onNotificationTap = onNotificationTap;

  final FlutterLocalNotificationsPlugin _plugin;
  final void Function(String? payload)? _onNotificationTap;
  bool _initialized = false;
  String? _lastError;

  static const String _channelId = 'prayer_times';
  static const String _channelName = 'Namaz vakitleri';
  static const String _channelDescription = 'Namaz vakti hatırlatmaları';

  /// Ses başına ayrı Android kanalı gerekir: kanal ses ayarı ilk
  /// yaratıldığında sabitlenir. Ses değişince yeni kanal id'si kullanılır.
  NotificationDetails _notificationDetails(String? sound) {
    final channelKey = sound == null || sound == 'default'
        ? 'default'
        : sound.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final androidDetails = AndroidNotificationDetails(
      '$_channelId$channelKey',
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      sound: sound == null || sound == 'default'
          ? null
          : RawResourceAndroidNotificationSound(sound),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
    return NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails());
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // KRİTİK: setLocalLocation çağrılmazsa tz.local UTC'ye düşer ve
    // bildirimler Türkiye'de 3 saat gecikmeli planlanır. Cihazın saat
    // dilimi okunamazsa Türkçe uygulama olduğu için İstanbul'a düşer.
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      } catch (_) {
        // Saat dilimi veritabanı tamamen yoksa UTC ile devam (en kötü durum).
      }
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _onNotificationTap?.call(response.payload);
      },
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    // İzin istekleri BURADA yapılmaz: açılış anında tetiklenince diyalog
    // yutuluyordu (exact alarm ayar ekranı üzerine açılıyordu). Bildirim
    // izni HomeScreen ilk kare sonrası PermissionManager üzerinden istenir;
    // exact alarm ise manifest'teki USE_EXACT_ALARM ile otomatik taninir.
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    ));
    _initialized = true;
  }

  @override
  Future<void> schedulePrayer({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    String? sound,
  }) async {
    await _ensureInitialized();
    if (!time.isAfter(DateTime.now())) return;
    try {
      await _zonedSchedule(
        id: id,
        title: title,
        body: body,
        time: time,
        payload: 'route:/prayer-times',
        daily: false,
        sound: sound,
      );
      _lastError = null;
    } catch (error) {
      _lastError = 'schedulePrayer($id): $error';
    }
  }

  @override
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime anchor,
  }) async {
    await _ensureInitialized();
    try {
      await _zonedSchedule(
        id: id,
        title: title,
        body: body,
        time: anchor,
        payload: 'route:/prayer-times',
        daily: true,
      );
      _lastError = null;
    } catch (error) {
      _lastError = 'scheduleDailyReminder: $error';
    }
  }

  @override
  Future<void> scheduleTestNotification() async {
    await _ensureInitialized();
    try {
      await _zonedSchedule(
        id: 999,
        title: 'Test bildirimi (5 sn)',
        body: 'Bildirim sistemi çalışıyor. Namaz vakitleri de böyle gelecek.',
        time: DateTime.now().add(const Duration(seconds: 5)),
        payload: 'route:/prayer-times',
        daily: false,
      );
      _lastError = null;
    } catch (error) {
      _lastError = 'scheduleTestNotification: $error';
    }
  }

  @override
  Future<void> showTestNotificationNow() async {
    await _ensureInitialized();
    try {
      await _plugin.show(
        998,
        'Test bildirimi (anında)',
        'Gösterim katmanı çalışıyor. Namaz vakitleri de böyle görünecek.',
        _notificationDetails(null),
        payload: 'route:/prayer-times',
      );
      _lastError = null;
    } catch (error) {
      _lastError = 'showTestNotificationNow: $error';
    }
  }

  @override
  Future<bool?> canScheduleExactAlarms() async {
    try {
      // Android 12+ exact alarm izni; USE_EXACT_ALARM manifest'te
      // bulunduğundan genellikle otomatik tanınır.
      final status = await ph.Permission.scheduleExactAlarm.status;
      return status.isGranted || status.isLimited;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ScheduledNotificationInfo>> pendingNotifications() async {
    try {
      await _ensureInitialized();
      final pending = await _plugin.pendingNotificationRequests();
      return [
        for (final request in pending)
          ScheduledNotificationInfo(
            id: request.id,
            title: request.title ?? '',
            body: request.body ?? '',
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  String? get lastError => _lastError;

  @override
  Future<String?> initialPayload() async {
    try {
      await _ensureInitialized();
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      return details.notificationResponse?.payload;
    } catch (_) {
      return null;
    }
  }

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    required String payload,
    required bool daily,
    String? sound,
  }) async {
    // Ses bazlı kanal, planlamadan ÖNCE var olmalı (plugin otomatik
    // yaratmaz). Kanal kurulumu başarısız olursa sesli kanal yerine
    // varsayılan kanalla devam edilir — planlama asla engellenmez.
    var details = _notificationDetails(sound);
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (sound != null && sound != 'default') {
      try {
        final androidDetails = details.android;
        if (android != null && androidDetails != null) {
          await android.createNotificationChannel(
              AndroidNotificationChannel(
            androidDetails.channelId,
            androidDetails.channelName,
            description: androidDetails.channelDescription,
            importance: androidDetails.importance,
            sound: androidDetails.sound,
            audioAttributesUsage: androidDetails.audioAttributesUsage,
          ));
        }
      } catch (error) {
        _lastError = 'Ses kanalı oluşturulamadı ($sound): $error';
        details = _notificationDetails(null);
      }
    }
    try {
      await _scheduleWithMode(
        id: id,
        title: title,
        body: body,
        time: time,
        payload: payload,
        daily: daily,
        details: details,
        mode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return;
    } catch (_) {
      // Exact alarm izni/uygulanabilirliği yoksa inexact ile devam —
      // gecikmeli de olsa bildirim gelmesi sessiz kalmaktan iyidir.
    }
    _lastError = 'Exact alarm yok, inexact modda planlandı (gecikebilir).';
    await _scheduleWithMode(
      id: id,
      title: title,
      body: body,
      time: time,
      payload: payload,
      daily: daily,
      details: details,
      mode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _scheduleWithMode({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    required String payload,
    required bool daily,
    required NotificationDetails details,
    required AndroidScheduleMode mode,
  }) =>
      _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(time, tz.local),
        details,
        payload: payload,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            daily ? DateTimeComponents.time : null,
      );

  @override
  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }
}

final class NoopNotificationScheduler implements LocalNotificationScheduler {
  const NoopNotificationScheduler();
  @override
  Future<void> schedulePrayer(
      {required int id,
      required String title,
      required String body,
      required DateTime time,
      String? sound}) async {}
  @override
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime anchor,
  }) async {}
  @override
  Future<void> scheduleTestNotification() async {}
  @override
  Future<void> showTestNotificationNow() async {}
  @override
  Future<bool?> canScheduleExactAlarms() async => null;
  @override
  Future<List<ScheduledNotificationInfo>> pendingNotifications() async =>
      const [];
  @override
  String? get lastError => null;
  @override
  Future<String?> initialPayload() async => null;
  @override
  Future<void> cancelAll() async {}
}
