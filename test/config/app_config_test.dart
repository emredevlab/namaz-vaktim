import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_vaktim/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production asset loads and validates', () async {
    final config = await AppConfigLoader(rootBundle).load();
    expect(config.name, 'Namaz Vaktim');
    expect(config.drawerItems, hasLength(5));
    expect(config.ads.androidAppId,
        'ca-app-pub-3940256099942544~3347511713');
    expect(const AppConfigValidator().validate(config), isEmpty);
  });

  test('validator reports unsafe endpoints and missing drawer entries', () {
    final base = AppConfig.production;
    final invalid = AppConfig(
      brand: BrandConfig(
        name: base.name,
        website: Uri.parse('http://example.com'),
        primaryColor: base.primaryColor,
        logoAsset: base.logoAsset,
      ),
      endpoints: EndpointConfig(
        api: Uri.parse('http://api.example.com'),
        web: Uri.parse('http://example.com'),
      ),
      ads: base.ads,
      drawerItems: const [],
      features: base.features,
    );

    final errors = const AppConfigValidator().validate(invalid);

    expect(errors, contains('brand.website HTTPS olmalıdır.'));
    expect(errors, contains('endpoints.api HTTPS olmalıdır.'));
    expect(errors, contains('endpoints.web HTTPS olmalıdır.'));
    expect(errors, contains('En az bir drawer girdisi zorunludur.'));
  });

  test('drawer icon falls back for unknown icon names', () {
    final item = DrawerItemConfig.fromJson(const {
      'title': 'Bilinmeyen',
      'route': '/unknown',
      'icon': 'not_registered',
    });
    expect(item.icon, Icons.article_outlined);
  });

  test('validator rejects invalid androidAppId when ads enabled', () {
    const validator = AppConfigValidator();
    final base = AppConfig.production;

    AppConfig withAppId(String androidAppId) => AppConfig(
          brand: base.brand,
          endpoints: base.endpoints,
          ads: AdConfig(
            enabled: true,
            appOpenId: base.ads.appOpenId,
            bannerId: base.ads.bannerId,
            androidAppId: androidAppId,
          ),
          drawerItems: base.drawerItems,
          features: base.features,
        );

    final error =
        'ads.androidAppId geçerli bir AdMob uygulama kimliği olmalıdır.';

    expect(validator.validate(withAppId('')), contains(error));
    expect(validator.validate(withAppId('invalid-id')), contains(error));
    expect(
        validator.validate(withAppId('ca-app-pub-3940256099942544~3347511713')),
        isNot(contains(error)));
  });
}
