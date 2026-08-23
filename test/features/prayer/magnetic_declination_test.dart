import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_vaktim/features/prayer/magnetic_declination.dart';

/// Referans: NOAA WMM2025_TestValues.txt (WMM2025COF.zip ile dağıtılır).
/// Dosyadaki değerler 2 ondalıklı yuvarlandığı için tolerans ±0.005°.
void main() {
  group('worldMagneticField vs official NOAA WMM2025 test values', () {
    final cases = <(double year, double altKm, double lat, double lon,
        double declination)>[
      (2025.0, 28, 89, -121, -99.77),
      (2025.0, 48, 80, -96, -29.91),
      (2025.0, 54, 82, 87, 54.89),
      (2025.0, 65, 43, 93, 0.50),
      (2025.0, 51, -33, 109, -5.49),
      (2025.0, 39, -59, -8, -15.75),
      (2025.0, 3, -50, -103, 27.96),
      (2025.5, 6, -36, -137, 20.28),
      (2025.5, 63, 26, 81, 0.51),
      (2025.5, 69, 38, -144, 12.93),
      (2025.5, 44, 33, -118, 11.10),
      (2026.0, 74, -57, 3, -22.51),
    ];

    for (final (year, altKm, lat, lon, expectedD) in cases) {
      test('declination at lat=$lat lon=$lon alt=$altKm year=$year',
          () {
        final result = worldMagneticField(
          latitudeDegrees: lat,
          longitudeDegrees: lon,
          altitudeKm: altKm,
          decimalYear: year,
        );
        expect(
          result.declinationDegrees,
          closeTo(expectedD, 0.005),
          reason:
              'lat=$lat lon=$lon beklenen=$expectedD gelen=${result.declinationDegrees}',
        );
      });
    }
  });

  group('field intensity sanity checks against NOAA values', () {
    test('total intensity matches at mid-latitude case', () {
      // 2025.0, h=65km, lat=43, lon=93 -> F=55626.62 nT
      final result = worldMagneticField(
        latitudeDegrees: 43,
        longitudeDegrees: 93,
        altitudeKm: 65,
        decimalYear: 2025.0,
      );
      expect(result.totalIntensityNT, closeTo(55626.62, 0.01));
      expect(result.horizontalIntensityNT, closeTo(24300.76, 0.01));
      expect(result.inclinationDegrees, closeTo(64.10, 0.005));
    });
  });

  group('magneticDeclinationDegrees', () {
    test('Turkey declination is east-positive and small', () {
      // Türkiye'de sapma ~ +3..+6 derece doğu (2026 itibarıyla).
      final d = magneticDeclinationDegrees(
        latitudeDegrees: 41.0082,
        longitudeDegrees: 28.9784,
        date: DateTime(2026, 7, 1),
      );
      expect(d, greaterThan(2));
      expect(d, lessThan(8));
    });

    test('decimalYearFor computes fractional years correctly', () {
      expect(decimalYearFor(DateTime(2025, 1, 1)), closeTo(2025.0, 1e-9));
      expect(decimalYearFor(DateTime(2026, 1, 1)), closeTo(2026.0, 1e-9));
      // Yıl ortası ~2026.496 (365 günlük yıl)
      final mid = decimalYearFor(DateTime(2026, 7, 2, 12));
      expect(mid, closeTo(2026.5, 0.01));
    });

    test('declination drifts slowly over the epoch', () {
      final start = magneticDeclinationDegrees(
        latitudeDegrees: 38.6244,
        longitudeDegrees: 34.7239,
        date: DateTime(2025, 1, 1),
      );
      final end = magneticDeclinationDegrees(
        latitudeDegrees: 38.6244,
        longitudeDegrees: 34.7239,
        date: DateTime(2029, 12, 31),
      );
      // Beş yılda birkaç on dakikalık kayışmakalı; sıçrama olmamalı.
      expect((end - start).abs(), lessThan(1.0));
      expect(end, isNot(equals(start)));
    });
  });
}
