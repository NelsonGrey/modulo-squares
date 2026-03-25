import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:modulo_squares/core/services/analytics_service.dart';
import 'package:modulo_squares/core/services/consent_service.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/core/config/admob_config.dart';
import 'package:modulo_squares/core/services/error_handler.dart';

class AdService {
  AdService._([bool testMode = false]) : _testMode = testMode;
  static AdService? _instance;

  static AdService get instance {
    _instance ??= AdService._();
    return _instance!;
  }

  // Public constructor for dependency injection and testing
  factory AdService([bool testMode = false]) {
    if (testMode) {
      return AdService._(true);
    }
    return instance;
  }

  // Factory method for testing
  factory AdService.createForTesting() {
    return AdService._(true);
  }

  InterstitialAd? _interstitial;
  bool _isLoading = false;
  final bool _testMode;

  // Get analytics service from dependency injection
  AnalyticsService get _analyticsService => getIt<AnalyticsService>();

  // Get purchase service from dependency injection
  PurchaseService get _purchaseService => getIt<PurchaseService>();

  Future<InitializationStatus> initialize() async {
    if (_testMode) {
      // In test mode, return a mock initialization status
      return InitializationStatus({}); // Empty map for test
    }
    return MobileAds.instance.initialize();
  }

  String get _interstitialId => AdMobConfig.interstitialId;

  void loadInterstitial() {
    if (_testMode) return; // Skip ad loading in test mode

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

  Future<void> showInterstitial({
    String? trigger,
    int? levelNum,
    void Function()? onClosed,
  }) async {
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

    var closedNotified = false;
    final closeCompleter = Completer<void>();

    void completeOnce() {
      if (!closeCompleter.isCompleted) {
        closeCompleter.complete();
      }
      if (closedNotified) return;
      closedNotified = true;
      onClosed?.call();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdImpression: (ad) {
        _analyticsService.logAdImpression(
          format: 'interstitial',
          trigger: trigger,
          levelNum: levelNum,
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
        _analyticsService.logAdDismissed(
          format: 'interstitial',
          trigger: trigger,
          levelNum: levelNum,
        );
        completeOnce();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
        _analyticsService.logAdDismissed(
          format: 'interstitial',
          trigger: trigger,
          levelNum: levelNum,
        );
        ErrorHandler().logError('Ad show failed', error);
        completeOnce();
      },
    );

    try {
      await ad.show();

      // Guard against plugin callback misses so gameplay can always resume.
      await closeCompleter.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          ErrorHandler().logError(
            'Ad close timeout',
            TimeoutException(
              'Interstitial did not report close/failure callback in time.',
            ),
          );

          if (_interstitial == ad) {
            ad.dispose();
            _interstitial = null;
            loadInterstitial();
          }
          completeOnce();
        },
      );
    } catch (error) {
      ErrorHandler().logError('Ad show exception', error);
      if (_interstitial == ad) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
      }
      completeOnce();
    }
  }
}
