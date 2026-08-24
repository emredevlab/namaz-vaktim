import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/app_config.dart';
import '../../../../core/web_navigation_policy.dart';
import '../../../../shared/design/app_theme.dart';
import '../../prayer_models.dart';
import '../duas_screen.dart';
import '../location_picker_screen.dart';
import '../notification_settings_screen.dart';
import '../religious_calendar_screen.dart';
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
  String _activeRoute = '/';

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
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  ...widget.config.drawerItems.map((item) => _buildNavItem(
                        icon: item.icon,
                        title: item.title,
                        isActive: _activeRoute == item.route,
                        onTap: () {
                          setState(() => _activeRoute = item.route);
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
                  _buildNavItem(
                    icon: Icons.location_city_outlined,
                    title: 'Şehir seç',
                    isActive: _activeRoute == '/location',
                    onTap: () {
                      setState(() => _activeRoute = '/location');
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
                    _buildNavItem(
                      icon: Icons.language,
                      title: 'Web sitesini aç',
                      onTap: () async {
                        Navigator.pop(context);
                        final uri = Uri.tryParse(
                            widget.config.endpoints.web.toString());
                        if (uri == null ||
                            const WebNavigationPolicy(allowedOrigins: {
                                  'https://kapadokyabulut.com.tr',
                                  'https://www.kapadokyabulut.com.tr',
                                }).decide(uri) !=
                                WebNavigationDecision.internal) {
                          return;
                        }
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      },
                    ),
                  _buildNavItem(
                    icon: Icons.calendar_month_outlined,
                    title: 'Dini Takvim',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReligiousCalendarScreen(),
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.info_outline,
                    title: 'Hakkında',
                    onTap: () async {
                      final appVersion = await _appVersionFuture;
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _showAboutSheet(context, appVersion);
                    },
                  ),
                ],
              ),
            ),
            _buildVersionFooter(),
          ],
        ),
      ),
    );
  }

  /// Gradient başlık: heroGradient + logoyu saran altın halka.
  Widget _buildHeader() {
    return DrawerHeader(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: .45),
                  blurRadius: 14,
                ),
              ],
            ),
            child: CircleAvatar(
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
                    color: AppTheme.primary,
                    size: 32,
                  ),
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
                    fontWeight: FontWeight.bold,
                    letterSpacing: -.3)),
          ),
        ],
      ),
    );
  }

  /// Yuvarlak zümrüt kutulu ikon; aktif rota altın gradient kutu alır.
  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: isActive ? AppTheme.goldGradient : null,
            color: isActive
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: .07)
                    : AppTheme.primary.withValues(alpha: .09)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            size: 21,
            color: isActive
                ? AppTheme.primaryDeep
                : (isDark ? AppTheme.goldSoft : AppTheme.primary),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color:
                isActive ? (isDark ? AppTheme.goldSoft : AppTheme.primaryDeep) : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  /// Listenin altında sabit duran ince sürüm yazısı.
  Widget _buildVersionFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(indent: 64, endIndent: 64, height: 1),
          const SizedBox(height: 10),
          FutureBuilder<String>(
            future: _appVersionFuture,
            builder: (context, snapshot) {
              final version = snapshot.data ?? _fallbackAppVersion;
              return Text(
                'KapadokyaBulut • v$version',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(letterSpacing: .4),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Hakkında diyaloğu: kısa, öz; lisans listesi yok.
  void _showAboutSheet(BuildContext context, String appVersion) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? AppTheme.cream : AppTheme.primaryDeep;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            isDark ? AppTheme.darkCard : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                widget.config.logoAsset,
                width: 52,
                height: 52,
                fit: BoxFit.contain,
                semanticsLabel: '${widget.config.name} logosu',
                placeholderBuilder: (_) => const Icon(
                  Icons.mosque_outlined,
                  color: AppTheme.primaryDeep,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.config.name,
              style: TextStyle(
                color: onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'v$appVersion',
              style: TextStyle(
                color: onSurface.withValues(alpha: .55),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Namaz vakitleri, kıble pusulası ve dualar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withValues(alpha: .8),
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.gold : AppTheme.primary)
                    .withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Vakit verileri: Aladhan.com\nDiyanet İşleri hesap yöntemi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: isDark ? AppTheme.goldSoft : AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Powered by Emre',
              style: TextStyle(
                color: onSurface.withValues(alpha: .6),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Kapat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
