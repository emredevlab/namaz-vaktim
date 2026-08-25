import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_providers.dart';
import '../../../config/app_config.dart';
import '../../../core/permission_manager.dart';
import '../../../shared/design/app_theme.dart';
import '../prayer_models.dart';
import '../religious_days.dart';
import 'notification_settings_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/location_card.dart';
import 'widgets/prayer_error.dart';
import 'widgets/prayer_times_grid.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({required this.config, super.key});
  final AppConfig config;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _loadingLocation = false;
  bool _bannerReady = false;
  BannerAd? _bannerAd;

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceLocation() async {
    setState(() => _loadingLocation = true);
    try {
      await DeviceLocationFlow(ref).loadFromDevice();
    } on LocationPermissionPermanentlyDeniedException {
      if (mounted) DeviceLocationFlow(ref).showSettingsPrompt(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // İzinler ilk kare render edildikten sonra istenir; açılış anında
    // istenirse sistem diyaloğu yutulabiliyor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestEntryPermissions();
    });
    Future<void>.microtask(() {
      ref.read(prayerControllerProvider).load();
      _restoreSavedLocation();
      if (widget.config.ads.enabled) {
        _bannerAd = BannerAd(
          adUnitId: widget.config.ads.bannerId,
          size: AdSize.banner,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: (ad) {
              if (mounted) setState(() => _bannerReady = true);
            },
            onAdFailedToLoad: (ad, _) => ad.dispose(),
          ),
        )..load();
      }
    });
  }

  /// Giriş akışı: bildirim izni -> konum izni -> pil optimizasyonu
  /// muafiyeti (sistem diyaloğu; ayar menüsüne gitmek gerekmez).
  /// Kanal yoksa (test ortamı) sessizce atlanır.
  Future<void> _requestEntryPermissions() async {
    await _ensureNotificationPermission();
    await _ensureLocationPermission();
    await _ensureBatteryExemption();
  }

  /// Android 13+ bildirim iznini yalnızca henüz verilmediyse ve bildirim
  /// özelliği config'te açıksa ister.
  Future<void> _ensureNotificationPermission() async {
    try {
      if (!(widget.config.features['notifications'] ?? false)) return;
      final manager = ref.read(permissionManagerProvider);
      var status = await manager.status(AppPermission.notification);
      if (status == PermissionStatus.granted) return;
      if (status == PermissionStatus.denied) {
        await manager.request(AppPermission.notification);
      }
    } catch (_) {
      // Platform kanalı yoksa (test) izin akışı sessizce atlanır.
    }
  }

  /// Konum izni girişte istenir; kalıcı reddedilmişse tekrar sorulmaz
  /// (kullanıcı konum butonundan ayarlara yönlendirilir).
  Future<void> _ensureLocationPermission() async {
    try {
      final manager = ref.read(permissionManagerProvider);
      var status = await manager.status(AppPermission.location);
      if (status != PermissionStatus.denied) return;
      await manager.request(AppPermission.location);
    } catch (_) {
      // Platform kanalı yoksa (test) izin akışı sessizce atlanır.
    }
  }

  /// Pil optimizasyonu muafiyeti: bildirimlerin Doze/üretici
  /// kısıtlamalarına takılmadan vaktinde gelmesini sağlar. Sistem
  /// diyaloğu tek dokunuşla onaylanır; zaten muaf ise sorulmaz.
  Future<void> _ensureBatteryExemption() async {
    try {
      final status = await ph.Permission.ignoreBatteryOptimizations.status;
      if (status.isGranted) return;
      await ph.Permission.ignoreBatteryOptimizations.request();
    } catch (_) {
      // Platform kanalı yoksa (test) sessizce atlanır.
    }
  }

  Future<void> _restoreSavedLocation() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final city = preferences.getString(DeviceLocationFlow.savedCityKey);
      if (city == null || !mounted) return;
      await ref.read(prayerControllerProvider).load(
            location: UserLocation(
              city: city,
              latitude: preferences
                  .getDouble(DeviceLocationFlow.savedLatitudeKey),
              longitude: preferences
                  .getDouble(DeviceLocationFlow.savedLongitudeKey),
            ),
          );
    } catch (_) {
      // Kayıtlı konum okunamazsa varsayılan Nevşehir konumu kullanılır.
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final prayerState = ref.watch(prayerControllerProvider).state;
    final prayerEnabled = config.features['prayerTimes'] ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
        actions: [
          if (config.features['notifications'] ?? false)
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen()),
              ),
              icon: const Icon(Icons.notifications_none),
              tooltip: 'Bildirim ayarları',
            )
        ],
      ),
      drawer: AppDrawer(
        config: config,
        onLocationSelected: (location) async {
          final preferences = await SharedPreferences.getInstance();
          await preferences.setString(
              DeviceLocationFlow.savedCityKey, location.city);
          if (location.latitude != null) {
            await preferences.setDouble(
                DeviceLocationFlow.savedLatitudeKey, location.latitude!);
          }
          if (location.longitude != null) {
            await preferences.setDouble(
                DeviceLocationFlow.savedLongitudeKey, location.longitude!);
          }
          if (mounted) {
            await ref.read(prayerControllerProvider).load(location: location);
          }
        },
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          LocationCard(
            config: config,
            data: prayerState.data,
            loadingLocation: _loadingLocation,
            onUseDeviceLocation: _loadDeviceLocation,
          ),
          if (prayerState.data != null) ...[
            const SizedBox(height: 12),
            SpecialDayBanner(
              content: specialContentFor(
                hijriMonth: prayerState.data!.hijriMonth,
                hijriDay: prayerState.data!.hijriDay,
                gregorianDate: DateTime.now(),
                // Kandil geceleri sabah namazıyla biter: gündüz geldiyse
                // banner gösterilmez.
                fajrTime: _imsakTimeOf(prayerState.data!),
              ),
            ),
          ],
          if (_bannerAd != null && _bannerReady) ...[
            const SizedBox(height: 12),
            SizedBox(height: 50, child: AdWidget(ad: _bannerAd!)),
          ],
          if (prayerEnabled) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Namaz Vakitleri',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                if (prayerState.data?.isFallback ?? false)
                  const Chip(
                    avatar: Icon(Icons.wifi_off, size: 16),
                    label: Text('Çevrimdışı'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (prayerState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (prayerState.error != null)
              PrayerError(
                message: prayerState.error!,
                onRetry: () => ref.read(prayerControllerProvider).load(),
              )
            else
              PrayerTimesGrid(data: prayerState.data),
          ],
        ],
      ),
    );
  }
}

