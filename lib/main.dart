import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app/app_navigation.dart';
import 'app/app_providers.dart';
import 'config/app_config.dart';
import 'features/prayer/prayer_models.dart';
import 'features/prayer/magnetic_declination.dart';
import 'features/prayer/prayer_repository.dart';
import 'features/prayer/qibla_calculator.dart';
import 'core/notification_service.dart';
import 'core/permission_manager.dart';
import 'core/web_navigation_policy.dart';
import 'package:kapadokya_mobile_core/kapadokya_mobile_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  try {
    await MobileAds.instance.initialize();
  } catch (_) {
    // Reklam SDK'si başlatılamasa da uygulamanın ana işlevleri çalışmalıdır.
  }
  runApp(
    ProviderScope(
      overrides: [
        notificationPreferencesStoreProvider.overrideWithValue(
          NotificationPreferencesStore(preferences),
        ),
      ],
      child: const NamazVaktimApp(),
    ),
  );
}

class NamazVaktimApp extends StatelessWidget {
  const NamazVaktimApp({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<AppConfig>(
        future: AppConfigLoader(rootBundle).load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MaterialApp(home: _LoadingScreen());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return MaterialApp(home: _ConfigErrorScreen(error: snapshot.error));
          }
          final config = snapshot.data!;
          final errors = const AppConfigValidator().validate(config);
          if (errors.isNotEmpty) {
            return MaterialApp(
                home: _ConfigErrorScreen(error: errors.join('\n')));
          }
          return _ConfiguredApp(config: config);
        },
      );
}

class _ConfiguredApp extends ConsumerStatefulWidget {
  const _ConfiguredApp({required this.config});
  final AppConfig config;

  @override
  ConsumerState<_ConfiguredApp> createState() => _ConfiguredAppState();
}

class _ConfiguredAppState extends ConsumerState<_ConfiguredApp> {
  @override
  void initState() {
    super.initState();
    notificationRouteHandler = _openRoute;
    Future<void>.microtask(() async {
      // Bildirime dokunularak soğuk başlatıldıysa rota isteğini işle.
      final scheduler = ref.read(notificationSchedulerProvider);
      final payload = await scheduler.initialPayload();
      if (payload != null) handleNotificationPayload(payload);
    });
  }

  @override
  void dispose() {
    if (notificationRouteHandler == _openRoute) {
      notificationRouteHandler = null;
    }
    super.dispose();
  }

