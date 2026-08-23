import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kapadokya_mobile_core/kapadokya_mobile_core.dart';

import '../config/app_config.dart';
import '../core/app_open_ad_manager.dart';
import '../features/prayer/presentation/home_screen.dart';
import '../features/prayer/presentation/prayer_times_screen.dart';
import '../features/prayer/prayer_repository.dart';
import '../shared/design/app_theme.dart';
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

class _ConfiguredAppState extends ConsumerState<_ConfiguredApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    notificationRouteHandler = _openRoute;
    final ads = widget.config.ads;
    if (ads.enabled && ads.appOpenId.trim().isNotEmpty) {
      Future<void>.microtask(() {
        ref.read(appOpenAdManagerProvider).load(ads.appOpenId);
      });
    }
    Future<void>.microtask(() async {
      // Bildirime dokunularak soğuk başlatıldıysa rota isteğini işle.
      final scheduler = ref.read(notificationSchedulerProvider);
      final payload = await scheduler.initialPayload();
      if (payload != null) handleNotificationPayload(payload);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      return;
    }
    final manager = ref.read(appOpenAdManagerProvider);
    if (AppOpenAdManager.shouldShowOnResume(
      adLoaded: manager.isLoaded,
      isShowing: manager.isShowing,
      state: state,
    )) {
      manager.showIfAvailable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
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
