import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/design/app_theme.dart';

class QiblaDial extends StatelessWidget {
  const QiblaDial({
    super.key,
    required this.heading,
    required this.qiblaBearing,
  });

  final double? heading;
  final double qiblaBearing;

  static bool isAligned({
    required double heading,
    required double qiblaBearing,
    double toleranceDegrees = 4,
  }) {
    var diff = (qiblaBearing - heading) % 360;
    if (diff < 0) diff += 360;
    return diff <= toleranceDegrees || diff >= 360 - toleranceDegrees;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final aligned = heading != null &&
            isAligned(heading: heading!, qiblaBearing: qiblaBearing);
        return Transform.rotate(
          angle: heading == null ? 0 : -heading! * math.pi / 180,
          child: CustomPaint(
            size: Size.square(side),
            painter: _QiblaDialPainter(
              heading: heading,
              qiblaBearing: qiblaBearing,
              aligned: aligned,
            ),
          ),
        );
      },
    );
  }
}

class _QiblaDialPainter extends CustomPainter {
  _QiblaDialPainter({
    required this.heading,
    required this.qiblaBearing,
    required this.aligned,
  });

  final double? heading;
  final double qiblaBearing;
  final bool aligned;

  @override
  bool shouldRepaint(covariant _QiblaDialPainter oldDelegate) =>
      oldDelegate.heading != heading ||
      oldDelegate.qiblaBearing != qiblaBearing ||
      oldDelegate.aligned != aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    if (radius <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);

