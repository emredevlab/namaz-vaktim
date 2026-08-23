import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_vaktim/features/prayer/prayer_models.dart';
import 'package:namaz_vaktim/features/prayer/presentation/location_picker_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const provinces = <String>[
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Aksaray',
    'Amasya',
    'Ankara',
    'Antalya',
    'Ardahan',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bartın',
    'Batman',
    'Bayburt',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Düzce',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkari',
    'Hatay',
    'Iğdır',
    'Isparta',
    'İstanbul',
    'İzmir',
    'Kahramanmaraş',
    'Karabük',
    'Karaman',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırıkkale',
    'Kırklareli',
    'Kırşehir',
    'Kilis',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Mardin',
    'Mersin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Osmaniye',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Şanlıurfa',
    'Şırnak',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Uşak',
    'Van',
    'Yalova',
    'Yozgat',
    'Zonguldak',
  ];

  Future<void> pumpPicker(
    WidgetTester tester, {
    void Function(UserLocation location)? onSelected,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: LocationPickerScreen(
          onSelected: (location) async {
            onSelected?.call(location);
          },
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('lists all 81 provinces in turkish alphabetical order',
      (tester) async {
    expect(provinces, hasLength(81));
    expect(provinces.toSet(), hasLength(81));

    await pumpPicker(tester);

    for (final city in provinces.take(8)) {
      expect(find.text(city), findsOneWidget);
    }
    double dyOf(String city) => tester.getTopLeft(find.text(city)).dy;
    for (var i = 0; i < 7; i++) {
      expect(dyOf(provinces[i]), lessThan(dyOf(provinces[i + 1])),
          reason: '${provinces[i]} must be above ${provinces[i + 1]}');
    }

    var lastCity = provinces.first;
    for (final city in provinces.skip(1)) {
      final titleFinder = find.text(city);
      var drags = 0;
      while (titleFinder.evaluate().isEmpty && drags < 90) {
        await tester.drag(find.byType(ListView), const Offset(0, -120));
        await tester.pumpAndSettle();
        drags++;
      }
      expect(titleFinder, findsOneWidget);
      lastCity = city;
    }
    expect(lastCity, 'Zonguldak');
    expect(find.text('Şehir seç'), findsOneWidget);
  });

  testWidgets('selecting izmir returns it and pops', (tester) async {
    UserLocation? selected;
    await pumpPicker(tester, onSelected: (location) => selected = location);

    expect(selected, isNull);

    await tester.enterText(find.byType(TextField), 'izmir');
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(1));

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
    UserLocation? selected;
    await pumpPicker(tester, onSelected: (location) => selected = location);

    await tester.tap(find.text('Ankara'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Pop geçişi bittikten sonra rota ağaçtan bir kare sonra çıkar.
    await tester.pump(const Duration(milliseconds: 100));

    expect(selected?.city, 'Ankara');
    expect(find.text('Ankara'), findsNothing);
  });

  testWidgets('search filters cities ignoring turkish i casing and dots',
      (tester) async {
    await pumpPicker(tester);

    await tester.enterText(find.byType(TextField), 'istan');
    await tester.pump();

    expect(find.byType(ListTile), findsNWidgets(1));
    expect(find.text('İstanbul'), findsOneWidget);
    expect(find.text('Ankara'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Adana'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ANKARA');
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(1));
    expect(find.text('Ankara'), findsOneWidget);
    expect(find.text('Antalya'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ISTANBUL');
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(1));
    expect(find.text('İstanbul'), findsOneWidget);
  });

  testWidgets('search without results shows empty message', (tester) async {
    await pumpPicker(tester);

    await tester.enterText(find.byType(TextField), 'xyztanımsız');
    await tester.pump();

    expect(find.text('Şehir bulunamadı'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('selecting searched nevsehir returns known coordinates',
      (tester) async {
    UserLocation? selected;
    await pumpPicker(tester, onSelected: (location) => selected = location);

    await tester.enterText(find.byType(TextField), 'NEVŞEHİR');
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(1));

    await tester.tap(find.text('Nevşehir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Pop geçişi bittikten sonra rota ağaçtan bir kare sonra çıkar.
    await tester.pump(const Duration(milliseconds: 100));

    expect(selected?.city, 'Nevşehir');
    expect(selected?.latitude, 38.6244);
    expect(selected?.longitude, 34.7239);
    expect(find.text('Şehir seç'), findsNothing);
  });
}
