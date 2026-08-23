import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_providers.dart';
import '../../../config/app_config.dart';
import '../../../core/permission_manager.dart';
import '../prayer_models.dart';
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
  static const _savedCityKey = 'saved_city';
  static const _savedLatitudeKey = 'saved_latitude';
  static const _savedLongitudeKey = 'saved_longitude';
  bool _loadingLocation = false;
  BannerAd? _bannerAd;

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceLocation() async {
    setState(() => _loadingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Konum servisi kapalı.');
      }
      final manager = ref.read(permissionManagerProvider);
      var status = await manager.status(AppPermission.location);
      if (status == PermissionStatus.denied) {
        status = await manager.request(AppPermission.location);
      }
      if (status != PermissionStatus.granted) {
        throw StateError('Konum izni verilmedi.');
      }
      final position = await Geolocator.getCurrentPosition();
      final location = UserLocation(
        city: 'Mevcut konum',
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_savedCityKey, location.city);
      await preferences.setDouble(_savedLatitudeKey, position.latitude);
      await preferences.setDouble(_savedLongitudeKey, position.longitude);
      await ref.read(prayerControllerProvider).load(location: location);
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
    Future<void>.microtask(() {
      ref.read(prayerControllerProvider).load();
      _restoreSavedLocation();
      if (widget.config.ads.enabled) {
        _bannerAd = BannerAd(
          adUnitId: widget.config.ads.bannerId,
          size: AdSize.banner,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdFailedToLoad: (ad, _) => ad.dispose(),
          ),
        )..load();
      }
    });
  }

  Future<void> _restoreSavedLocation() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final city = preferences.getString(_savedCityKey);
      if (city == null || !mounted) return;
      await ref.read(prayerControllerProvider).load(
            location: UserLocation(
              city: city,
              latitude: preferences.getDouble(_savedLatitudeKey),
              longitude: preferences.getDouble(_savedLongitudeKey),
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
          await preferences.setString(_savedCityKey, location.city);
          if (location.latitude != null) {
            await preferences.setDouble(_savedLatitudeKey, location.latitude!);
          }
          if (location.longitude != null) {
            await preferences.setDouble(
                _savedLongitudeKey, location.longitude!);
          }
          if (mounted) {
            await ref.read(prayerControllerProvider).load(location: location);
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LocationCard(
            config: config,
            data: prayerState.data,
            loadingLocation: _loadingLocation,
            onUseDeviceLocation: _loadDeviceLocation,
          ),
          if (_bannerAd != null) ...[
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
