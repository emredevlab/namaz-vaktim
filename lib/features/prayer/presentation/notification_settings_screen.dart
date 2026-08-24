import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/notification_service.dart';
import '../../../shared/design/app_theme.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late bool _enabled;
  late bool _dailyReminder;
  late bool _notifyAtTime;
  late int _minutesBefore;

  @override
  void initState() {
    super.initState();
    final preferences =
        ref.read(prayerControllerProvider).notificationPreferences;
    _enabled = preferences.enabled;
    _dailyReminder = preferences.dailyReminder;
    _notifyAtTime = preferences.notifyAtTime;
    _minutesBefore = preferences.minutesBefore;
  }

  Future<void> _save() async {
    try {
      await ref.read(prayerControllerProvider).updateNotificationPreferences(
            NotificationPreferences(
              enabled: _enabled,
              minutesBefore: _minutesBefore,
              dailyReminder: _dailyReminder,
              notifyAtTime: _notifyAtTime,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildirim ayarları kaydedilemedi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim ayarları')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          _buildSectionLabel(context, 'Bildirimler'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  secondary:
                      _buildIconBox(Icons.notifications_outlined, isDark),
                  title: const Text('Namaz bildirimleri'),
                  subtitle: const Text('Vakit yaklaşınca bildirim gönder'),
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
                const Divider(height: 1, indent: 70, endIndent: 16),
                SwitchListTile.adaptive(
                  secondary: _buildIconBox(Icons.schedule_outlined, isDark),
                  title: const Text('Vakit girişinde bildir'),
                  subtitle: const Text('Vaktin kendisinde de bildirim gönder'),
                  value: _notifyAtTime,
                  onChanged: _enabled
                      ? (value) => setState(() => _notifyAtTime = value)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel(context, 'Hatırlatıcı'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  secondary:
                      _buildGoldIconBox(Icons.wb_twilight_outlined, isDark),
                  title: const Text('Günlük hatırlatma'),
                  subtitle:
                      const Text('Her gün sabah namazı için ek hatırlatma'),
                  value: _dailyReminder,
                  onChanged: (value) => setState(() => _dailyReminder = value),
                ),
                const Divider(height: 1, indent: 70, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: DropdownButtonFormField<int>(
                    initialValue: _minutesBefore,
                    decoration: const InputDecoration(
                      labelText: 'Bildirim zamanı',
                    ),
                    items: const [10, 15, 30]
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value dakika önce'),
                            ))
                        .toList(),
                    onChanged: _enabled
                        ? (value) {
                            if (value != null) {
                              setState(() => _minutesBefore = value);
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Kaydet'),
            ),
          ),
          const SizedBox(height: 28),
          _buildDiagnostics(context),
        ],
      ),
    );
  }

  /// Teşhis paneli: planlı bildirimleri listeler, test bildirimi gönderir
  /// ve planlama hatalarını görünür kılar.
  Widget _buildDiagnostics(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduler = ref.read(notificationSchedulerProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildIconBox(Icons.bug_report_outlined, isDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Bildirim teşhisi',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Bildirim gelmiyorsa önce test bildirimi gönderin; sonra '
              'telefonun pil optimizasyonundan uygulamaya "kısıtlama yok" '
              'verin (Xiaomi/Huawei gibi cihazlarda gerekli).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await scheduler.showTestNotificationNow();
                      if (!mounted) return;
                      messenger.showSnackBar(const SnackBar(
                          content:
                              Text('Anında bildirim komutu verildi — şimdi bak!')));
                      setState(() {});
                    },
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: const Text('Hemen göster'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await scheduler.scheduleTestNotification();
                      if (!mounted) return;
                      messenger.showSnackBar(const SnackBar(
                          content:
                              Text('Test bildirimi 5 saniye içinde gelecek.')));
                      setState(() {});
                    },
                    icon: const Icon(Icons.schedule_send_outlined, size: 18),
                    label: const Text('5 sn sonra'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<bool?>(
              future: scheduler.canScheduleExactAlarms(),
              builder: (context, snapshot) {
                final can = snapshot.data;
                if (can == null) return const SizedBox.shrink();
                return Row(
                  children: [
                    Icon(
                      can ? Icons.check_circle : Icons.warning_amber_rounded,
                      size: 16,
                      color: can
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        can
                            ? 'Tam zamanlı alarm izni: VAR'
                            : 'Tam zamanlı alarm izni: YOK — bildirimler gecikebilir. Ayarlar > Uygulama > Alarmlar ve hatırlatıcılar bölümünden izin verin.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<ScheduledNotificationInfo>>(
              future: scheduler.pendingNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final pending = snapshot.data ?? const [];
                if (pending.isEmpty) {
                  return Text(
                    'Planlı bildirim yok — bildirimler henüz planlanmamış '
                    'veya planlama hata verdi.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12.5),
                  );
                }
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text('Planlı bildirimler: ${pending.length}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Detayları görmek için dokun',
                      style: TextStyle(fontSize: 12)),
                  children: [
                    for (final item in pending)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Text('#${item.id}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontFeatures: [FontFeature.tabularFigures()])),
                        title: Text(item.title,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(item.body,
                            style: const TextStyle(fontSize: 11.5)),
                      ),
                  ],
                );
              },
            ),
            FutureBuilder<String?>(
              future: Future<String?>.value(scheduler.lastError),
              builder: (context, snapshot) {
                final error = snapshot.data;
                if (error == null || error.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Son hata: $error',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 11.5),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Altın vurgulu bölüm başlığı: ince gradient çubuk + etiket.
  Widget _buildSectionLabel(BuildContext context, String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 15,
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(letterSpacing: .2),
        ),
      ],
    );
  }

  /// Zümrüt ikon kutusu (bildirim anahtarları).
  Widget _buildIconBox(IconData icon, bool isDark) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: isDark ? .20 : .12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 21, color: isDark ? AppTheme.goldSoft : AppTheme.primary),
    );
  }

  /// Altın ikon kutusu (günlük hatırlatma).
  Widget _buildGoldIconBox(IconData icon, bool isDark) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: isDark ? .22 : .18),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 21, color: AppTheme.gold),
    );
  }
}