  void _openRoute(String route) {
    if (route != '/prayer-times') return;
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => _PrayerTimesScreen(config: widget.config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: widget.config.primaryColor);
    final networkClient = HttpNetworkClient();
    return ProviderScope(
      overrides: [
        prayerRepositoryProvider.overrideWith(
          (ref) {
            ref.onDispose(networkClient.close);
            return ResilientPrayerTimesRepository(
              primary: ApiPrayerTimesRepository(
                network: networkClient,
                endpoint: widget.config.endpoints.api,
              ),
            );
          },
        ),
      ],
      child: MaterialApp(
        title: widget.config.name,
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            scaffoldBackgroundColor: scheme.surface),
        home: HomeScreen(config: widget.config),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({required this.config, super.key});
  final AppConfig config;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _savedCityKey = 'saved_city';
  static const _savedLatitudeKey = 'saved_latitude';
  static const _savedLongitudeKey = 'saved_longitude';
  bool _loadingLocation = false;
  BannerAd? _bannerAd;

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceLocation() async {
    setState(() => _loadingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Konum servisi kapalı.');
      }
      final manager = ref.read(permissionManagerProvider);
      var status = await manager.status(AppPermission.location);
      if (status == PermissionStatus.denied) {
        status = await manager.request(AppPermission.location);
      }
      if (status != PermissionStatus.granted) {
        throw StateError('Konum izni verilmedi.');
      }
      final position = await Geolocator.getCurrentPosition();
      final location = UserLocation(
        city: 'Mevcut konum',
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_savedCityKey, location.city);
      await preferences.setDouble(_savedLatitudeKey, position.latitude);
      await preferences.setDouble(_savedLongitudeKey, position.longitude);
      await ref.read(prayerControllerProvider).load(location: location);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(prayerControllerProvider).load();
      _restoreSavedLocation();
      if (widget.config.ads.enabled) {
        _bannerAd = BannerAd(
          adUnitId: widget.config.ads.bannerId,
          size: AdSize.banner,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdFailedToLoad: (ad, _) => ad.dispose(),
          ),
        )..load();
      }
    });
  }

  Future<void> _restoreSavedLocation() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final city = preferences.getString(_savedCityKey);
      if (city == null || !mounted) return;
      await ref.read(prayerControllerProvider).load(
            location: UserLocation(
              city: city,
              latitude: preferences.getDouble(_savedLatitudeKey),
              longitude: preferences.getDouble(_savedLongitudeKey),
            ),
          );
    } catch (_) {
      // Kayıtlı konum okunamazsa varsayılan Nevşehir konumu kullanılır.
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final prayerState = ref.watch(prayerControllerProvider).state;
    final prayerEnabled = config.features['prayerTimes'] ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
        actions: [
          if (config.features['notifications'] ?? false)
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const _NotificationSettingsScreen()),
              ),
              icon: const Icon(Icons.notifications_none),
              tooltip: 'Bildirim ayarları',
            )
        ],
      ),
      drawer: _AppDrawer(
        config: config,
        onLocationSelected: (location) async {
          final preferences = await SharedPreferences.getInstance();
          await preferences.setString(_savedCityKey, location.city);
          if (location.latitude != null) {
            await preferences.setDouble(_savedLatitudeKey, location.latitude!);
          }
          if (location.longitude != null) {
            await preferences.setDouble(
                _savedLongitudeKey, location.longitude!);
          }
          if (mounted) {
            await ref.read(prayerControllerProvider).load(location: location);
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _LocationCard(
            config: config,
            data: prayerState.data,
            loadingLocation: _loadingLocation,
            onUseDeviceLocation: _loadDeviceLocation,
          ),
          if (_bannerAd != null) ...[
            const SizedBox(height: 12),
            SizedBox(height: 50, child: AdWidget(ad: _bannerAd!)),
          ],
          if (prayerEnabled) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Namaz Vakitleri',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                if (prayerState.data?.isFallback ?? false)
                  const Chip(
                    avatar: Icon(Icons.wifi_off, size: 16),
                    label: Text('Çevrimdışı'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (prayerState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (prayerState.error != null)
              _PrayerError(
                message: prayerState.error!,
                onRetry: () => ref.read(prayerControllerProvider).load(),
              )
            else
              _PrayerTimes(data: prayerState.data),
          ],
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.config, required this.onLocationSelected});
  final AppConfig config;
  final Future<void> Function(UserLocation location) onLocationSelected;

  @override
  Widget build(BuildContext context) => Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: config.primaryColor),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: SvgPicture.asset(
                          config.logoAsset,
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                          semanticsLabel: '${config.name} logosu',
                          placeholderBuilder: (_) => const Icon(
                            Icons.mosque_outlined,
                            color: Color(0xFF0D6B5D),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(config.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              ...config.drawerItems.map((item) => ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    onTap: () {
                      Navigator.pop(context);
                      final Widget? destination = switch (item.route) {
                        '/prayer-times' => _PrayerTimesScreen(config: config),
                        '/qibla' => const _QiblaScreen(),
                        '/location' => _LocationPickerScreen(
                            onSelected: onLocationSelected,
                          ),
                        '/prayers' => const _DuasScreen(),
                        '/settings/notifications' =>
                          const _NotificationSettingsScreen(),
                        _ => null,
                      };
                      if (destination != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => destination),
                        );
                      }
                    },
                  )),
              ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: const Text('Şehir seç'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _LocationPickerScreen(
                        onSelected: onLocationSelected,
                      ),
                    ),
                  );
                },
              ),
              if (config.features['webContent'] ?? false)
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Web sitesini aç'),
                  onTap: () async {
                    Navigator.pop(context);
                    final uri = Uri.tryParse(config.endpoints.web.toString());
                    if (uri == null ||
                        const WebNavigationPolicy(allowedOrigins: {
                              'https://kapadokyabulut.com.tr',
                              'https://www.kapadokyabulut.com.tr',
                            }).decide(uri) !=
                            WebNavigationDecision.internal) {
                      return;
                    }
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
            ],
          ),
        ),
      );
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
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
  Widget build(BuildContext context) {
    final next = data?.next;
    return Card(
      color: config.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(
                child: Text(data?.location.city ?? 'Nevşehir',
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
              IconButton(
                onPressed: loadingLocation ? null : onUseDeviceLocation,
                color: Colors.white,
                tooltip: 'Mevcut konumu kullan',
                icon: loadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
              next == null
                  ? 'Bugünün vakitleri'
                  : 'Sonraki Namaz: ${_label(next.type)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(next == null ? '--:--' : _formatTime(next.dateTime),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _PrayerError extends StatelessWidget {
  const _PrayerError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text(message),
          trailing:
              TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
        ),
      );
}

class _PrayerTimes extends StatelessWidget {
  const _PrayerTimes({required this.data});
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
                    Text(_label(item.type)),
                    const SizedBox(height: 6),
                    Text(_formatTime(item.dateTime),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ]),
            ),
          );
        },
      );
}

