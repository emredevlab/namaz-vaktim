import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../config/app_config.dart';
import '../../../shared/design/app_theme.dart';
import '../../../shared/formatting.dart';
import '../prayer_models.dart';
import 'home_screen.dart';
import 'widgets/prayer_error.dart';

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({required this.config, super.key});

  final AppConfig config;

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  bool _loadingLocation = false;

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
  Widget build(BuildContext context) {
    final state = ref.watch(prayerControllerProvider).state;
    final data = state.data;
    final tomorrow = state.tomorrow;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Vakitleri'),
        actions: [
          IconButton(
            tooltip: 'Vakitleri yenile',
            onPressed: state.isLoading
                ? null
                : () => ref.read(prayerControllerProvider).load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(prayerControllerProvider).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          children: [
            _buildHeroHeader(data),
            if (data?.isFallback ?? false) ...[
              const SizedBox(height: 14),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Örnek vakitler gösteriliyor'),
                  subtitle: Text(
                      'Sunucuya ulaşılamadı; örnek (Nevşehir) vakitler gösteriliyor. Sunucu erişilebilir olduğunda yenilemek için aşağı çekin.'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (state.isLoading && data == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && data == null)
              PrayerError(
                message: state.error!,
                onRetry: () => ref.read(prayerControllerProvider).load(),
              )
            else
              ...?data?.times.map(
                (item) => _buildPrayerTile(
                  item,
                  next: data.next,
                  compact: false,
                  isDark: isDark,
                ),
              ),
            if (tomorrow != null) ...[
              const SizedBox(height: 26),
              _buildGoldSectionTitle(context, 'Yarın'),
              const SizedBox(height: 12),
              ...tomorrow.times.map(
                (item) => _buildPrayerTile(
                  item,
                  next: null,
                  compact: true,
                  isDark: isDark,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Vakitler bulunduğunuz şehir ve yerel saat dilimine göre gösterilir. İnternet bağlantısı olmadığında son başarılı sonuç ekranda kalır.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// AppBar altındaki ince gradient şerit: konum, bugünün tarihi,
  /// çevrimdışı rozeti ve cihaz konumu kısayolu.
  Widget _buildHeroHeader(DailyPrayerTimes? data) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: .30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_outlined,
                    color: AppTheme.goldSoft, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data?.location.city ?? 'Nevşehir',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          formatPrayerDate(data?.date ?? DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .75),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (data?.isFallback ?? false) ...[
                          const SizedBox(width: 8),
                          const _OfflineBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadingLocation ? null : _loadDeviceLocation,
                tooltip: 'Mevcut konumu kullan',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .14),
                ),
                color: Colors.white,
                icon: _loadingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Altın vurgulu bölüm başlığı: ince gradient çubuk + başlık.
  Widget _buildGoldSectionTitle(BuildContext context, String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  /// Ana ekrandaki tile diline yakın vakit satırı: sıradaki vakte altın
  /// çerçeve + gradient, diğerlerine yumuşak kart yüzeyi.
  Widget _buildPrayerTile(
    PrayerTime item, {
    required PrayerTime? next,
    required bool compact,
    required bool isDark,
  }) {
    final isNext = next?.type == item.type;
    final onCard = isDark ? AppTheme.cream : AppTheme.primaryDeep;
    final iconSize = compact ? 38.0 : 44.0;
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 9 : 13,
      ),
      decoration: BoxDecoration(
        gradient: isNext ? AppTheme.nextTileGradient : null,
        color:
            isNext ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(
          color: isNext
              ? AppTheme.gold.withValues(alpha: .75)
              : (isDark
                  ? Colors.white.withValues(alpha: .06)
                  : AppTheme.primary.withValues(alpha: .08)),
          width: isNext ? 1.4 : 1,
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: .28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              gradient: isNext ? AppTheme.goldGradient : null,
              color: isNext
                  ? null
                  : (isDark
                      ? Colors.white.withValues(alpha: .07)
                      : AppTheme.primary.withValues(alpha: .09)),
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
            ),
            child: Icon(
              prayerIcon(item.type),
              size: compact ? 19 : 22,
              color: isNext
                  ? AppTheme.primaryDeep
                  : (isDark ? AppTheme.goldSoft : AppTheme.primary),
            ),
          ),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayerTypeLabel(item.type),
                  style: TextStyle(
                    color: isNext ? Colors.white : onCard,
                    fontSize: compact ? 15 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Sıradaki vakit',
                    style: TextStyle(
                      color: AppTheme.goldSoft,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            formatPrayerTime(item.dateTime),
            style: TextStyle(
              color: isNext ? AppTheme.goldSoft : onCard.withValues(alpha: .85),
              fontSize: compact ? 17 : 19,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient şeritteki 'Örnek veri' rozeti.
class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withValues(alpha: .45)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 11, color: AppTheme.goldSoft),
          SizedBox(width: 4),
          Text(
            'Örnek veri',
            style: TextStyle(
              color: AppTheme.goldSoft,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ],
      ),
    );
  }
}
