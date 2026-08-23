import 'dart:math' as math;

/// WMM2025 Gauss katsayıları (epoch 2025.0, geçerlilik 2025–2030).
/// Kaynak: NOAA NCEI WMM2025COF.zip — WMM.COF (doi:10.25921/aqfd-sd83)
/// Her satır: [n, m, g(nT), h(nT), gDot(nT/yıl), hDot(nT/yıl)]
const List<List<double>> _kWmm2025Coefficients = [
  [1, 0, -29351.8, 0.0, 12.0, 0.0],
  [1, 1, -1410.8, 4545.4, 9.7, -21.5],
  [2, 0, -2556.6, 0.0, -11.6, 0.0],
  [2, 1, 2951.1, -3133.6, -5.2, -27.7],
  [2, 2, 1649.3, -815.1, -8.0, -12.1],
  [3, 0, 1361.0, 0.0, -1.3, 0.0],
  [3, 1, -2404.1, -56.6, -4.2, 4.0],
  [3, 2, 1243.8, 237.5, 0.4, -0.3],
  [3, 3, 453.6, -549.5, -15.6, -4.1],
  [4, 0, 895.0, 0.0, -1.6, 0.0],
  [4, 1, 799.5, 278.6, -2.4, -1.1],
  [4, 2, 55.7, -133.9, -6.0, 4.1],
  [4, 3, -281.1, 212.0, 5.6, 1.6],
  [4, 4, 12.1, -375.6, -7.0, -4.4],
  [5, 0, -233.2, 0.0, 0.6, 0.0],
  [5, 1, 368.9, 45.4, 1.4, -0.5],
  [5, 2, 187.2, 220.2, 0.0, 2.2],
  [5, 3, -138.7, -122.9, 0.6, 0.4],
  [5, 4, -142.0, 43.0, 2.2, 1.7],
  [5, 5, 20.9, 106.1, 0.9, 1.9],
  [6, 0, 64.4, 0.0, -0.2, 0.0],
  [6, 1, 63.8, -18.4, -0.4, 0.3],
  [6, 2, 76.9, 16.8, 0.9, -1.6],
  [6, 3, -115.7, 48.8, 1.2, -0.4],
  [6, 4, -40.9, -59.8, -0.9, 0.9],
  [6, 5, 14.9, 10.9, 0.3, 0.7],
  [6, 6, -60.7, 72.7, 0.9, 0.9],
  [7, 0, 79.5, 0.0, -0.0, 0.0],
  [7, 1, -77.0, -48.9, -0.1, 0.6],
  [7, 2, -8.8, -14.4, -0.1, 0.5],
  [7, 3, 59.3, -1.0, 0.5, -0.8],
  [7, 4, 15.8, 23.4, -0.1, 0.0],
  [7, 5, 2.5, -7.4, -0.8, -1.0],
  [7, 6, -11.1, -25.1, -0.8, 0.6],
  [7, 7, 14.2, -2.3, 0.8, -0.2],
  [8, 0, 23.2, 0.0, -0.1, 0.0],
  [8, 1, 10.8, 7.1, 0.2, -0.2],
  [8, 2, -17.5, -12.6, 0.0, 0.5],
  [8, 3, 2.0, 11.4, 0.5, -0.4],
  [8, 4, -21.7, -9.7, -0.1, 0.4],
  [8, 5, 16.9, 12.7, 0.3, -0.5],
  [8, 6, 15.0, 0.7, 0.2, -0.6],
  [8, 7, -16.8, -5.2, -0.0, 0.3],
  [8, 8, 0.9, 3.9, 0.2, 0.2],
  [9, 0, 4.6, 0.0, -0.0, 0.0],
  [9, 1, 7.8, -24.8, -0.1, -0.3],
  [9, 2, 3.0, 12.2, 0.1, 0.3],
  [9, 3, -0.2, 8.3, 0.3, -0.3],
  [9, 4, -2.5, -3.3, -0.3, 0.3],
  [9, 5, -13.1, -5.2, 0.0, 0.2],
  [9, 6, 2.4, 7.2, 0.3, -0.1],
  [9, 7, 8.6, -0.6, -0.1, -0.2],
  [9, 8, -8.7, 0.8, 0.1, 0.4],
  [9, 9, -12.9, 10.0, -0.1, 0.1],
  [10, 0, -1.3, 0.0, 0.1, 0.0],
  [10, 1, -6.4, 3.3, 0.0, 0.0],
  [10, 2, 0.2, 0.0, 0.1, -0.0],
  [10, 3, 2.0, 2.4, 0.1, -0.2],
  [10, 4, -1.0, 5.3, -0.0, 0.1],
  [10, 5, -0.6, -9.1, -0.3, -0.1],
  [10, 6, -0.9, 0.4, 0.0, 0.1],
  [10, 7, 1.5, -4.2, -0.1, 0.0],
  [10, 8, 0.9, -3.8, -0.1, -0.1],
  [10, 9, -2.7, 0.9, -0.0, 0.2],
  [10, 10, -3.9, -9.1, -0.0, -0.0],
  [11, 0, 2.9, 0.0, 0.0, 0.0],
  [11, 1, -1.5, 0.0, -0.0, -0.0],
  [11, 2, -2.5, 2.9, 0.0, 0.1],
  [11, 3, 2.4, -0.6, 0.0, -0.0],
  [11, 4, -0.6, 0.2, 0.0, 0.1],
  [11, 5, -0.1, 0.5, -0.1, -0.0],
  [11, 6, -0.6, -0.3, 0.0, -0.0],
  [11, 7, -0.1, -1.2, -0.0, 0.1],
  [11, 8, 1.1, -1.7, -0.1, -0.0],
  [11, 9, -1.0, -2.9, -0.1, 0.0],
  [11, 10, -0.2, -1.8, -0.1, 0.0],
  [11, 11, 2.6, -2.3, -0.1, 0.0],
  [12, 0, -2.0, 0.0, 0.0, 0.0],
  [12, 1, -0.2, -1.3, 0.0, -0.0],
  [12, 2, 0.3, 0.7, -0.0, 0.0],
  [12, 3, 1.2, 1.0, -0.0, -0.1],
  [12, 4, -1.3, -1.4, -0.0, 0.1],
  [12, 5, 0.6, -0.0, -0.0, -0.0],
  [12, 6, 0.6, 0.6, 0.1, -0.0],
  [12, 7, 0.5, -0.1, -0.0, -0.0],
  [12, 8, -0.1, 0.8, 0.0, 0.0],
  [12, 9, -0.4, 0.1, 0.0, -0.0],
  [12, 10, -0.2, -1.0, -0.1, -0.0],
  [12, 11, -1.3, 0.1, -0.0, 0.0],
  [12, 12, -0.7, 0.2, -0.1, -0.1],
];

