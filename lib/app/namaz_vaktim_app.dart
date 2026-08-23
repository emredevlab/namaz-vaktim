import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kapadokya_mobile_core/kapadokya_mobile_core.dart';

import '../config/app_config.dart';
import '../features/prayer/presentation/home_screen.dart';
import '../features/prayer/presentation/prayer_times_screen.dart';
import '../features/prayer/prayer_repository.dart';
import 'app_navigation.dart';
import 'app_providers.dart';

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
        builder: (_) => PrayerTimesScreen(config: widget.config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme =
        ColorScheme.fromSeed(seedColor: widget.config.primaryColor);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: widget.config.primaryColor,
      brightness: Brightness.dark,
    );
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
              // API erişilemezse son başarılı gerçek vakitler gösterilir.
              cache: SharedPreferencesStorage(
                ref.read(sharedPreferencesProvider),
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
            colorScheme: lightScheme,
            scaffoldBackgroundColor: lightScheme.surface),
        darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            scaffoldBackgroundColor: darkScheme.surface),
        themeMode: ThemeMode.system,
        home: HomeScreen(config: widget.config),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
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
