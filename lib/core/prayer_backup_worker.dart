import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../shared/formatting.dart';
import '../features/prayer/prayer_models.dart';

/// Alarm katmanı üretici (Xiaomi vb.) tarafından engellense bile
/// 15 dakikada bir çalışan yedek görev: vakti yeni girmiş namazı
/// tespit edip ezan sesli bildirimle gönderir. Kullanıcıdan hiçbir
/// ayar istemez — "hacı amca" garantisi buradan gelir.
const String prayerBackupTaskName = 'prayerBackupCheck';
const String _backupDataKey = 'notification_backup_data';
const String _lastFiredKey = 'notification_backup_last_fired';

const String _backupChannelName = 'Namaz vakitleri';

/// Controller başarılı yüklemede bugünün vakitlerini buraya yazar;
/// yedek görev bu veriyle çalışır (ağ gerekmez).
Future<void> writeBackupData(DailyPrayerTimes data) async {
  try {
    final preferences = await SharedPreferences.getInstance();
    final times = <String, String>{
      for (final time in data.times)
        time.type.name:
            '${time.dateTime.hour.toString().padLeft(2, '0')}:${time.dateTime.minute.toString().padLeft(2, '0')}',
    };
    await preferences.setString(
      _backupDataKey,
      jsonEncode({
        'date':
            '${data.date.year}-${data.date.month.toString().padLeft(2, '0')}-${data.date.day.toString().padLeft(2, '0')}',
        'times': times,
      }),
    );
  } catch (_) {
    // Yedek veri yazılamazsa sessiz geç; alarm katmanı zaten çalışıyor.
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final preferences = await SharedPreferences.getInstance();

      // Kullanıcı tercihine saygı: bildirimler kapalıysa veya vakit
      // girişi bildirimi istenmiyorsa yedek görev sessiz kalır.
      // (Anahtar adları NotificationPreferencesStore ile aynıdır.)
      if (!(preferences.getBool('notifications.enabled') ?? true)) return true;
      if (!(preferences.getBool('notifications.notify_at_time') ?? true)) {
        return true;
      }

      final raw = preferences.getString(_backupDataKey);
      if (raw == null) return true;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final dateRaw = '${decoded['date']}';
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (dateRaw != today) return true; // Bayat veri — bugünkü yok.

      final times = decoded['times'] as Map<String, dynamic>;
      final lastFired = preferences.getString(_lastFiredKey);

      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      } catch (_) {}

      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ));

      // Tercihleri oku — yaklaşım yedeği için minutesBefore/approachSound lazım.
      final minutesBefore = preferences.getInt('notifications.minutes_before') ?? 10;
      final approachSound =
          preferences.getString('notifications.approach_sound') ?? 'notification_chime';
      final entrySound =
          preferences.getString('notifications.entry_sound') ?? 'ezan_vakit';

      String sanitizeSound(String s) =>
          s.replaceAll(RegExp(r'[^a-z0-9_]'), '');
      bool isAdhan(String s) => s.startsWith('ezan');

      String channelIdFor(String sound) {
        if (sound == 'default') return 'prayer_times_v4';
        return 'prayer_times_v4${sanitizeSound(sound)}';
      }

      Future<NotificationDetails> detailsFor(String sound) async {
        final channelId = channelIdFor(sound);
        final adhan = isAdhan(sound);
        final rawSound = sound == 'default'
            ? null
            : RawResourceAndroidNotificationSound(sound);
        final androidDetails = AndroidNotificationDetails(
          channelId,
          _backupChannelName,
          channelDescription: 'Namaz vakti hatırlatmaları',
          importance: Importance.high,
          priority: Priority.high,
          sound: rawSound,
          audioAttributesUsage: adhan
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
        );
        try {
          await plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(AndroidNotificationChannel(
                channelId,
                _backupChannelName,
                description: 'Namaz vakti hatırlatmaları',
                importance: Importance.high,
                sound: rawSound,
                audioAttributesUsage: adhan
                    ? AudioAttributesUsage.alarm
                    : AudioAttributesUsage.notification,
              ));
        } catch (_) {}
        return NotificationDetails(android: androidDetails);
      }

      // En az bir kez v4 ana kanalı garanti et (entry/approach kanalları
      // ayrıca yukarıda oluşturulur).
      try {
        await plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(const AndroidNotificationChannel(
              'prayer_times_v4',
              _backupChannelName,
              description: 'Namaz vakti hatırlatmaları',
              importance: Importance.high,
            ));
      } catch (_) {}

      for (final type in PrayerType.values) {
        // Güneş namaz vakti değildir; bildirim çıkarılmaz.
        if (type == PrayerType.gunes) continue;
        final timeRaw = times[type.name];
        if (timeRaw == null) continue;
        final parts = timeRaw.split(':');
        if (parts.length < 2) continue;
        final prayer = DateTime(now.year, now.month, now.day,
            int.parse(parts[0]), int.parse(parts[1]));
        final approach = prayer.subtract(Duration(minutes: minutesBefore));

        // 1) Yaklaşım yedeği: "vakti yaklaşıyor" — OEM alarmı sildiyse 15 dk içinde telafi.
        final sinceApproach = now.difference(approach);
        if (sinceApproach.inMinutes >= 0 && sinceApproach.inMinutes <= 15) {
          final firedKey = '${type.name}_approach_$today';
          // lastFired tek bir string tuttuğu için güncel değeri her tur yeniden oku
          final currentLast = preferences.getString(_lastFiredKey);
          if (currentLast != firedKey) {
            final approachDetails = await detailsFor(approachSound);
            await plugin.show(
              400 + type.index,
              prayerTypeLabel(type),
              'Namaz vaktiniz yaklaşıyor.',
              approachDetails,
              payload: 'route:/prayer-times',
            );
            await preferences.setString(_lastFiredKey, firedKey);
          }
        }

        // 2) Vakit girişi yedeği.
        final since = now.difference(prayer);
        if (since.inMinutes >= 0 && since.inMinutes <= 15) {
          final firedKey = '${type.name}_entry_$today';
          final currentLast = preferences.getString(_lastFiredKey);
          if (currentLast == firedKey) continue;
          // Geriye uyum: eski tek-anahtarlı kaydı da kontrol et
          if (lastFired == '${type.name}_$today') continue;
          final entryDetails = await detailsFor(entrySound);
          await plugin.show(
            300 + type.index,
            prayerTypeLabel(type),
            '${prayerTypeLabel(type)} vakti girdi.',
            entryDetails,
            payload: 'route:/prayer-times',
          );
          await preferences.setString(_lastFiredKey, firedKey);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  });
}
