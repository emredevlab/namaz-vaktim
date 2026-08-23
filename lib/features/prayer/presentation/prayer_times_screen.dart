import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../config/app_config.dart';
import '../../../shared/formatting.dart';
import 'widgets/location_card.dart';
import 'widgets/prayer_error.dart';

class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prayerControllerProvider).state;
    final data = state.data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Vakitleri'),
        actions: [
          IconButton(
            tooltip: 'Vakitleri yenile',
            onPressed: state.isLoading
                ? null
                : () => ref.read(prayerControllerProvider).load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(prayerControllerProvider).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            LocationCard(
              config: config,
              data: data,
              loadingLocation: false,
              onUseDeviceLocation: () {},
            ),
            const SizedBox(height: 16),
            if (data?.isFallback ?? false)
              const Card(
                color: Color(0xFFFFF4D6),
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Çevrimdışı örnek vakitler'),
                  subtitle: Text(
                      'Sunucuya ulaşılamadı. İnternet bağlantısı kurulduğunda yenileyin.'),
                ),
              ),
            if (data != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(formatPrayerDate(data.date)),
                  subtitle: Text('${data.location.city} için günlük vakitler'),
                ),
              ),
            const SizedBox(height: 16),
            if (state.isLoading && data == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && data == null)
              PrayerError(
                message: state.error!,
                onRetry: () => ref.read(prayerControllerProvider).load(),
              )
            else
              ...?data?.times.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          config.primaryColor.withValues(alpha: .12),
                      foregroundColor: config.primaryColor,
                      child: Icon(prayerIcon(item.type)),
                    ),
                    title: Text(prayerTypeLabel(item.type)),
                    trailing: Text(
                      formatPrayerTime(item.dateTime),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: config.primaryColor,
                              ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Vakitler bulunduğunuz şehir ve yerel saat dilimine göre gösterilir. İnternet bağlantısı olmadığında son başarılı sonuç ekranda kalır.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
