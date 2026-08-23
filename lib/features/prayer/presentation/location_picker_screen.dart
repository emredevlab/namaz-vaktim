import 'package:flutter/material.dart';

import '../../../shared/design/app_theme.dart';
import '../prayer_models.dart';

class LocationPickerScreen extends StatelessWidget {
  const LocationPickerScreen({required this.onSelected, super.key});
  final Future<void> Function(UserLocation location) onSelected;

  static const _cities = <UserLocation>[
    UserLocation(city: 'Nevşehir', latitude: 38.6244, longitude: 34.7239),
    UserLocation(city: 'İstanbul', latitude: 41.0082, longitude: 28.9784),
    UserLocation(city: 'Ankara', latitude: 39.9334, longitude: 32.8597),
    UserLocation(city: 'İzmir', latitude: 38.4237, longitude: 27.1428),
    UserLocation(city: 'Bursa', latitude: 40.1950, longitude: 29.0600),
    UserLocation(city: 'Antalya', latitude: 36.8969, longitude: 30.7133),
    UserLocation(city: 'Konya', latitude: 37.8746, longitude: 32.4932),
    UserLocation(city: 'Kayseri', latitude: 38.7225, longitude: 35.4875),
    UserLocation(city: 'Gaziantep', latitude: 37.0662, longitude: 37.3833),
    UserLocation(city: 'Diyarbakır', latitude: 37.9144, longitude: 40.2306),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Şehir seç')),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: _cities.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) return const _CityInfoBanner();
            final location = _cities[index - 1];
            return _CityTile(
              location: location,
              onTap: () async {
                await onSelected(location);
                if (context.mounted) Navigator.pop(context);
              },
            );
          },
        ),
      );
}

class _CityInfoBanner extends StatelessWidget {
  const _CityInfoBanner();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: .35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_city,
                  color: AppTheme.goldSoft, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Vakitler seçtiğin şehre göre gösterilir',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .95),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

class _CityTile extends StatelessWidget {
  const _CityTile({required this.location, required this.onTap});

  final UserLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              location.city[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          title: Text(
            location.city,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${location.latitude!.toStringAsFixed(3)}, ${location.longitude!.toStringAsFixed(3)}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: onTap,
        ),
      );
}
