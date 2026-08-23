import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namaz_vaktim/app/app_providers.dart';
import 'package:namaz_vaktim/core/notification_service.dart';
import 'package:namaz_vaktim/features/prayer/prayer_models.dart';
import 'package:namaz_vaktim/features/prayer/prayer_repository.dart';
import 'package:namaz_vaktim/features/prayer/presentation/notification_settings_screen.dart';

final class _StubRepository implements PrayerTimesRepository {
  @override
  Future<DailyPrayerTimes> getDaily(UserLocation location, DateTime date) =>
      throw UnimplementedError('Testte depo kullanılmaz.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openSettings(WidgetTester tester, NotificationPreferencesStore store) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(_StubRepository()),
          notificationPreferencesStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  ),
                  child: const Text('Ayarları aç'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ayarları aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('switches start with stored preferences', (tester) async {
    final store = NotificationPreferencesStore.memory();
    await store.write(
      const NotificationPreferences(
          enabled: false, minutesBefore: 30, dailyReminder: false),
    );

    await openSettings(tester, store);

    expect(find.text('Bildirim ayarları'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Namaz bildirimleri'),
          )
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Günlük hatırlatma'),
          )
          .value,
      isFalse,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<int> &&
            widget.initialValue == 30,
      ),
      findsOneWidget,
    );
  });

  testWidgets('Kaydet persists changes and closes the screen', (tester) async {
    final store = NotificationPreferencesStore.memory();

    await openSettings(tester, store);

    // Varsayılanlar açık (true); iki switch'i de kapat.
    await tester.tap(find.text('Namaz bildirimleri'));
    await tester.tap(find.text('Günlük hatırlatma'));
    await tester.pump();

    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Namaz bildirimleri'),
          )
          .value,
      isFalse,
    );

    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Pop geçişi bittikten sonra rota ağaçtan bir kare sonra çıkar.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bildirim ayarları'), findsNothing);

    final saved = store.read();
    expect(saved.enabled, isFalse);
    expect(saved.dailyReminder, isFalse);
    expect(saved.minutesBefore, 10);
  });

  testWidgets('Kaydet keeps disabled state when switches stay off',
      (tester) async {
    final store = NotificationPreferencesStore.memory();
    await store.write(
      const NotificationPreferences(enabled: false, minutesBefore: 15),
    );

    await openSettings(tester, store);

    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Pop geçişi bittikten sonra rota ağaçtan bir kare sonra çıkar.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bildirim ayarları'), findsNothing);

    final saved = store.read();
    expect(saved.enabled, isFalse);
    expect(saved.minutesBefore, 15);
  });
}
