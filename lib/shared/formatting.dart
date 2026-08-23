import 'package:flutter/material.dart';

import '../features/prayer/prayer_models.dart';

String prayerTypeLabel(PrayerType type) => switch (type) {
      PrayerType.imsak => 'İmsak',
      PrayerType.gunes => 'Güneş',
      PrayerType.ogle => 'Öğle',
      PrayerType.ikindi => 'İkindi',
      PrayerType.aksam => 'Akşam',
      PrayerType.yatsi => 'Yatsı',
    };

String formatPrayerTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String formatPrayerDate(DateTime value) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık'
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

IconData prayerIcon(PrayerType type) => switch (type) {
      PrayerType.imsak => Icons.nightlight_outlined,
      PrayerType.gunes => Icons.wb_sunny_outlined,
      PrayerType.ogle => Icons.light_mode_outlined,
      PrayerType.ikindi => Icons.wb_twilight_outlined,
      PrayerType.aksam => Icons.nights_stay_outlined,
      PrayerType.yatsi => Icons.dark_mode_outlined,
    };
