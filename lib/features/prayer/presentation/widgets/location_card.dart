import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/app_config.dart';
import '../../../../shared/design/app_theme.dart';
import '../../../../shared/formatting.dart';
import '../../prayer_models.dart';

/// Ana ekranın gradient hero kartı: konum, tarih, sonraki vakit,
/// saniyesi ile akan geri sayım ve iki vakit arası ilerleme çubuğu.
class LocationCard extends StatefulWidget {
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
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _ensureCountdownTimer(PrayerTime? next) {
    if (next == null) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      return;
    }
    _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  String _formatCountdown(Duration remaining) {
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final next = data?.next;
    _ensureCountdownTimer(next);

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: .35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const Positioned.fill(child: _HeroPattern()),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(context, data),
                  const SizedBox(height: 20),
                  if (next != null)
                    _buildNextPrayer(context, data!, next)
                  else
                    _buildCompleted(context, data),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, DailyPrayerTimes? data) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.location_on_outlined,
              color: AppTheme.goldSoft, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data?.location.city ?? 'Nevşehir',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _dateLine(data),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .75),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed:
              widget.loadingLocation ? null : widget.onUseDeviceLocation,
          tooltip: 'Mevcut konumu kullan',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .14),
          ),
          color: Colors.white,
          icon: widget.loadingLocation
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.my_location, size: 20),
        ),
      ],
    );
  }

  /// '24 Ağustos 2026' ya da Hicri mevcutsa
  /// '24 Ağustos 2026 • 1 Rebiülevvel 1448'.
  String _dateLine(DailyPrayerTimes? data) {
    final gregorian = formatPrayerDate(DateTime.now());
    final hijri = data?.hijriDate;
    return hijri == null ? gregorian : '$gregorian • $hijri';
  }

  Widget _buildNextPrayer(BuildContext context, DailyPrayerTimes data, PrayerTime next) {
    final now = DateTime.now();
    final remaining = next.dateTime.difference(now);
    final previous = _previousPrayer(data, next);
    final progress = _progressBetween(previous, next, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold.withValues(alpha: .45)),
              ),
              child: const Text(
                'SONRAKİ NAMAZ',
                style: TextStyle(
                  color: AppTheme.goldSoft,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayerTypeLabel(next.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Saat ${formatPrayerTime(next.dateTime)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .78),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCountdown(remaining.isNegative ? Duration.zero : remaining),
                  style: const TextStyle(
                    color: AppTheme.goldSoft,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'kaldı',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .65),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: .18),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted(BuildContext context, DailyPrayerTimes? data) {
    final times = data?.times ?? const <PrayerTime>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bugünün vakitleri tamamlandı',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          times.isEmpty
              ? 'Vakitler yüklendiğinde burada görünecek.'
              : 'Yarının ilk vakti: ${times.isEmpty ? '--:--' : formatPrayerTime(times.first.dateTime.add(const Duration(days: 1)))} (yaklaşık)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .72),
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  PrayerTime? _previousPrayer(DailyPrayerTimes data, PrayerTime next) {
    final now = DateTime.now();
    PrayerTime? previous;
    for (final time in data.times) {
      if (time.dateTime.isBefore(now) &&
          (previous == null || time.dateTime.isAfter(previous.dateTime))) {
        previous = time;
      }
    }
    return previous;
  }

  double _progressBetween(PrayerTime? previous, PrayerTime next, DateTime now) {
    final start = previous?.dateTime ?? DateTime(next.dateTime.year, next.dateTime.month, next.dateTime.day);
    final total = next.dateTime.difference(start).inSeconds;
    if (total <= 0) return 0;
    final elapsed = now.difference(start).inSeconds;
    return elapsed / total;
  }
}

/// Hero arka planının süslemesi: yumuşak halkalar ve hilal yayı.
class _HeroPattern extends StatelessWidget {
  const _HeroPattern();

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _HeroPatternPainter(),
        size: Size.infinite,
      );
}

class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(
      Offset(size.width * .88, size.height * .12),
      size.height * .38,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * .88, size.height * .12),
      size.height * .30,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * .12, size.height * 1.02),
      size.height * .34,
      paint,
    );

    // Hilal: iki dairenin kesişimi, düşük opaklıkta dolgu
    final crescent = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(
        center: Offset(size.width * .82, size.height * .30),
        radius: size.height * .16,
      ))
      ..addOval(Rect.fromCircle(
        center: Offset(size.width * .86, size.height * .26),
        radius: size.height * .14,
      ));
    canvas.drawPath(
      crescent,
      Paint()..color = Colors.white.withValues(alpha: .07),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