String _label(PrayerType type) => switch (type) {
      PrayerType.imsak => 'İmsak',
      PrayerType.gunes => 'Güneş',
      PrayerType.ogle => 'Öğle',
      PrayerType.ikindi => 'İkindi',
      PrayerType.aksam => 'Akşam',
      PrayerType.yatsi => 'Yatsı',
    };

String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _NotificationSettingsScreen extends ConsumerStatefulWidget {
  const _NotificationSettingsScreen();

  @override
  ConsumerState<_NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<_NotificationSettingsScreen> {
  late bool _enabled;
  late bool _dailyReminder;
  late int _minutesBefore;

  @override
  void initState() {
    super.initState();
    final preferences =
        ref.read(prayerControllerProvider).notificationPreferences;
    _enabled = preferences.enabled;
    _dailyReminder = preferences.dailyReminder;
    _minutesBefore = preferences.minutesBefore;
  }

  Future<void> _save() async {
    try {
      await ref.read(prayerControllerProvider).updateNotificationPreferences(
            NotificationPreferences(
              enabled: _enabled,
              minutesBefore: _minutesBefore,
              dailyReminder: _dailyReminder,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildirim ayarları kaydedilemedi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bildirim ayarları')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Namaz bildirimleri'),
              subtitle: const Text('Vakit yaklaşınca bildirim gönder'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Günlük hatırlatma'),
              subtitle: const Text('Her gün sabah namazı için ek hatırlatma'),
              value: _dailyReminder,
              onChanged: (value) => setState(() => _dailyReminder = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _minutesBefore,
              decoration: const InputDecoration(
                labelText: 'Bildirim zamanı',
                border: OutlineInputBorder(),
              ),
              items: const [10, 15, 30]
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value dakika önce'),
                      ))
                  .toList(),
              onChanged: _enabled
                  ? (value) {
                      if (value != null) setState(() => _minutesBefore = value);
                    }
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Kaydet'),
            ),
          ],
        ),
      );
}

class _PrayerTimesScreen extends ConsumerWidget {
  const _PrayerTimesScreen({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prayerControllerProvider).state;
    final data = state.data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Vakitleri'),
        actions: [
          IconButton(
            tooltip: 'Vakitleri yenile',
            onPressed: state.isLoading
                ? null
                : () => ref.read(prayerControllerProvider).load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(prayerControllerProvider).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _LocationCard(
              config: config,
              data: data,
              loadingLocation: false,
              onUseDeviceLocation: () {},
            ),
            const SizedBox(height: 16),
            if (data?.isFallback ?? false)
              const Card(
                color: Color(0xFFFFF4D6),
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Çevrimdışı örnek vakitler'),
                  subtitle: Text(
                      'Sunucuya ulaşılamadı. İnternet bağlantısı kurulduğunda yenileyin.'),
                ),
              ),
            if (data != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(_formatDate(data.date)),
                  subtitle: Text('${data.location.city} için günlük vakitler'),
                ),
              ),
            const SizedBox(height: 16),
            if (state.isLoading && data == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && data == null)
              _PrayerError(
                message: state.error!,
                onRetry: () => ref.read(prayerControllerProvider).load(),
              )
            else
              ...?data?.times.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          config.primaryColor.withValues(alpha: .12),
                      foregroundColor: config.primaryColor,
                      child: Icon(_prayerIcon(item.type)),
                    ),
                    title: Text(_label(item.type)),
                    trailing: Text(
                      _formatTime(item.dateTime),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: config.primaryColor,
                              ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Vakitler bulunduğunuz şehir ve yerel saat dilimine göre gösterilir. İnternet bağlantısı olmadığında son başarılı sonuç ekranda kalır.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPickerScreen extends StatelessWidget {
  const _LocationPickerScreen({required this.onSelected});
  final Future<void> Function(UserLocation location) onSelected;

  static const _cities = <UserLocation>[
    UserLocation(city: 'Nevşehir', latitude: 38.6244, longitude: 34.7239),
    UserLocation(city: 'İstanbul', latitude: 41.0082, longitude: 28.9784),
    UserLocation(city: 'Ankara', latitude: 39.9334, longitude: 32.8597),
    UserLocation(city: 'İzmir', latitude: 38.4237, longitude: 27.1428),
    UserLocation(city: 'Bursa', latitude: 40.1950, longitude: 29.0600),
    UserLocation(city: 'Antalya', latitude: 36.8969, longitude: 30.7133),
    UserLocation(city: 'Konya', latitude: 37.8746, longitude: 32.4932),
    UserLocation(city: 'Kayseri', latitude: 38.7225, longitude: 35.4875),
    UserLocation(city: 'Gaziantep', latitude: 37.0662, longitude: 37.3833),
    UserLocation(city: 'Diyarbakır', latitude: 37.9144, longitude: 40.2306),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Şehir seç')),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _cities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final location = _cities[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(location.city),
                subtitle: Text(
                    '${location.latitude!.toStringAsFixed(3)}, ${location.longitude!.toStringAsFixed(3)}'),
                onTap: () async {
                  await onSelected(location);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            );
          },
        ),
      );
}

