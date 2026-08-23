import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:kapadokya_mobile_core/kapadokya_mobile_core.dart';

Color _parseColor(String value) =>
    Color(int.parse(value.replaceFirst('#', '0xFF')));

const _drawerIcons = <String, IconData>{
  'home': Icons.home_outlined,
  'schedule': Icons.access_time_outlined,
  'explore': Icons.explore_outlined,
  'menu_book': Icons.menu_book_outlined,
  'notifications': Icons.notifications_outlined,
};

@immutable
class BrandConfig {
  const BrandConfig(
      {required this.name,
      required this.website,
      required this.primaryColor,
      required this.logoAsset});
  final String name;
  final Uri website;
  final Color primaryColor;
  final String logoAsset;

  factory BrandConfig.fromJson(Map<String, dynamic> json) => BrandConfig(
        name: json['name'] as String,
        website: Uri.parse(json['website'] as String),
        primaryColor: _parseColor(json['primaryColor'] as String),
        logoAsset: json['logoAsset'] as String,
      );
}

@immutable
class EndpointConfig {
  const EndpointConfig({required this.api, required this.web});
  final Uri api;
  final Uri web;

  factory EndpointConfig.fromJson(Map<String, dynamic> json) => EndpointConfig(
        api: Uri.parse(json['api'] as String),
        web: Uri.parse(json['web'] as String),
      );
}

@immutable
class AdConfig {
  const AdConfig(
      {required this.enabled,
      required this.appOpenId,
      required this.bannerId,
      this.androidAppId = ''});
  final bool enabled;
  final String appOpenId;
  final String bannerId;
  final String androidAppId;

  factory AdConfig.fromJson(Map<String, dynamic> json) => AdConfig(
        enabled: json['enabled'] as bool,
        appOpenId: json['appOpenId'] as String,
        bannerId: json['bannerId'] as String,
        androidAppId: json['androidAppId'] as String? ?? '',
      );
}

@immutable
class DrawerItemConfig {
  const DrawerItemConfig(
      {required this.title, required this.route, required this.icon});
  final String title;
  final String route;
  final IconData icon;

  factory DrawerItemConfig.fromJson(Map<String, dynamic> json) =>
      DrawerItemConfig(
        title: json['title'] as String,
        route: json['route'] as String,
        icon: _drawerIcons[json['icon'] as String] ?? Icons.article_outlined,
      );
}

@immutable
class AppConfig {
  const AppConfig(
      {required this.brand,
      required this.endpoints,
      required this.ads,
      required this.drawerItems,
      required this.features});
  final BrandConfig brand;
  final EndpointConfig endpoints;
  final AdConfig ads;
  final List<DrawerItemConfig> drawerItems;
  final Map<String, bool> features;

  String get name => brand.name;
  Color get primaryColor => brand.primaryColor;
  String get logoAsset => brand.logoAsset;
  CoreConfiguration get core => CoreConfiguration(
      applicationName: name, websiteUri: brand.website, apiUri: endpoints.api);

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        brand: BrandConfig.fromJson(json['brand'] as Map<String, dynamic>),
        endpoints:
            EndpointConfig.fromJson(json['endpoints'] as Map<String, dynamic>),
        ads: AdConfig.fromJson(json['ads'] as Map<String, dynamic>),
        drawerItems: (json['drawerItems'] as List<dynamic>)
            .map((item) =>
                DrawerItemConfig.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        features: Map<String, bool>.unmodifiable(
          (json['features'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, value as bool)),
        ),
      );

  static final production = AppConfig(
    brand: BrandConfig(
      name: 'Namaz Vaktim',
      website: Uri.parse('https://kapadokyabulut.com.tr'),
      primaryColor: const Color(0xFF0D6B5D),
      logoAsset: 'assets/config/namaz_vaktim_logo.svg',
    ),
    endpoints: EndpointConfig(
      api: Uri.parse('https://api.kapadokyabulut.com.tr'),
      web: Uri.parse('https://kapadokyabulut.com.tr'),
    ),
    ads: const AdConfig(
        enabled: true,
        appOpenId: 'ca-app-pub-3940256099942544/9257395921',
        bannerId: 'ca-app-pub-3940256099942544/6300978111',
        androidAppId: 'ca-app-pub-3940256099942544~3347511713'),
    drawerItems: const [
      DrawerItemConfig(
          title: 'Ana Sayfa', route: '/', icon: Icons.home_outlined),
      DrawerItemConfig(
          title: 'Namaz Vakitleri',
          route: '/prayer-times',
          icon: Icons.access_time_outlined),
      DrawerItemConfig(
          title: 'Kıble', route: '/qibla', icon: Icons.explore_outlined),
      DrawerItemConfig(
          title: 'Dualar', route: '/prayers', icon: Icons.menu_book_outlined),
      DrawerItemConfig(
          title: 'Bildirim Ayarları',
          route: '/settings/notifications',
          icon: Icons.notifications_outlined),
    ],
    features: const {
      'prayerTimes': true,
      'notifications': true,
      'webContent': true
    },
  );
}

class AppConfigLoader {
  const AppConfigLoader(this.assetBundle,
      {AppLogger logger = const ConsoleLogger()})
      : _logger = logger;
  final AssetBundle assetBundle;
  final AppLogger _logger;

  Future<AppConfig> load(
      {String assetPath = 'assets/config/app.production.json'}) async {
    try {
      final raw = await assetBundle.loadString(assetPath);
      return AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error, stackTrace) {
      _logger.error(
        'Uygulama yapılandırması yüklenemedi',
        error,
        stackTrace,
        metadata: {'asset': assetPath},
      );
      if (assetPath == 'assets/config/app.production.json') {
        return AppConfig.production;
      }
      rethrow;
    }
  }
}

class AppConfigValidator {
  const AppConfigValidator();

  List<String> validate(AppConfig config) {
    final errors = <String>[];
    if (config.name.trim().isEmpty) errors.add('brand.name zorunludur.');
    if (config.brand.website.scheme != 'https') {
      errors.add('brand.website HTTPS olmalıdır.');
    }
    if (config.endpoints.api.scheme != 'https') {
      errors.add('endpoints.api HTTPS olmalıdır.');
    }
    if (config.endpoints.web.scheme != 'https') {
      errors.add('endpoints.web HTTPS olmalıdır.');
    }
    if (config.brand.logoAsset.trim().isEmpty) {
      errors.add('brand.logoAsset zorunludur.');
    }
    if (config.ads.enabled &&
        (config.ads.appOpenId.trim().isEmpty ||
            config.ads.bannerId.trim().isEmpty)) {
      errors.add('Aktif reklam kimlikleri zorunludur.');
    }
    if (config.ads.enabled &&
        !config.ads.androidAppId.startsWith('ca-app-pub-')) {
      errors.add('ads.androidAppId geçerli bir AdMob uygulama kimliği olmalıdır.');
    }
    if (config.drawerItems.isEmpty) {
      errors.add('En az bir drawer girdisi zorunludur.');
    }
    for (final item in config.drawerItems) {
      if (item.title.trim().isEmpty || !item.route.startsWith('/')) {
        errors.add('Geçersiz drawer girdisi: ${item.route}');
      }
    }
    errors.addAll(config.core.validate());
    return errors.toSet().toList(growable: false);
  }
}