    if (aligned) {
      canvas.drawCircle(
        center,
        radius * 1.02,
        Paint()
          ..color = Colors.greenAccent.withValues(alpha: .22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    _paintFace(canvas, center, radius);
    _paintScale(canvas, center, radius);
    _paintNorthMarker(canvas, center, radius);
    _paintNeedle(canvas, center, radius);
    _paintHub(canvas, center, radius);
  }

  void _paintFace(Canvas canvas, Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF20443A), AppTheme.darkCard, Color(0xFF081310)],
          stops: [0.0, 0.58, 1.0],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius - 1.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = (aligned ? Colors.greenAccent : AppTheme.gold)
            .withValues(alpha: .6),
    );
    canvas.drawCircle(
      center,
      radius * .60,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppTheme.gold.withValues(alpha: .16),
    );
    canvas.drawCircle(
      center,
      radius * .44,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = Colors.white.withValues(alpha: .05),
    );
  }

  void _paintScale(Canvas canvas, Offset center, double radius) {
    final dim = heading == null ? .65 : 1.0;
    final outer = radius * .96;
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    for (var deg = 0; deg < 360; deg += 5) {
      final cardinal = deg % 90 == 0;
      final major = deg % 45 == 0;
      final mid = !major && deg % 15 == 0;
      final length = cardinal
          ? radius * .08
          : major
              ? radius * .065
              : mid
                  ? radius * .05
                  : radius * .035;
      tickPaint.strokeWidth = cardinal
          ? 3.0
          : major
              ? 2.2
              : mid
                  ? 1.6
                  : 1.0;
      tickPaint.color = cardinal
          ? AppTheme.gold.withValues(alpha: dim)
          : major
              ? AppTheme.gold.withValues(alpha: .75 * dim)
              : Colors.white.withValues(alpha: (mid ? .5 : .26) * dim);
      canvas.drawLine(
        _polar(center, deg.toDouble(), outer),
        _polar(center, deg.toDouble(), outer - length),
        tickPaint,
      );
    }

    const letters = <int, String>{0: 'K', 90: 'D', 180: 'G', 270: 'B'};
    letters.forEach((deg, letter) {
      final isNorth = deg == 0;
      _drawLabel(
        canvas,
        letter,
        _polar(center, deg.toDouble(), radius * .78),
        radius * .115,
        color: isNorth
            ? AppTheme.gold
            : Colors.white.withValues(alpha: .82 * dim),
        weight: FontWeight.w800,
      );
      _drawLabel(
        canvas,
        '$deg',
        _polar(center, deg.toDouble(), radius * .69),
        radius * .058,
        color: Colors.white.withValues(alpha: .42 * dim),
        weight: FontWeight.w600,
      );
    });
  }

  void _paintNorthMarker(Canvas canvas, Offset center, double radius) {
    final apex = _polar(center, 0, radius * .955);
    final right = _polar(center, -5.2, radius * .885);
    final left = _polar(center, 5.2, radius * .885);
    final path = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = AppTheme.gold);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppTheme.primaryDeep,
    );
  }

  void _paintNeedle(Canvas canvas, Offset center, double radius) {
    final bearing = qiblaBearing * math.pi / 180;
    final dir = Offset(math.sin(bearing), -math.cos(bearing));
    final perp = Offset(dir.dy, -dir.dx);

    final tip = center + dir * (radius * .56);
    final waist = center + dir * (radius * .17);
    final waistRight = waist + perp * (radius * .032);
    final waistLeft = waist - perp * (radius * .032);
    final shoulderRight = center + perp * (radius * .085);
    final shoulderLeft = center - perp * (radius * .085);
    final tail = center - dir * (radius * .16);

    final body = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(waistRight.dx, waistRight.dy)
      ..lineTo(shoulderRight.dx, shoulderRight.dy)
      ..lineTo(tail.dx, tail.dy)
      ..lineTo(shoulderLeft.dx, shoulderLeft.dy)
      ..lineTo(waistLeft.dx, waistLeft.dy)
      ..close();

    final gradientColors = aligned
        ? const [Color(0xFF00897B), Colors.greenAccent, Color(0xFFE0FFF4)]
        : const [Color(0xFF8A6430), AppTheme.gold, AppTheme.goldSoft];
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: gradientColors,
        ).createShader(body.getBounds()),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: .35),
    );

    final counterTip = center - dir * (radius * .16);
    final counterBase = center - dir * (radius * .27);
    final counterweight = Path()
      ..moveTo(counterTip.dx, counterTip.dy)
      ..lineTo((counterBase + perp * (radius * .035)).dx,
          (counterBase + perp * (radius * .035)).dy)
      ..lineTo((counterBase - perp * (radius * .035)).dx,
          (counterBase - perp * (radius * .035)).dy)
      ..close();
    canvas.drawPath(
      counterweight,
      Paint()..color = Colors.white.withValues(alpha: .28),
    );

    final medallionCenter = center + dir * (radius * .41);
    final medallionRadius = radius * .095;
    if (aligned) {
      canvas.drawCircle(
        medallionCenter,
        medallionRadius * 1.5,
        Paint()
          ..color = Colors.greenAccent.withValues(alpha: .3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    canvas.drawCircle(
      medallionCenter,
      medallionRadius,
      Paint()..color = AppTheme.primaryDeep,
    );
    canvas.drawCircle(
      medallionCenter,
      medallionRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = (aligned ? Colors.greenAccent : AppTheme.gold)
            .withValues(alpha: .9),
    );

    final mosque = Icons.mosque;
    final kaaba = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(mosque.codePoint),
        style: TextStyle(
          fontFamily: mosque.fontFamily,
          package: mosque.fontPackage,
          fontSize: medallionRadius * 1.25,
          color: AppTheme.goldSoft,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    kaaba.paint(
      canvas,
      medallionCenter - Offset(kaaba.width / 2, kaaba.height / 2),
    );
  }

  void _paintHub(Canvas canvas, Offset center, double radius) {
    final hubColor = aligned ? Colors.greenAccent : AppTheme.gold;
    canvas.drawCircle(
      center,
      radius * .062,
      Paint()..color = const Color(0xFF0B1F19),
    );
    canvas.drawCircle(
      center,
      radius * .062,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = hubColor.withValues(alpha: .85),
    );
    canvas.drawCircle(center, radius * .024, Paint()..color = hubColor);

    final label = TextPainter(
      text: TextSpan(
        text: 'KIBLE',
        style: TextStyle(
          fontSize: radius * .055,
          fontWeight: FontWeight.w800,
          letterSpacing: radius * .035,
          color: AppTheme.goldSoft.withValues(alpha: .9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelCenter = Offset(center.dx, center.dy + radius * .155);
    final pillRect = Rect.fromCenter(
      center: labelCenter,
      width: label.width + radius * .09,
      height: label.height + radius * .045,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, Radius.circular(pillRect.height / 2)),
      Paint()..color = Colors.black.withValues(alpha: .4),
    );
    label.paint(
      canvas,
      labelCenter - Offset(label.width / 2, label.height / 2),
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position,
    double fontSize, {
    required Color color,
    required FontWeight weight,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      position - Offset(painter.width / 2, painter.height / 2),
    );
  }

  Offset _polar(Offset center, double degrees, double distance) {
    final rad = degrees * math.pi / 180;
    return center +
        Offset(math.sin(rad) * distance, -math.cos(rad) * distance);
  }
}
