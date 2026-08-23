import 'dart:math' as math;

/// Kâbe'nin koordinatlarından verilen konuma doğru gerçek kuzey kerterizi.
double qiblaBearing({required double latitude, required double longitude}) {
  const kaabaLatitude = 21.422487;
  const kaabaLongitude = 39.826206;
  final sourceLat = latitude * math.pi / 180;

  final targetLat = kaabaLatitude * math.pi / 180;
  final deltaLon = (kaabaLongitude - longitude) * math.pi / 180;
  final y = math.sin(deltaLon);
  final x = math.cos(sourceLat) * math.tan(targetLat) -
      math.sin(sourceLat) * math.cos(deltaLon);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// İvmeölçer (yerçekimi) ve manyetometre örneklerinden telefonun üst
/// kenarının gösterdiği pusula açısını hesaplar; derece cinsinden 0-360
/// döner (0 = coğrafi kuzey). Cihaz eğimliyken de doğru çalışır çünkü
/// kuzey yönü yerçekimi vektörüne göre yatay düzleme izdüşürülür.
///
/// Veri yetersizse (sıfıra yakın ivme veya manyetik alan) null döner.
double? fusedCompassHeading({
  required double gravityX,
  required double gravityY,
  required double gravityZ,
  required double magneticX,
  required double magneticY,
  required double magneticZ,
}) {
  final gravityNorm =
      math.sqrt(gravityX * gravityX + gravityY * gravityY + gravityZ * gravityZ);
  if (gravityNorm < 1e-3) return null;
  final ux = gravityX / gravityNorm;
  final uy = gravityY / gravityNorm;
  final uz = gravityZ / gravityNorm;

  // Manyetik alanın yatay bileşeni: m - (m·u)u
  final inclination = magneticX * ux + magneticY * uy + magneticZ * uz;
  final hx = magneticX - inclination * ux;
  final hy = magneticY - inclination * uy;
  final hz = magneticZ - inclination * uz;
  final horizontalNorm = math.sqrt(hx * hx + hy * hy + hz * hz);
  if (horizontalNorm < 1e-6) return null;
  final nx = hx / horizontalNorm;
  final ny = hy / horizontalNorm;
  final nz = hz / horizontalNorm;

  // Doğu birimi: doğu = kuzey × yukarı
  final ey = nz * ux - nx * uz;

  // Cihazın üst kenarı (+y ekseni) dünyada nereye bakıyor?
  // heading = atan2(doğu bileşeni, kuzey bileşeni)
  return (math.atan2(ey, ny) * 180 / math.pi + 360) % 360;
}
