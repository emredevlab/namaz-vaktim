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
      const androidDetails = AndroidNotificationDetails(
        'prayer_times_v2ezan_vakit',
        'Namaz vakitleri',
        channelDescription: 'Namaz vakti hatırlatmaları',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('ezan_vakit'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );
      const details = NotificationDetails(android: androidDetails);

      for (final type in PrayerType.values) {
        final timeRaw = times[type.name];
        if (timeRaw == null) continue;
        final parts = timeRaw.split(':');
        if (parts.length < 2) continue;
        final prayer = DateTime(now.year, now.month, now.day,
            int.parse(parts[0]), int.parse(parts[1]));
        final since = now.difference(prayer);
        // Vakti son 15 dakika içinde girdiyse ve henüz bildirilmediyse gönder.
        if (since.inMinutes >= 0 && since.inMinutes <= 15) {
          final firedKey = '${type.name}_$today';
          if (lastFired == firedKey) continue;
          await plugin.show(
            300 + type.index,
            prayerTypeLabel(type),
            '${prayerTypeLabel(type)} vakti girdi.',
            details,
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