/// WMM'nin geçerli epoch aralığı.
const double kWmmEpochStart = 2025.0;
const double kWmmEpochEnd = 2030.0;

final class MagneticFieldResult {
  const MagneticFieldResult({
    required this.declinationDegrees,
    required this.inclinationDegrees,
    required this.horizontalIntensityNT,
    required this.totalIntensityNT,
  });

  /// Sapma (declination): gerçek kuzey ile manyetik kuzey arasındaki açı,
  /// derece cinsinden; doğu pozitif.
  final double declinationDegrees;

  /// Eğim (inclination): yatay düzleme göre alan açısı, derece.
  final double inclinationDegrees;

  final double horizontalIntensityNT;
  final double totalIntensityNT;
}

/// [date] için ondalık yıl hesabı (yıl başından itibaren kesirli).
double decimalYearFor(DateTime date) {
  final startOfYear = DateTime(date.year);
  final endOfYear = DateTime(date.year + 1);
  final yearFraction = date.difference(startOfYear).inMicroseconds /
      endOfYear.difference(startOfYear).inMicroseconds;
  return date.year + yearFraction;
}

/// Jeodezik konum ve tarihte manyetik alan öğelerini hesaplar.
///
/// Algoritma, NOAA'nın resmi geomag70 C/VB kaynak kodundaki
/// `SphericalHarmonicVAL3` + `DIHF` rutinlerinin birebir taşımasıdır.
///
/// [altitudeKm]: WGS84 elipsoid yüksekliği (GPS yüksekliği uygundur).
/// Model 2025.0–2030.0 arasında doğrudur; aralık dışında sonuç lineer
/// ekstrapole edilir ve güvenilirliği azalır.
MagneticFieldResult worldMagneticField({
  required double latitudeDegrees,
  required double longitudeDegrees,
  required double altitudeKm,
  required double decimalYear,
}) {
  const earthRadiusKm = 6371.2;
  const aSquared = 40680631.59; // WGS84 a^2
  const bSquared = 40408299.98; // WGS84 b^2
  const epoch = kWmmEpochStart;

  // Model katsayılarını epoch'a göre güncelle.
  // Düzen kaynak kodla aynıdır: m=0 satırı yalnızca g içerir (tek slot),
  // m>0 için g,h çifti arka arkaya gelir.
  final gh = <double>[
    for (final row in _kWmm2025Coefficients) ...[
      row[2] + row[4] * (decimalYear - epoch),
      if (row[1] > 0) row[3] + row[5] * (decimalYear - epoch),
    ],
  ];

  var sinLatitude = math.sin(latitudeDegrees * math.pi / 180);
  var cosLatitude = math.cos(latitudeDegrees * math.pi / 180);

  // Kutuplara çok yakın noktalarda sayısal güvenlik (kaynak koddaki gibi)
  var clampedLatitude = latitudeDegrees;
  if ((90 - clampedLatitude).abs() < 0.001) clampedLatitude = 89.999;
  if ((90 + clampedLatitude).abs() < 0.001) clampedLatitude = -89.999;
  sinLatitude = math.sin(clampedLatitude * math.pi / 180);
  cosLatitude = math.cos(clampedLatitude * math.pi / 180);

  final maxOrder = 12;
  final sinLon = List<double>.generate(maxOrder + 2, (_) => 0);
  final cosLon = List<double>.generate(maxOrder + 2, (_) => 0);
  final p = List<double>.generate(120, (_) => 0);
  final q = List<double>.generate(120, (_) => 0);

  sinLon[1] = math.sin(longitudeDegrees * math.pi / 180);
  cosLon[1] = math.cos(longitudeDegrees * math.pi / 180);

  // Jeodezik -> jeosantrik dönüşüm (WGS84)
  var r = altitudeKm;
  var cd = 1.0;
  var sd = 0.0;
  {
    final aa = aSquared * cosLatitude * cosLatitude;
    final bb = bSquared * sinLatitude * sinLatitude;
    final cc = aa + bb;
    final dd = math.sqrt(cc);
    final arg =
        altitudeKm * (altitudeKm + 2 * dd) + (aSquared * aa + bSquared * bb) / cc;
    r = math.sqrt(arg);
    cd = (altitudeKm + dd) / r;
    sd = (aSquared - bSquared) /
        dd *
        sinLatitude *
        cosLatitude /
        r;
    final originalSinLatitude = sinLatitude;
    sinLatitude = sinLatitude * cd - cosLatitude * sd;
    cosLatitude = cosLatitude * cd + originalSinLatitude * sd;
  }

  final ratio = earthRadiusKm / r;
  final sqrt3 = math.sqrt(3.0);

  // Başlangıç değerleri: p ve q (n+1) ile çarpılmış Legendre değerleridir.
  p[1] = 2 * sinLatitude;
  p[2] = 2 * cosLatitude;
  p[3] = 4.5 * sinLatitude * sinLatitude - 1.5;
  p[4] = 3 * sqrt3 * cosLatitude * sinLatitude;
  q[1] = -cosLatitude;
  q[2] = sinLatitude;
  q[3] = -3 * cosLatitude * sinLatitude;
  q[4] = sqrt3 * (sinLatitude * sinLatitude - cosLatitude * cosLatitude);

  var xNorth = 0.0;
  var yEast = 0.0;
  var zDown = 0.0;

  final npq = (maxOrder * (maxOrder + 3)) ~/ 2;
  var k = 1;
  var l = 1; // gh dizininde sıradaki katsayı konumu (1 tabanlı)
  var n = 0;
  var m = 1;

  while (k <= npq) {
    if (n < m) {
      m = 0;
      n++;
    }
    final fm = m.toDouble();
    final fn = n.toDouble();
    final rr = math.pow(ratio, n + 2).toDouble();

    if (k >= 5) {
      if (m == n) {
        // Sektorel: P(n,n)
        final arg = 1.0 - 0.5 / fm;
        final aa = math.sqrt(arg);
        final j = k - n - 1;
        p[k] = (1.0 + 1.0 / fm) * aa * cosLatitude * p[j];
        q[k] = aa * (cosLatitude * q[j] + sinLatitude / fm * p[j]);
        sinLon[m] = sinLon[m - 1] * cosLon[1] + cosLon[m - 1] * sinLon[1];
        cosLon[m] = cosLon[m - 1] * cosLon[1] - sinLon[m - 1] * sinLon[1];
      } else {
        // Tesseral/zonal: P(n,m), m < n
        final arg = fn * fn - fm * fm;
        final aa = math.sqrt(arg);
        final arg2 = (fn - 1.0) * (fn - 1.0) - fm * fm;
        final bb = math.sqrt(arg2) / aa;
        final cc = (2.0 * fn - 1.0) / aa;
        final ii = k - n;
        final j = k - 2 * n + 1;
        p[k] = (fn + 1.0) *
            (cc * sinLatitude / fn * p[ii] -
                bb / (fn - 1.0) * p[j]);
        q[k] = cc *
                (sinLatitude * q[ii] -
                    cosLatitude / fn * p[ii]) -
            bb * q[j];
      }
    }

    // Kaynak koddaki düzen: m=0 için yalnızca g (L+1), m!=0 için g,h çifti (L+2)
    final gCoefficient = gh[l - 1];
    final aa = rr * gCoefficient;

    if (m == 0) {
      xNorth += aa * q[k];
      zDown -= aa * p[k];
      l++;
    } else {
      final hCoefficient = gh[l];
      final bb = rr * hCoefficient;
      final cc = aa * cosLon[m] + bb * sinLon[m];
      xNorth += cc * q[k];
      zDown -= cc * p[k];
      if (cosLatitude > 0) {
        yEast += (aa * sinLon[m] - bb * cosLon[m]) *
            fm *
            p[k] /
            ((fn + 1.0) * cosLatitude);
      } else {
        yEast +=
            (aa * sinLon[m] - bb * cosLon[m]) * q[k] * sinLatitude;
      }
      l += 2;
    }
    m++;
    k++;
  }

  // Jeosantrik -> jeodezik çerçeve dönüşü
  final originalX = xNorth;
  xNorth = xNorth * cd + zDown * sd;
  zDown = zDown * cd - originalX * sd;

  // DIHF: D, I, H, F
  final horizontal = math.sqrt(xNorth * xNorth + yEast * yEast);
  final total = math.sqrt(
      horizontal * horizontal + zDown * zDown);
  final inclination = math.atan2(zDown, horizontal) * 180 / math.pi;
  final hPlusX = horizontal + xNorth;
  var declinationRad = 0.0;
  if (hPlusX < 1e-10) {
    declinationRad = math.pi;
  } else {
    declinationRad = 2 * math.atan2(yEast, hPlusX);
  }
  var declination = declinationRad * 180 / math.pi;
  if (declination > 180) declination -= 360;
  if (declination <= -180) declination += 360;

  return MagneticFieldResult(
    declinationDegrees: declination,
    inclinationDegrees: inclination,
    horizontalIntensityNT: horizontal,
    totalIntensityNT: total,
  );
}

/// Verilen konum/tarih için manyetik sapma (derece, doğu pozitif).
double magneticDeclinationDegrees({
  required double latitudeDegrees,
  required double longitudeDegrees,
  required DateTime date,
  double altitudeKm = 0,
}) {
  return worldMagneticField(
    latitudeDegrees: latitudeDegrees,
    longitudeDegrees: longitudeDegrees,
    altitudeKm: altitudeKm,
    decimalYear: decimalYearFor(date),
  ).declinationDegrees;
}
