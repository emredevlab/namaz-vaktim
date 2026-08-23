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
        padding: const EdgeInsets.all(20),
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
        ],
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
