import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:modulo/utils/analytics_service.dart';
import 'package:modulo/utils/consent_service.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  InterstitialAd? _interstitial;
  bool _isLoading = false;

  Future<InitializationStatus> initialize() async {
    return MobileAds.instance.initialize();
  }

  String get _testInterstitialId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  void loadInterstitial() {
    if (_isLoading || _interstitial != null) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: _testInterstitialId,
      request: AdRequest(
        nonPersonalizedAds: !ConsentService.instance.isPersonalized,
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
        },
      ),
    );
  }

  Future<void> showInterstitial({String? trigger, int? levelNum, void Function()? onClosed}) async {
    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      onClosed?.call();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdImpression: (ad) {
        AnalyticsService.instance.logAdImpression(format: 'interstitial', trigger: trigger, levelNum: levelNum);
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
        AnalyticsService.instance.logAdDismissed(format: 'interstitial', trigger: trigger, levelNum: levelNum);
        onClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
        AnalyticsService.instance.logAdDismissed(format: 'interstitial', trigger: trigger, levelNum: levelNum);
        onClosed?.call();
      },
    );
    await ad.show();
  }
}
