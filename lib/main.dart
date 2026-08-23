import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_providers.dart';
import 'app/namaz_vaktim_app.dart';
import 'core/notification_service.dart';

export 'app/namaz_vaktim_app.dart';

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
        sharedPreferencesProvider.overrideWithValue(preferences),
        notificationPreferencesStoreProvider.overrideWithValue(
          NotificationPreferencesStore(preferences),
        ),
      ],
      child: const NamazVaktimApp(),
    ),
  );
}
