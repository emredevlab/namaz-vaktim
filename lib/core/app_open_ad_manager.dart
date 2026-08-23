import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// App Open reklamının yüklenmesini ve gösterilmesini yönetir.
///
/// Tüm hatalar sessizce yutulur; reklam başarısız olursa uygulama akışı
/// etkilenmez.
class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isLoaded = false;
  bool _isShowing = false;
  String? _lastAdUnitId;

  bool get isLoaded => _isLoaded;
  bool get isShowing => _isShowing;

  /// Karar mantığının test edilebilir saf hâli.
  static bool shouldShowOnResume({
    required bool adLoaded,
    required bool isShowing,
    required AppLifecycleState state,
  }) =>
      state == AppLifecycleState.resumed && adLoaded && !isShowing;

  void load(String adUnitId) {
    _lastAdUnitId = adUnitId;
    try {
      AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isLoaded = true;
          },
          onAdFailedToLoad: (error) {
            _isLoaded = false;
          },
        ),
      );
    } catch (_) {
      _isLoaded = false;
    }
  }

  void showIfAvailable() {
    if (!_isLoaded || _isShowing) return;
    final ad = _appOpenAd;
    if (ad == null) return;
    _isShowing = true;
    try {
      ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
        onAdDismissedFullScreenContent: (ad) => _onDismissed(ad),
        onAdFailedToShowFullScreenContent: (ad, error) => _onDismissed(ad),
      );
      ad.show();
    } catch (_) {
      _releaseAndReload();
    }
  }

  void _onDismissed(AppOpenAd ad) {
    try {
      ad.dispose();
    } catch (_) {}
    _releaseAndReload();
  }

  void _releaseAndReload() {
    _appOpenAd = null;
    _isLoaded = false;
    _isShowing = false;
    final id = _lastAdUnitId;
    if (id != null && id.isNotEmpty) load(id);
  }
}
