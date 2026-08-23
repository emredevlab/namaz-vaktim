import 'package:flutter/material.dart';

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
          padding: const EdgeInsets.all(16),
          itemCount: _cities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final location = _cities[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(location.city),
                subtitle: Text(
                    '${location.latitude!.toStringAsFixed(3)}, ${location.longitude!.toStringAsFixed(3)}'),
                onTap: () async {
                  await onSelected(location);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            );
          },
        ),
      );
}
