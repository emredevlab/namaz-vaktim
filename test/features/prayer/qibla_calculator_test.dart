import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_vaktim/features/prayer/qibla_calculator.dart';

void main() {
  group('qiblaBearing', () {
    // Referans değerler iki bağımsız yöntemle doğrulandı:
    // 1) atan2(sin Δλ·cos φ2, cos φ1·tan φ2 − sin φ1·cos Δλ)
    // 2) ECEF vektörleri + kuzey/doğu teğet birimleri projeksiyonu
    test('returns verified great-circle bearing to Kaaba', () {
      expect(
        qiblaBearing(latitude: 41.0082, longitude: 28.9784),
        closeTo(151.6206, 0.001),
      );
      expect(
        qiblaBearing(latitude: 38.6244, longitude: 34.7239),
        closeTo(164.2442, 0.001),
      );
      expect(
        qiblaBearing(latitude: 40.7128, longitude: -74.0060),
        closeTo(58.4817, 0.001),
      );
    });

    test('same meridian south of Kaaba points due north', () {
      expect(
        qiblaBearing(latitude: 11.422487, longitude: 39.826206),
        closeTo(0, 0.0001),
      );
    });

    test('same meridian north of Kaaba points due south', () {
      expect(
        qiblaBearing(latitude: 31.422487, longitude: 39.826206),
        closeTo(180, 0.0001),
      );
    });

    test('result is always normalized to [0, 360)', () {
      const samples = [
        (-89.9, -179.9),
        (89.9, 179.9),
        (0.0, 0.0),
        (-45.5, 120.25),
      ];
      for (final (latitude, longitude) in samples) {
        final bearing = qiblaBearing(latitude: latitude, longitude: longitude);
        expect(bearing, greaterThanOrEqualTo(0));
        expect(bearing, lessThan(360));
      }
    });
  });

  group('fusedCompassHeading', () {
    const g = 9.81;
    const horizontalField = 25.0;
    const dip = 40.0;

    double headingForFlatOrientation(double yawDegrees) {
      final yaw = yawDegrees * math.pi / 180;
      // Cihaz düz; üst kenar yaw derece döndürülmüş.
      // Manyetik alan cihaz eksenlerine göre: x = h·sin(yaw)? değil;
      // kuzey bileşeni cihaz +y üzerinde yaw ile döner.
      final mx = -horizontalField * math.sin(yaw);
      final my = horizontalField * math.cos(yaw);
      return fusedCompassHeading(
            gravityX: 0,
            gravityY: 0,
            gravityZ: g,
            magneticX: mx,
            magneticY: my,
            magneticZ: -dip,
          ) ??
          -1;
    }

    test('flat device facing each cardinal direction', () {
      expect(headingForFlatOrientation(0), closeTo(0, 0.001));
      expect(headingForFlatOrientation(90), closeTo(90, 0.001));
      expect(headingForFlatOrientation(180), closeTo(180, 0.001));
      expect(headingForFlatOrientation(270), closeTo(270, 0.001));
    });

    test('tilted device keeps correct heading', () {
      // Telefon arkaya 45° yatık; üst kenar hâlâ kuzeye bakıyor.
      // Cihaz eksenlerinde yerçekimi ve manyetik alan örnekleri.
      const tilt = math.pi / 4;
      final gravityY = g * math.sin(tilt);
      final gravityZ = g * math.cos(tilt);
      final magneticY =
          horizontalField * math.cos(tilt) - dip * math.sin(tilt);
      final magneticZ =
          -horizontalField * math.sin(tilt) - dip * math.cos(tilt);

      final heading = fusedCompassHeading(
        gravityX: 0,
        gravityY: gravityY,
        gravityZ: gravityZ,
        magneticX: 0,
        magneticY: magneticY,
        magneticZ: magneticZ,
      );

      expect(heading, isNotNull);
      expect(heading!, closeTo(0, 0.01));
    });

    test('degenerate magnetic field returns null', () {
      final heading = fusedCompassHeading(
        gravityX: 0,
        gravityY: 0,
        gravityZ: g,
        magneticX: 0,
        magneticY: 0,
        magneticZ: -50,
      );
      expect(heading, isNull);
    });

    test('degenerate gravity returns null', () {
      final heading = fusedCompassHeading(
        gravityX: 0,
        gravityY: 0,
        gravityZ: 0,
        magneticX: 0,
        magneticY: 25,
        magneticZ: -40,
      );
      expect(heading, isNull);
    });
  });
}
