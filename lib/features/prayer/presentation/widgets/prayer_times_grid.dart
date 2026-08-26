import 'package:flutter/material.dart';

import '../../../../shared/design/app_theme.dart';
import '../../../../shared/formatting.dart';
import '../../prayer_models.dart';

/// Bugünün vakitlerini durum etiketleriyle listeleyen kart listesi:
/// geçmiş vakitler soluk, sıradaki vaktin altın çerçevesi ve rozeti var.
class PrayerTimesGrid extends StatelessWidget {
  const PrayerTimesGrid({super.key, required this.data});

  final DailyPrayerTimes? data;

  @override
  Widget build(BuildContext context) {
    // Güneş hariç BEŞ vakit gösterilir; güneş namaz vakti değildir.
    final times = data?.prayerTimes ?? const <PrayerTime>[];
    final next = data?.next;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        for (var index = 0; index < times.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _buildTile(context, times[index], next, isDark),
        ],
      ],
    );
  }

  Widget _buildTile(
    BuildContext context,
    PrayerTime time,
    PrayerTime? next,
    bool isDark,
  ) {
    final isNext = next != null && next.type == time.type;
    final isPassed = !isNext && time.dateTime.isBefore(DateTime.now());
    final onCard = isDark ? AppTheme.cream : AppTheme.primaryDeep;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: isNext ? AppTheme.nextTileGradient : null,
        color: isNext ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNext
              ? AppTheme.gold.withValues(alpha: .75)
              : (isDark ? Colors.white.withValues(alpha: .06) : AppTheme.primary.withValues(alpha: .08)),
          width: isNext ? 1.4 : 1,
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: .28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          _buildIcon(time, isNext, isPassed, isDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayerTypeLabel(time.type),
                  style: TextStyle(
                    color: isPassed
                        ? onCard.withValues(alpha: .45)
                        : (isNext ? Colors.white : onCard),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Sıradaki vakit',
                    style: TextStyle(
                      color: AppTheme.goldSoft.withValues(alpha: .9),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isPassed) ...[
            Icon(Icons.check_circle_outline,
                size: 18, color: onCard.withValues(alpha: .35)),
            const SizedBox(width: 8),
          ],
          Text(
            formatPrayerTime(time.dateTime),
            style: TextStyle(
              color: isNext
                  ? AppTheme.goldSoft
                  : onCard.withValues(alpha: isPassed ? .45 : .85),
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(PrayerTime time, bool isNext, bool isPassed, bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: isNext ? AppTheme.goldGradient : null,
        color: isNext
            ? null
            : (isDark
                ? Colors.white.withValues(alpha: .07)
                : AppTheme.primary.withValues(alpha: .09)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        prayerIcon(time.type),
        size: 22,
        color: isNext
            ? AppTheme.primaryDeep
            : (isPassed
                ? (isDark ? Colors.white38 : AppTheme.primary.withValues(alpha: .4))
                : (isDark ? AppTheme.goldSoft : AppTheme.primary)),
      ),
    );
  }
}
