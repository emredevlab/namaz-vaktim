import 'package:flutter/material.dart';

import '../../../../config/app_config.dart';
import '../../../../shared/formatting.dart';
import '../../prayer_models.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.config,
    required this.data,
    required this.loadingLocation,
    required this.onUseDeviceLocation,
  });
  final AppConfig config;
  final DailyPrayerTimes? data;
  final bool loadingLocation;
  final VoidCallback onUseDeviceLocation;

  @override
  Widget build(BuildContext context) {
    final next = data?.next;
    return Card(
      color: config.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(
                child: Text(data?.location.city ?? 'Nevşehir',
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
              IconButton(
                onPressed: loadingLocation ? null : onUseDeviceLocation,
                color: Colors.white,
                tooltip: 'Mevcut konumu kullan',
                icon: loadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
              next == null
                  ? 'Bugünün vakitleri'
                  : 'Sonraki Namaz: ${prayerTypeLabel(next.type)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(next == null ? '--:--' : formatPrayerTime(next.dateTime),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
