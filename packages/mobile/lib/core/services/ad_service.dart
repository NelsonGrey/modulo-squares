import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:modulo/core/services/analytics_service.dart';
import 'package:modulo/core/services/consent_service.dart';
import 'package:modulo/core/services/purchase_service.dart';
import 'package:modulo/core/di/service_locator.dart';
import 'package:modulo/core/config/admob_config.dart';
import 'package:modulo/core/services/error_handler.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // Public constructor for dependency injection
  factory AdService() => instance;

  InterstitialAd? _interstitial;
  bool _isLoading = false;

  // Get analytics service from dependency injection
  AnalyticsService get _analyticsService => getIt<AnalyticsService>();

  // Get purchase service from dependency injection
  PurchaseService get _purchaseService => getIt<PurchaseService>();

  Future<InitializationStatus> initialize() async {
    return MobileAds.instance.initialize();
  }

  String get _interstitialId => AdMobConfig.interstitialId;

  void loadInterstitial() {
    if (_isLoading || _interstitial != null) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: AdRequest(
        nonPersonalizedAds: !getIt<ConsentService>().isPersonalized,
      ),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _isLoading = false;
          _interstitial?.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _interstitial = null;
          ErrorHandler().logError('Ad load failed', error);
          // Don't show error to user for ad failures - they're not critical
        },
      ),
    );
  }

  Future<void> showInterstitial({String? trigger, int? levelNum, void Function()? onClosed}) async {
    // Don't show ads if user has purchased ad removal
    if (_purchaseService.adsRemoved) {
      onClosed?.call();
      return;
    }

    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      onClosed?.call();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdImpression: (ad) {
        _analyticsService.logAdImpression(format: 'interstitial', trigger: trigger, levelNum: levelNum);
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
        _analyticsService.logAdDismissed(format: 'interstitial', trigger: trigger, levelNum: levelNum);
        onClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
        _analyticsService.logAdDismissed(format: 'interstitial', trigger: trigger, levelNum: levelNum);
        ErrorHandler().logError('Ad show failed', error);
        onClosed?.call();
      },
    );
    await ad.show();
  }
}
