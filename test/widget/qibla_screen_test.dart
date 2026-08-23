import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namaz_vaktim/features/prayer/presentation/qibla_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpQibla(
    WidgetTester tester, {
    Future<void> Function()? onLocate,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: QiblaScreen(onLocate: onLocate)),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('qibla screen renders compass without sensor data',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpQibla(tester);

    expect(find.text('Kıble'), findsOneWidget);
    expect(find.byIcon(Icons.navigation), findsOneWidget);
    // Sensör akışları testte veri üretmez: başlık null kalır.
    expect(find.text('Pusula sensörü bekleniyor'), findsOneWidget);
    expect(find.text('İvme ölçer ve manyetometre verisi bekleniyor.'),
        findsOneWidget);
    expect(find.textContaining('Kıble: '), findsNothing);
  });

  testWidgets('location card shows Nevşehir by default', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpQibla(tester);

    expect(find.text('Konum bilgisi'), findsOneWidget);
    expect(find.text('Kıble hesabı Nevşehir konumuna göre yapılmaktadır.'),
        findsOneWidget);
  });

  testWidgets('use-location button is visible and invokes onLocate callback',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var invoked = false;
    await pumpQibla(
      tester,
      onLocate: () async {
        invoked = true;
      },
    );

    expect(find.text('Konum kullan'), findsOneWidget);

    await tester.tap(find.text('Konum kullan'));
    await tester.pump();

    expect(invoked, isTrue);
  });

  testWidgets('use-location button is hidden when coordinates are saved',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues(<String, Object>{
      'saved_city': 'İstanbul',
      'saved_latitude': 41.0082,
      'saved_longitude': 28.9784,
    });

    await pumpQibla(tester);

    expect(find.text('Konum kullan'), findsNothing);
    expect(find.text('Kıble hesabı İstanbul konumuna göre yapılmaktadır.'),
        findsOneWidget);
  });
}
