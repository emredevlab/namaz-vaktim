import 'package:flutter/material.dart';

import '../../../shared/design/app_theme.dart';
import '../prayer_models.dart';

String _normalizeCityQuery(String value) => value
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .replaceAll('ı', 'i')
    .toLowerCase();

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({required this.onSelected, super.key});
  final Future<void> Function(UserLocation location) onSelected;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _cities = <UserLocation>[
    UserLocation(city: 'Adana', latitude: 37.0000, longitude: 35.3213),
    UserLocation(city: 'Adıyaman', latitude: 37.7648, longitude: 38.2786),
    UserLocation(city: 'Afyonkarahisar', latitude: 38.7507, longitude: 30.5567),
    UserLocation(city: 'Ağrı', latitude: 39.7191, longitude: 43.0503),
    UserLocation(city: 'Aksaray', latitude: 38.3687, longitude: 34.0370),
    UserLocation(city: 'Amasya', latitude: 40.6499, longitude: 35.8353),
    UserLocation(city: 'Ankara', latitude: 39.9334, longitude: 32.8597),
    UserLocation(city: 'Antalya', latitude: 36.8969, longitude: 30.7133),
    UserLocation(city: 'Ardahan', latitude: 41.1105, longitude: 42.7022),
    UserLocation(city: 'Artvin', latitude: 41.1828, longitude: 41.8183),
    UserLocation(city: 'Aydın', latitude: 37.8560, longitude: 27.8416),
    UserLocation(city: 'Balıkesir', latitude: 39.6484, longitude: 27.8826),
    UserLocation(city: 'Bartın', latitude: 41.6344, longitude: 32.3375),
    UserLocation(city: 'Batman', latitude: 37.8812, longitude: 41.1351),
    UserLocation(city: 'Bayburt', latitude: 40.2552, longitude: 40.2249),
    UserLocation(city: 'Bilecik', latitude: 40.1426, longitude: 29.9793),
    UserLocation(city: 'Bingöl', latitude: 38.8854, longitude: 40.4983),
    UserLocation(city: 'Bitlis', latitude: 38.4006, longitude: 42.1095),
    UserLocation(city: 'Bolu', latitude: 40.7392, longitude: 31.6089),
    UserLocation(city: 'Burdur', latitude: 37.7203, longitude: 30.2908),
    UserLocation(city: 'Bursa', latitude: 40.1950, longitude: 29.0600),
    UserLocation(city: 'Çanakkale', latitude: 40.1553, longitude: 26.4142),
    UserLocation(city: 'Çankırı', latitude: 40.6013, longitude: 33.6134),
    UserLocation(city: 'Çorum', latitude: 40.5506, longitude: 34.9556),
    UserLocation(city: 'Denizli', latitude: 37.7765, longitude: 29.0864),
    UserLocation(city: 'Diyarbakır', latitude: 37.9144, longitude: 40.2306),
    UserLocation(city: 'Düzce', latitude: 40.8438, longitude: 31.1565),
    UserLocation(city: 'Edirne', latitude: 41.6818, longitude: 26.5623),
    UserLocation(city: 'Elazığ', latitude: 38.6810, longitude: 39.2264),
    UserLocation(city: 'Erzincan', latitude: 39.7500, longitude: 39.5000),
    UserLocation(city: 'Erzurum', latitude: 39.9000, longitude: 41.2700),
    UserLocation(city: 'Eskişehir', latitude: 39.7767, longitude: 30.5206),
    UserLocation(city: 'Gaziantep', latitude: 37.0662, longitude: 37.3833),
    UserLocation(city: 'Giresun', latitude: 40.9128, longitude: 38.3895),
    UserLocation(city: 'Gümüşhane', latitude: 40.4386, longitude: 39.5086),
    UserLocation(city: 'Hakkari', latitude: 37.5833, longitude: 43.7333),
    UserLocation(city: 'Hatay', latitude: 36.2025, longitude: 36.1606),
    UserLocation(city: 'Iğdır', latitude: 39.9208, longitude: 44.0448),
    UserLocation(city: 'Isparta', latitude: 37.7648, longitude: 30.5566),
    UserLocation(city: 'İstanbul', latitude: 41.0082, longitude: 28.9784),
    UserLocation(city: 'İzmir', latitude: 38.4237, longitude: 27.1428),
    UserLocation(city: 'Kahramanmaraş', latitude: 37.5858, longitude: 36.9371),
    UserLocation(city: 'Karabük', latitude: 41.2061, longitude: 32.6204),
    UserLocation(city: 'Karaman', latitude: 37.1759, longitude: 33.2287),
    UserLocation(city: 'Kars', latitude: 40.6013, longitude: 43.0975),
    UserLocation(city: 'Kastamonu', latitude: 41.3887, longitude: 33.7827),
    UserLocation(city: 'Kayseri', latitude: 38.7225, longitude: 35.4875),
    UserLocation(city: 'Kırıkkale', latitude: 39.8468, longitude: 33.5153),
    UserLocation(city: 'Kırklareli', latitude: 41.7333, longitude: 27.2167),
    UserLocation(city: 'Kırşehir', latitude: 39.1425, longitude: 34.1709),
    UserLocation(city: 'Kilis', latitude: 36.7184, longitude: 37.1212),
    UserLocation(city: 'Kocaeli', latitude: 40.8533, longitude: 29.8815),
    UserLocation(city: 'Konya', latitude: 37.8746, longitude: 32.4932),
    UserLocation(city: 'Kütahya', latitude: 39.4242, longitude: 29.9833),
    UserLocation(city: 'Malatya', latitude: 38.3552, longitude: 38.3095),
    UserLocation(city: 'Manisa', latitude: 38.6191, longitude: 27.4289),
    UserLocation(city: 'Mardin', latitude: 37.3212, longitude: 40.7245),
    UserLocation(city: 'Mersin', latitude: 36.8000, longitude: 34.6333),
    UserLocation(city: 'Muğla', latitude: 37.2153, longitude: 28.3636),
    UserLocation(city: 'Muş', latitude: 38.7432, longitude: 41.5064),
    UserLocation(city: 'Nevşehir', latitude: 38.6244, longitude: 34.7239),
    UserLocation(city: 'Niğde', latitude: 37.9667, longitude: 34.6833),
    UserLocation(city: 'Ordu', latitude: 40.9839, longitude: 37.8764),
    UserLocation(city: 'Osmaniye', latitude: 37.0742, longitude: 36.2478),
    UserLocation(city: 'Rize', latitude: 41.0201, longitude: 40.5234),
    UserLocation(city: 'Sakarya', latitude: 40.7569, longitude: 30.3783),
    UserLocation(city: 'Samsun', latitude: 41.2867, longitude: 36.3300),
    UserLocation(city: 'Siirt', latitude: 37.9333, longitude: 41.9500),
    UserLocation(city: 'Sinop', latitude: 42.0231, longitude: 35.1531),
    UserLocation(city: 'Sivas', latitude: 39.7477, longitude: 37.0179),
    UserLocation(city: 'Şanlıurfa', latitude: 37.1591, longitude: 38.7969),
    UserLocation(city: 'Şırnak', latitude: 37.4187, longitude: 42.4918),
    UserLocation(city: 'Tekirdağ', latitude: 40.9833, longitude: 27.5167),
    UserLocation(city: 'Tokat', latitude: 40.3167, longitude: 36.5544),
    UserLocation(city: 'Trabzon', latitude: 41.0015, longitude: 39.7178),
    UserLocation(city: 'Tunceli', latitude: 39.1079, longitude: 39.5401),
    UserLocation(city: 'Uşak', latitude: 38.6823, longitude: 29.4082),
    UserLocation(city: 'Van', latitude: 38.4891, longitude: 43.4089),
    UserLocation(city: 'Yalova', latitude: 40.6500, longitude: 29.2667),
    UserLocation(city: 'Yozgat', latitude: 39.8181, longitude: 34.8147),
    UserLocation(city: 'Zonguldak', latitude: 41.4564, longitude: 31.7987),
  ];

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final needle = _normalizeCityQuery(_query);
    final filtered = needle.isEmpty
        ? _cities
        : _cities
            .where((location) =>
                _normalizeCityQuery(location.city).contains(needle))
            .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Şehir seç')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Şehir ara',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Şehir bulunamadı'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) return const _CityInfoBanner();
                      final location = filtered[index - 1];
                      return _CityTile(
                        location: location,
                        onTap: () async {
                          await widget.onSelected(location);
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CityInfoBanner extends StatelessWidget {
  const _CityInfoBanner();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: .35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_city,
                  color: AppTheme.goldSoft, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Vakitler seçtiğin şehre göre gösterilir',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .95),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

class _CityTile extends StatelessWidget {
  const _CityTile({required this.location, required this.onTap});

  final UserLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              location.city[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          title: Text(
            location.city,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${location.latitude!.toStringAsFixed(3)}, ${location.longitude!.toStringAsFixed(3)}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: onTap,
        ),
      );
}
