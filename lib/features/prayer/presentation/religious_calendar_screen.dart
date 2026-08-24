import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_providers.dart';
import '../../../shared/design/app_theme.dart';
import '../../../shared/formatting.dart';
import '../religious_days.dart';

/// Drawer'dan açılan dini takvim: gelecek 1 yılın dini günleri,
/// Aladhan hToG ile her yıl otomatik güncel.
class ReligiousCalendarScreen extends ConsumerStatefulWidget {
  const ReligiousCalendarScreen({super.key});

  @override
  ConsumerState<ReligiousCalendarScreen> createState() =>
      _ReligiousCalendarScreenState();
}

class _ReligiousCalendarScreenState
    extends ConsumerState<ReligiousCalendarScreen> {
  late Future<List<UpcomingReligiousDay>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<UpcomingReligiousDay>> _load() async {
    final hijriYear = await _resolveCurrentHijriYear();
    return upcomingReligiousDays(
      currentHijriYear: hijriYear,
      today: DateTime.now(),
    );
  }

  /// Bugünün Hicri yılını önce vakit verisinden, orada yoksa Aladhan
  /// gToH'dan çözer; ikisi de olmazsa Miladi yıldan yaklaşık değer.
  Future<int> _resolveCurrentHijriYear() async {
    final data = ref.read(prayerControllerProvider).state.data;
    if (data != null && data.hijriMonth > 0) {
      return _hijriYearFromLabel(data.hijriDate) ??
          DateTime.now().year - 578;
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      final latitude = preferences.getDouble('saved_latitude') ?? 38.6244;
      final longitude = preferences.getDouble('saved_longitude') ?? 34.7239;
      final now = DateTime.now();
      final dateParam =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(
            'https://api.aladhan.com/v1/timings/$dateParam?latitude=$latitude&longitude=$longitude&method=13'));
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final hijri = decoded['data']?['date']?['hijri'];
        final year = int.tryParse('${hijri?['year']}');
        if (year != null && year > 1400) return year;
      } finally {
        client.close();
      }
    } catch (_) {
      // Ağ yoksa yaklaşık değer kullanılır.
    }
    return DateTime.now().year - 578;
  }

  int? _hijriYearFromLabel(String? hijriDate) {
    if (hijriDate == null) return null;
    final parts = hijriDate.split(' ');
    if (parts.length != 3) return null;
    return int.tryParse(parts[2]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? AppTheme.cream : AppTheme.primaryDeep;
    return Scaffold(
      appBar: AppBar(title: const Text('Dini Takvim')),
      body: FutureBuilder<List<UpcomingReligiousDay>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 44),
                  const SizedBox(height: 12),
                  const Text('Takvim yüklenemedi. İnternet bağlantısı gerekli.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() => _future = _load()),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            );
          }
          final days = snapshot.data!;
          if (days.isEmpty) {
            return const Center(child: Text('Yaklaşan dini gün bulunamadı.'));
          }
          final today = DateTime.now();
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final item = days[index];
              final daysLeft =
                  item.gregorianDate.difference(DateTime(today.year, today.month, today.day)).inDays;
              final isToday = daysLeft == 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isToday
                        ? const BorderSide(color: AppTheme.gold, width: 1.4)
                        : BorderSide.none,
                  ),
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${item.gregorianDate.day}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isToday ? AppTheme.gold : onSurface)),
                      Text(_monthName(item.gregorianDate.month),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  title: Text(item.info.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${formatPrayerDate(item.gregorianDate)} • Hicri ${item.info.day} ${_hijriMonthName(item.info.month)} ${item.hijriYear}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: isToday
                      ? const Chip(label: Text('Bugün'))
                      : Chip(label: Text('$daysLeft gün')),
                  onTap: () => _showDaySheet(context, item),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDaySheet(BuildContext context, UpcomingReligiousDay item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? AppTheme.cream : AppTheme.primaryDeep;
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppTheme.darkCard : Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(sheetContext).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mosque_outlined, color: AppTheme.gold, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.info.title,
                      style: TextStyle(
                          color: onSurface,
                          fontSize: 19,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(formatPrayerDate(item.gregorianDate),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            Text(item.info.message,
                style: TextStyle(
                    color: onSurface.withValues(alpha: .85),
                    fontSize: 14,
                    height: 1.5)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.gold : AppTheme.primary)
                    .withValues(alpha: .1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.gold.withValues(alpha: .4)),
              ),
              child: Text(
                item.info.dua,
                style: TextStyle(
                  color: isDark ? AppTheme.goldSoft : AppTheme.primary,
                  fontSize: 14.5,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  String _hijriMonthName(int month) {
    const months = [
      'Muharrem', 'Safer', 'Rebiülevvel', 'Rebiiülahır', 'Cemaziyelevvel',
      'Cemaziyelahir', 'Recep', 'Şaban', 'Ramazan', 'Şevval', 'Zilkade',
      'Zilhicce'
    ];
    return months[month - 1];
  }
}
