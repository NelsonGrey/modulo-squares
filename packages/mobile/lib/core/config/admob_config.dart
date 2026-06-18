import 'dart:io';

/// AdMob configuration for production and test environments
class AdMobConfig {
  // Production AdMob App IDs (REPLACE WITH YOUR ACTUAL PRODUCTION IDs)
  static const String androidAppId = 'ca-app-pub-5198775482699756~4572596676'; // Already configured in AndroidManifest.xml
  static const String iosAppId = 'ca-app-pub-5198775482699756~9962129501';

  // Production Ad Unit IDs (REPLACE WITH YOUR ACTUAL AD UNIT IDs)
  static const String androidInterstitialId = 'ca-app-pub-5198775482699756/2729455367';
  static const String iosInterstitialId = 'ca-app-pub-5198775482699756/8528576954';

  // Test Ad Unit IDs (used in debug mode)
  static const String testAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testIosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  /// Get the appropriate App ID based on platform
  static String get appId {
    if (Platform.isAndroid) {
      return androidAppId;
    } else if (Platform.isIOS) {
      return iosAppId;
    }
    return '';
  }

  /// Get the appropriate interstitial ad unit ID
  static String get interstitialId {
    // Use test IDs in debug mode, production IDs in release mode
    bool isDebug = const bool.fromEnvironment('dart.vm.product') == false;

    if (isDebug) {
      return Platform.isAndroid ? testAndroidInterstitialId : testIosInterstitialId;
    } else {
      return Platform.isAndroid ? androidInterstitialId : iosInterstitialId;
    }
  }

  /// Check if using production AdMob IDs
  static bool get isUsingProductionIds {
    return interstitialId != testAndroidInterstitialId && interstitialId != testIosInterstitialId;
  }
}
