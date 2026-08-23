import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/app_config.dart';
import '../../../../core/web_navigation_policy.dart';
import '../../prayer_models.dart';
import '../duas_screen.dart';
import '../location_picker_screen.dart';
import '../notification_settings_screen.dart';
import '../prayer_times_screen.dart';
import '../qibla_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer(
      {super.key, required this.config, required this.onLocationSelected});
  final AppConfig config;
  final Future<void> Function(UserLocation location) onLocationSelected;

  @override
  Widget build(BuildContext context) => Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: config.primaryColor),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: SvgPicture.asset(
                          config.logoAsset,
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                          semanticsLabel: '${config.name} logosu',
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
                      child: Text(config.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              ...config.drawerItems.map((item) => ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    onTap: () {
                      Navigator.pop(context);
                      final Widget? destination = switch (item.route) {
                        '/prayer-times' => PrayerTimesScreen(config: config),
                        '/qibla' => const QiblaScreen(),
                        '/location' => LocationPickerScreen(
                            onSelected: onLocationSelected,
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
                        onSelected: onLocationSelected,
                      ),
                    ),
                  );
                },
              ),
              if (config.features['webContent'] ?? false)
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Web sitesini aç'),
                  onTap: () async {
                    Navigator.pop(context);
                    final uri = Uri.tryParse(config.endpoints.web.toString());
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
                onTap: () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: config.name,
                    applicationVersion: '1.1.0',
                    applicationLegalese: '© 2026 KapadokyaBulut',
                    applicationIcon: SvgPicture.asset(
                      config.logoAsset,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      semanticsLabel: '${config.name} logosu',
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
