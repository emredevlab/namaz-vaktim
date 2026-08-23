import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/app_config.dart';
import '../../../../core/web_navigation_policy.dart';
import '../../prayer_models.dart';
import '../duas_screen.dart';
import '../location_picker_screen.dart';
import '../notification_settings_screen.dart';
import '../prayer_times_screen.dart';
import '../qibla_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer(
      {super.key, required this.config, required this.onLocationSelected});
  final AppConfig config;
  final Future<void> Function(UserLocation location) onLocationSelected;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  static const String _fallbackAppVersion = '1.1.0';

  late final Future<String> _appVersionFuture;

  @override
  void initState() {
    super.initState();
    _appVersionFuture = _loadAppVersion();
  }

  Future<String> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version.isEmpty
          ? _fallbackAppVersion
          : packageInfo.version;
    } catch (_) {
      return _fallbackAppVersion;
    }
  }

  @override
  Widget build(BuildContext context) => Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: widget.config.primaryColor),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: SvgPicture.asset(
                          widget.config.logoAsset,
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                          semanticsLabel: '${widget.config.name} logosu',
                          placeholderBuilder: (_) => const Icon(
                            Icons.mosque_outlined,
                            color: Color(0xFF0D6B5D),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(widget.config.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              ...widget.config.drawerItems.map((item) => ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    onTap: () {
                      Navigator.pop(context);
                      final Widget? destination = switch (item.route) {
                        '/prayer-times' =>
                          PrayerTimesScreen(config: widget.config),
                        '/qibla' => const QiblaScreen(),
                        '/location' => LocationPickerScreen(
                            onSelected: widget.onLocationSelected,
                          ),
                        '/prayers' => const DuasScreen(),
                        '/settings/notifications' =>
                          const NotificationSettingsScreen(),
                        _ => null,
                      };
                      if (destination != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => destination),
                        );
                      }
                    },
                  )),
              ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: const Text('Şehir seç'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationPickerScreen(
                        onSelected: widget.onLocationSelected,
                      ),
                    ),
                  );
                },
              ),
              if (widget.config.features['webContent'] ?? false)
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Web sitesini aç'),
                  onTap: () async {
                    Navigator.pop(context);
                    final uri =
                        Uri.tryParse(widget.config.endpoints.web.toString());
                    if (uri == null ||
                        const WebNavigationPolicy(allowedOrigins: {
                              'https://kapadokyabulut.com.tr',
                              'https://www.kapadokyabulut.com.tr',
                            }).decide(uri) !=
                            WebNavigationDecision.internal) {
                      return;
                    }
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Hakkında'),
                onTap: () async {
                  final appVersion = await _appVersionFuture;
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: widget.config.name,
                    applicationVersion: appVersion,
                    applicationLegalese: '© 2026 KapadokyaBulut',
                    applicationIcon: SvgPicture.asset(
                      widget.config.logoAsset,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      semanticsLabel: '${widget.config.name} logosu',
                      placeholderBuilder: (_) => const Icon(
                        Icons.mosque_outlined,
                        color: Color(0xFF0D6B5D),
                        size: 40,
                      ),
                    ),
                    children: const [
                      Text('Namaz vakitleri, kıble pusulası ve dualar'),
                      SizedBox(height: 8),
                      Text('Veriler: api.kapadokyabulut.com.tr'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
}
