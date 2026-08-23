import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_vaktim/features/prayer/prayer_models.dart';
import 'package:namaz_vaktim/features/prayer/presentation/location_picker_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cities = <String>[
    'Nevşehir',
    'İstanbul',
    'Ankara',
    'İzmir',
    'Bursa',
    'Antalya',
    'Konya',
    'Kayseri',
    'Gaziantep',
    'Diyarbakır',
  ];

  testWidgets('lists ten cities and selecting one returns it and pops',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    UserLocation? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: LocationPickerScreen(
          onSelected: (location) async {
            selected = location;
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ListTile), findsNWidgets(cities.length));
    for (final city in cities) {
      expect(find.text(city), findsOneWidget);
    }
    expect(selected, isNull);

    await tester.tap(find.text('İzmir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Pop geçişi bittikten sonra rota ağaçtan bir kare sonra çıkar.
    await tester.pump(const Duration(milliseconds: 100));

    expect(selected?.city, 'İzmir');
    expect(selected?.latitude, 38.4237);
    expect(selected?.longitude, 27.1428);
    expect(find.text('Şehir seç'), findsNothing);
  });

  testWidgets('selection waits for onSelected future before popping',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    UserLocation? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: LocationPickerScreen(
          onSelected: (location) async {
            selected = location;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Ankara'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Pop geçişi bittikten sonra rota ağaçtan bir kare sonra çıkar.
    await tester.pump(const Duration(milliseconds: 100));

    expect(selected?.city, 'Ankara');
    expect(find.text('Ankara'), findsNothing);
  });
}
