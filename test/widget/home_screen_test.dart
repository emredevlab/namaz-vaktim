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

  testWidgets('home screen shows loading then prayer times', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final config = AppConfig.production;
    final repository = _ImmediateRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prayerRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(home: HomeScreen(config: config)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Namaz Vakitleri'), findsOneWidget);
    expect(find.text('İmsak', skipOffstage: false), findsOneWidget);
    expect(find.text('04:21', skipOffstage: false), findsOneWidget);
  });

  testWidgets('home screen shows retry action when repository fails',
      (tester) async {
    final config = AppConfig.production;
    final completer = Completer<DailyPrayerTimes>();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prayerRepositoryProvider.overrideWithValue(
          _CompletingRepository(completer),
        ),
      ],
      child: MaterialApp(home: HomeScreen(config: config)),
    ));
    await tester.pump();
    completer.completeError(StateError('test failure'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Namaz vakitleri yüklenemedi. Lütfen tekrar deneyin.'),
        findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
  });

  testWidgets('feature flags hide prayer content and notification action',
      (tester) async {
    final config = _configWithFeatures(
      prayerTimes: false,
      notifications: false,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prayerRepositoryProvider.overrideWithValue(
          _CompletingRepository(Completer<DailyPrayerTimes>()),
        ),
      ],
      child: MaterialApp(home: HomeScreen(config: config)),
    ));
    await tester.pump();

    expect(find.text('Namaz Vakitleri'), findsNothing);
    expect(find.byIcon(Icons.notifications_none), findsNothing);
  });

  testWidgets('notification action is visible when enabled', (tester) async {
    final config = _configWithFeatures(
      prayerTimes: false,
      notifications: true,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prayerRepositoryProvider.overrideWithValue(
          _CompletingRepository(Completer<DailyPrayerTimes>()),
        ),
      ],
      child: MaterialApp(home: HomeScreen(config: config)),
    ));
    await tester.pump();

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  testWidgets('drawer renders configured SVG logo', (tester) async {
    final config = _configWithFeatures(
      prayerTimes: false,
      notifications: false,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        prayerRepositoryProvider.overrideWithValue(
          _CompletingRepository(Completer<DailyPrayerTimes>()),
        ),
      ],
      child: MaterialApp(home: HomeScreen(config: config)),
    ));
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pump();

    expect(find.bySemanticsLabel('${config.name} logosu'), findsOneWidget);
  });
}

AppConfig _configWithFeatures({
  required bool prayerTimes,
  required bool notifications,
}) {
  final base = AppConfig.production;
  return AppConfig(
    brand: base.brand,
    endpoints: base.endpoints,
    ads: base.ads,
    drawerItems: base.drawerItems,
    features: {
      ...base.features,
      'prayerTimes': prayerTimes,
      'notifications': notifications,
    },
  );
}

DailyPrayerTimes _dailyPrayerTimes() {
  final date = DateTime(2026, 8, 6);
  return DailyPrayerTimes(
    date: date,
    location: const UserLocation(city: 'Nevşehir'),
    times: [
      PrayerTime(type: PrayerType.imsak, dateTime: DateTime(2026, 8, 6, 4, 21)),
      PrayerTime(type: PrayerType.gunes, dateTime: DateTime(2026, 8, 6, 5, 54)),
    ],
  );
}

final class _ImmediateRepository implements PrayerTimesRepository {
  @override
  Future<DailyPrayerTimes> getDaily(UserLocation location, DateTime date) =>
      Future<DailyPrayerTimes>.value(_dailyPrayerTimes());
}

final class _CompletingRepository implements PrayerTimesRepository {
  _CompletingRepository(this.completer);
  final Completer<DailyPrayerTimes> completer;

  @override
  Future<DailyPrayerTimes> getDaily(UserLocation location, DateTime date) =>
      completer.future;
}
