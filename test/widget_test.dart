import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namaz_vaktim/app/app_providers.dart';
import 'package:namaz_vaktim/config/app_config.dart';
import 'package:namaz_vaktim/features/prayer/presentation/home_screen.dart';
import 'package:namaz_vaktim/features/prayer/prayer_models.dart';
import 'package:namaz_vaktim/features/prayer/prayer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home screen starts in loading state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(
            _PendingRepository(),
          ),
        ],
        child: MaterialApp(home: HomeScreen(config: AppConfig.production)),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

final class _PendingRepository implements PrayerTimesRepository {
  @override
  Future<DailyPrayerTimes> getDaily(UserLocation location, DateTime date) =>
      Completer<DailyPrayerTimes>().future;
}
