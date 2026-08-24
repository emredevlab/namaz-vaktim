import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_providers.dart';
import '../../../core/permission_manager.dart';
import '../../../shared/design/app_theme.dart';
import '../magnetic_declination.dart';
import '../qibla_calculator.dart';
import 'widgets/qibla_dial.dart';

/// GPS koordinatlarını ters geocoding ile şehir adına çözer; ilk
/// placemark'ın sırasıyla locality, subAdministrativeArea ve
/// administrativeArea değerlerinden boş olmayan ilki döner.
/// Sonuç yoksa (çevrimdışı/servis yok/hata) null döner.
Future<String?> _resolveCityName(double latitude, double longitude) async {
  try {
    final placemarks =
        await Geocoding().placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;
    final placemark = placemarks.first;
    for (final candidate in <String?>[
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }
    return null;
  } catch (_) {
    // Geocoding servisi kullanılamazsa yedek isim kullanılır.
    return null;
  }
}

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key, this.onLocate});

  /// Cihaz konumunu alma akışı; testlerde sahte bir akış enjekte edilebilir.
  /// Null ise varsayılan izin + GPS akışı çalışır.
  final Future<void> Function()? onLocate;

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  List<double>? _gravity;
  List<double>? _magnetic;
  DateTime _lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  double? _heading;
  double? _horizontalField;
  double _qiblaBearing = 145.4;
  double? _qiblaTrueBearing;
  double? _declination;
  String _locationName = 'Nevşehir';
  bool? _hasSavedLocation;
  bool _locating = false;

  static const double _smoothingFactor = 0.1;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    // Test ortamında platform kanalları yoktur; sensör hataları yutulur.
    _accelerometerSubscription = accelerometerEventStream().listen(
      (event) {
        _gravity = _smooth(_gravity, [event.x, event.y, event.z]);
        _updateHeading();
      },
      onError: (Object _) {},
    );
    _magnetometerSubscription = magnetometerEventStream().listen(
      (event) {
        _magnetic = _smooth(_magnetic, [event.x, event.y, event.z]);
        _updateHeading();
      },
      onError: (Object _) {},
    );
  }

  List<double> _smooth(List<double>? previous, List<double> sample) {
    if (previous == null) return sample;
    return <double>[
      for (var index = 0; index < 3; index++)
        previous[index] + (sample[index] - previous[index]) * _smoothingFactor,
    ];
  }

  void _updateHeading() {
    final gravity = _gravity;
    final magnetic = _magnetic;
    if (gravity == null || magnetic == null || !mounted) return;
    final heading = fusedCompassHeading(
      gravityX: gravity[0],
      gravityY: gravity[1],
      gravityZ: gravity[2],
      magneticX: magnetic[0],
      magneticY: magnetic[1],
      magneticZ: magnetic[2],
    );
    if (heading == null) return;
    final horizontalField = math.sqrt(
      magnetic[0] * magnetic[0] +
          magnetic[1] * magnetic[1] +
          magnetic[2] * magnetic[2],
    );
    final now = DateTime.now();
    final changedEnough =
        _heading == null || (_heading! - heading).abs() > 0.5;
    if (!changedEnough ||
        now.difference(_lastUiUpdate) < const Duration(milliseconds: 66)) {
      return;
    }
    _lastUiUpdate = now;
    setState(() {
      _heading = heading;
      _horizontalField = horizontalField;
    });
  }

  Future<void> _loadLocation() async {
    final preferences = await SharedPreferences.getInstance();
    final latitude = preferences.getDouble('saved_latitude');
    final longitude = preferences.getDouble('saved_longitude');
    final city = preferences.getString('saved_city') ?? 'Nevşehir';
    if (!mounted) return;
    if (latitude != null && longitude != null) {
      _applyLocation(latitude: latitude, longitude: longitude, city: city);
    } else {
      setState(() {
        _hasSavedLocation = false;
        _locationName = city;
      });
    }
  }

  void _applyLocation({
    required double latitude,
    required double longitude,
    required String city,
  }) {
    var bearing = qiblaBearing(latitude: latitude, longitude: longitude);
    double? declination;
    try {
      // Manyetik pusula manyetik kuzeyi gösterir; hedef açıyı sapma
      // kadar düzelt (doğu pozitif sapma eksi yönde uygulanır).
      declination = magneticDeclinationDegrees(
        latitudeDegrees: latitude,
        longitudeDegrees: longitude,
        date: DateTime.now(),
        altitudeKm: 0,
      );
    } catch (_) {
      // Sapma hesaplanamazsa gerçek kuzey kerterizi kullanılır.
    }
    setState(() {
      _hasSavedLocation = true;
      _locationName = city;
      _qiblaTrueBearing = bearing;
      _declination = declination;
      _qiblaBearing =
          declination == null ? bearing : bearing - declination;
    });
  }

  Future<void> _acquireDeviceLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final manager = ref.read(permissionManagerProvider);
      var status = await manager.status(AppPermission.location);
      if (status == PermissionStatus.denied) {
        status = await manager.request(AppPermission.location);
      }
      if (status != PermissionStatus.granted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Konum izni verilmedi.')),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final city = await _resolveCityName(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      _applyLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city ?? 'Mevcut konum',
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Konum alınamadı.')),
      );
    }
  }

  Future<void> _handleLocatePressed() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      await (widget.onLocate ?? _acquireDeviceLocation)();
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = _heading;
    final aligned = heading != null &&
        QiblaDial.isAligned(heading: heading, qiblaBearing: _qiblaBearing);
    return Scaffold(
      appBar: AppBar(title: const Text('Kıble')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          _buildDialCard(theme, heading, aligned),
          const SizedBox(height: 16),
          _buildTipsCard(),
          const SizedBox(height: 16),
          _buildLocationCard(theme),
        ],
      ),
    );
  }

  Widget _buildDialCard(ThemeData theme, double? heading, bool aligned) {
    final weakField = _horizontalField != null && _horizontalField! < 15;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeep.withValues(alpha: .4),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(30.4),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          QiblaDial(
                            heading: heading,
                            qiblaBearing: _qiblaBearing,
                          ),
                          if (heading == null)
                            Center(child: _buildSensorWaitBadge()),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (heading != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeadingChip(heading),
                      _buildAlignmentChip(heading, aligned),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  heading == null
                      ? 'Pusula sensörü bekleniyor'
                      : 'Kıble: ${_qiblaBearing.toStringAsFixed(1)}°',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.cream,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  heading == null
                      ? 'İvme ölçer ve manyetometre verisi bekleniyor.'
                      : 'Telefonu düz tutun ve yön oku kıbleyi gösterene kadar dönün.',
                  textAlign: TextAlign.center,
                ),
                if (_declination != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Sapma düzeltmesi: ${_declination!.toStringAsFixed(1)}° '
                    '(${_declination! >= 0 ? 'doğu' : 'batı'}) · '
                    'Gerçek kerteriz: ${_qiblaTrueBearing?.toStringAsFixed(1)}°',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (weakField) ...[
                  const SizedBox(height: 12),
                  _buildWeakFieldWarning(theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorWaitBadge() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.darkCardAlt,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.gold.withValues(alpha: .45)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .45), blurRadius: 16),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Icon(Icons.navigation, size: 30, color: AppTheme.goldSoft),
      ),
    );
  }

  Widget _buildHeadingChip(double heading) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.darkCardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_outlined,
                size: 15, color: AppTheme.gold),
            const SizedBox(width: 6),
            Text(
              '${heading.round()}°',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.cream,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlignmentChip(double heading, bool aligned) {
    if (aligned) {
      return _chip(
        icon: Icons.check_circle,
        label: 'Hizalandı',
        color: Colors.greenAccent,
        background: Colors.greenAccent.withValues(alpha: .12),
        border: Colors.greenAccent.withValues(alpha: .35),
      );
    }
    final signed = ((_qiblaBearing - heading + 540) % 360) - 180;
    return _chip(
      icon: signed > 0 ? Icons.rotate_right : Icons.rotate_left,
      label: 'Kıbleye dön',
      color: AppTheme.goldSoft,
      background: AppTheme.gold.withValues(alpha: .12),
      border: AppTheme.gold.withValues(alpha: .35),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
    required Color background,
    required Color border,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakFieldWarning(ThemeData theme) {
    final error = theme.colorScheme.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: error.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: error.withValues(alpha: .3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Manyetik alan zayıf; metal eşyalardan uzaklaşın.',
                style: TextStyle(
                  color: error,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.compass_calibration, color: AppTheme.gold),
        title: const Text('Doğru ölçüm için'),
        subtitle: const Text(
            'Metal eşyalardan ve mıknatıslı kılıflardan uzak durun. Kalibrasyon için cihazı sekiz şeklinde hareket ettirin.'),
      ),
    );
  }

  Widget _buildLocationCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppTheme.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Konum bilgisi',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                'Kıble hesabı $_locationName konumuna göre yapılmaktadır.'),
            if (_hasSavedLocation == false) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _locating ? null : _handleLocatePressed,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
                label: const Text('Konum kullan'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
