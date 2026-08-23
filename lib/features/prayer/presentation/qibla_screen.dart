import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../magnetic_declination.dart';
import '../qibla_calculator.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
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

  static const double _smoothingFactor = 0.1;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _gravity = _smooth(_gravity, [event.x, event.y, event.z]);
      _updateHeading();
    });
    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      _magnetic = _smooth(_magnetic, [event.x, event.y, event.z]);
      _updateHeading();
    });
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
    var bearing = _qiblaBearing;
    double? declination;
    if (latitude != null && longitude != null) {
      bearing = qiblaBearing(latitude: latitude, longitude: longitude);
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
    }
    setState(() {
      _locationName = city;
      _qiblaTrueBearing = bearing;
      _declination = declination;
      _qiblaBearing =
          declination == null ? bearing : bearing - declination;
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turn = _heading == null ? 0.0 : _qiblaBearing - _heading!;
    final weakField = _horizontalField != null && _horizontalField! < 15;
    return Scaffold(
      appBar: AppBar(title: const Text('Kıble')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Transform.rotate(
                    angle: turn * math.pi / 180,
                    child: Icon(Icons.navigation,
                        size: 150,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _heading == null
                        ? 'Pusula sensörü bekleniyor'
                        : 'Kıble: ${_qiblaBearing.toStringAsFixed(1)}°',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _heading == null
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
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (weakField) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Manyetik alan zayıf; metal eşyalardan uzaklaşın.',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Doğru ölçüm için'),
              subtitle: Text(
                  'Metal eşyalardan ve mıknatıslı kılıflardan uzak durun. Kalibrasyon için cihazı sekiz şeklinde hareket ettirin.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Konum bilgisi'),
              subtitle: Text(
                  'Kıble hesabı $_locationName konumuna göre yapılmaktadır.'),
            ),
          ),
        ],
      ),
    );
  }
}