/// HomeScreen ile PrayerTimesScreen'in paylaştığı cihaz konumu akışı:
/// izin kontrolü, konum okuma, kalıcı depoya kaydetme ve vakit yükleme.
final class DeviceLocationFlow {
  DeviceLocationFlow(this._ref);

  final WidgetRef _ref;

  static const savedCityKey = 'saved_city';
  static const savedLatitudeKey = 'saved_latitude';
  static const savedLongitudeKey = 'saved_longitude';

  Future<void> loadFromDevice() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Konum servisi kapalı.');
    }
    final manager = _ref.read(permissionManagerProvider);
    var status = await manager.status(AppPermission.location);
    if (status == PermissionStatus.denied) {
      status = await manager.request(AppPermission.location);
    }
    if (status == PermissionStatus.permanentlyDenied) {
      throw const LocationPermissionPermanentlyDeniedException();
    }
    if (status != PermissionStatus.granted) {
      throw StateError('Konum izni verilmedi.');
    }
    final position = await Geolocator.getCurrentPosition();
    final city = await resolveCityName(position.latitude, position.longitude) ??
        'Mevcut konum';
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(savedCityKey, city);
    await preferences.setDouble(savedLatitudeKey, position.latitude);
    await preferences.setDouble(savedLongitudeKey, position.longitude);
    await _ref.read(prayerControllerProvider).load(
          location: UserLocation(
            city: city,
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
  }

  /// GPS koordinatlarını ters geocoding ile şehir adına çözer; ilk
  /// placemark'ın sırasıyla locality, subAdministrativeArea ve
  /// administrativeArea değerlerinden boş olmayan ilki döner.
  /// Sonuç yoksa (çevrimdışı/servis yok/hata) null döner.
  static Future<String?> resolveCityName(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks =
          await Geocoding().placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      final placemark = placemarks.first;
      for (final candidate in <String?>[
        placemark.locality,
        placemark.subAdministrativeArea,
        placemark.administrativeArea,
      ]) {
        if (candidate != null && candidate.trim().isNotEmpty) {
          return candidate;
        }
      }
      return null;
    } catch (_) {
      // Geocoding servisi kullanılamazsa çağıran taraf yedek ismi kullanır.
      return null;
    }
  }

  /// Kalıcı olarak reddedilen konum izni için kullanıcıyı sistem
  /// ayarlarına yönlendiren SnackBar gösterir.
  void showSettingsPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          const PermissionRationalePolicy()
              .permanentlyDeniedMessage(AppPermission.location),
        ),
        action: SnackBarAction(
          label: 'Ayarları Aç',
          onPressed: openPermissionSettings,
        ),
      ),
    );
  }

  Future<bool> openPermissionSettings() =>
      _ref.read(permissionManagerProvider).openSettings();
}

final class LocationPermissionPermanentlyDeniedException implements Exception {
  const LocationPermissionPermanentlyDeniedException();
}

/// Bugünün imsak vakti; kandil banner'ı sabahla birlikte kapanır.
DateTime? _imsakTimeOf(DailyPrayerTimes data) {
  for (final time in data.times) {
    if (time.type == PrayerType.imsak) return time.dateTime;
  }
  return null;
}

/// Dini gün / Cuma banner'ı: altın gradient kart, dokununca tam dua açılır.
class SpecialDayBanner extends StatelessWidget {
  const SpecialDayBanner({super.key, required this.content});

  final SpecialDayContent? content;

  void _showDuaSheet(BuildContext context) {
    final special = content!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? AppTheme.cream : AppTheme.primaryDeep;
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppTheme.darkCard : Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(sheetContext).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(specialDayIcon(special), color: AppTheme.gold, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    special.title,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              special.message,
              style: TextStyle(
                  color: onSurface.withValues(alpha: .85), fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.gold : AppTheme.primary)
                    .withValues(alpha: .1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: .4),
                ),
              ),
              child: Text(
                special.dua,
                style: TextStyle(
                  color: isDark ? AppTheme.goldSoft : AppTheme.primary,
                  fontSize: 14.5,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Âmin'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final special = content;
    if (special == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _showDuaSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.gold.withValues(alpha: .3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(specialDayIcon(special),
                color: AppTheme.primaryDeep, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    special.title,
                    style: const TextStyle(
                      color: AppTheme.primaryDeep,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    special.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.primaryDeep.withValues(alpha: .8),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.primaryDeep),
          ],
        ),
      ),
    );
  }
}
