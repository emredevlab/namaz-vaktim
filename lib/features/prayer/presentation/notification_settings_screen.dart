import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/notification_service.dart';

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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bildirim ayarları')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Namaz bildirimleri'),
              subtitle: const Text('Vakit yaklaşınca bildirim gönder'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vakit girişinde bildir'),
              subtitle: const Text('Vaktin kendisinde de bildirim gönder'),
              value: _notifyAtTime,
              onChanged: _enabled
                  ? (value) => setState(() => _notifyAtTime = value)
                  : null,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Günlük hatırlatma'),
              subtitle: const Text('Her gün sabah namazı için ek hatırlatma'),
              value: _dailyReminder,
              onChanged: (value) => setState(() => _dailyReminder = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _minutesBefore,
              decoration: const InputDecoration(
                labelText: 'Bildirim zamanı',
                border: OutlineInputBorder(),
              ),
              items: const [10, 15, 30]
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value dakika önce'),
                      ))
                  .toList(),
              onChanged: _enabled
                  ? (value) {
                      if (value != null) setState(() => _minutesBefore = value);
                    }
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Kaydet'),
            ),
          ],
        ),
      );
}