class _QiblaScreen extends StatefulWidget {
  const _QiblaScreen();

  @override
  State<_QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<_QiblaScreen> {
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

class _DuasScreen extends StatelessWidget {
  const _DuasScreen();

  static const _duas = <({String title, String arabic, String meaning})>[
    (
      title: 'Yemek Duası',
      arabic: 'Bismillâhirrahmânirrahîm',
      meaning: 'Rahmân ve Rahîm olan Allah’ın adıyla.',
    ),
    (
      title: 'Rabbenâ Âtinâ',
      arabic:
          'Rabbenâ âtinâ fid-dünyâ haseneten ve fil-âhireti haseneten ve kınâ azâben-nâr.',
      meaning:
          'Rabbimiz! Bize dünyada iyilik, ahirette de iyilik ver ve bizi ateş azabından koru.',
    ),
    (
      title: 'Rabbi Yessir',
      arabic: 'Rabbi yessir velâ tuassir, Rabbi temmim bil-hayr.',
      meaning: 'Rabbim kolaylaştır, zorlaştırma; Rabbim hayırla tamamla.',
    ),
    (
      title: 'İlim Duası',
      arabic: 'Rabbi zidnî ilmâ.',
      meaning: 'Rabbim, ilmimi artır.',
    ),
    (
      title: 'Bağışlanma Duası',
      arabic: 'Estağfirullâhel azîm ve etûbü ileyh.',
      meaning: 'Yüce Allah’tan bağışlanma diler ve O’na tövbe ederim.',
    ),
    (
      title: 'Yolculuk Duası',
      arabic: 'Sübhânellezî sehhara lenâ hâzâ ve mâ kunnâ lehû mukrinîn.',
      meaning:
          'Bunu bizim hizmetimize veren Allah’ı noksan sıfatlardan tenzih ederiz; yoksa buna gücümüz yetmezdi.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Dualar')),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _duas.length,
          itemBuilder: (context, index) {
            final dua = _duas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(dua.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      dua.arabic,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(height: 1.6),
                    ),
                  ),
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                        Text(dua.meaning, style: const TextStyle(height: 1.5)),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

IconData _prayerIcon(PrayerType type) => switch (type) {
      PrayerType.imsak => Icons.nightlight_outlined,
      PrayerType.gunes => Icons.wb_sunny_outlined,
      PrayerType.ogle => Icons.light_mode_outlined,
      PrayerType.ikindi => Icons.wb_twilight_outlined,
      PrayerType.aksam => Icons.nights_stay_outlined,
      PrayerType.yatsi => Icons.dark_mode_outlined,
    };

String _formatDate(DateTime value) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık'
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

class _ConfigErrorScreen extends StatelessWidget {
  const _ConfigErrorScreen({required this.error});
  final Object? error;

  String get _safeMessage {
    if (error is String && (error! as String).trim().isNotEmpty) {
      return error! as String;
    }
    return 'Yapılandırma dosyası okunamadı. Lütfen uygulamayı yeniden başlatın.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              header: true,
              label: 'Yapılandırma hatası',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Uygulama başlatılamadı',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(_safeMessage, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
}
