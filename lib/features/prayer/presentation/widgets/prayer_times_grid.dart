import 'package:flutter/material.dart';

import '../../../../shared/formatting.dart';
import '../../prayer_models.dart';

class PrayerTimesGrid extends StatelessWidget {
  const PrayerTimesGrid({super.key, required this.data});
  final DailyPrayerTimes? data;

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data?.times.length ?? 0,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5),
        itemBuilder: (_, index) {
          final item = data!.times[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prayerTypeLabel(item.type)),
                    const SizedBox(height: 6),
                    Text(formatPrayerTime(item.dateTime),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ]),
            ),
          );
        },
      );
}
