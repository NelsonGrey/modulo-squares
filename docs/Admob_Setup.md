# AdMob Configuration Guide

This guide covers setting up Google AdMob for monetization in the Modulo Squares Flutter app, including production configuration, testing, and privacy compliance.

## Table of Contents

1. [AdMob Account Setup](#admob-account-setup)
2. [App Registration](#app-registration)
3. [Ad Unit Creation](#ad-unit-creation)
4. [Flutter Integration](#flutter-integration)
5. [Platform-Specific Configuration](#platform-specific-configuration)
6. [Testing & Validation](#testing--validation)
7. [Privacy & Compliance](#privacy--compliance)
8. [Production Deployment](#production-deployment)

## AdMob Account Setup

### Prerequisites
- Google account
- Published or ready-to-publish app
- Valid payment profile (for monetization)

### Account Creation
1. Visit [admob.google.com](https://admob.google.com)
2. Sign in with Google account
3. Complete account verification
4. Set up payments profile
5. Accept AdMob terms of service

## App Registration

### Android App
1. In AdMob console, click "Apps" → "Add app"
2. Select "Android" platform
3. Enter app details:
   - **App name**: Modulo Squares
   - **Package name**: `com.modulosquares.app` (matches AndroidManifest.xml)
4. AdMob will generate an **App ID** (format: `ca-app-pub-XXXXXXXXXX~YYYYYYYYYY`)

### iOS App
1. In AdMob console, click "Apps" → "Add app"
2. Select "iOS" platform
3. Enter app details:
   - **App name**: Modulo Squares
   - **Bundle ID**: `com.modulosquares.app.ios` (matches Info.plist)
4. AdMob will generate an **App ID** (format: `ca-app-pub-XXXXXXXXXX~YYYYYYYYYY`)

## Ad Unit Creation

### Interstitial Ad Units

#### Android Interstitial
1. In AdMob console, select your Android app
2. Click "Ad units" → "Add ad unit"
3. Select "Interstitial"
4. Configure:
   - **Ad unit name**: "Game Interstitial"
   - **Ad type**: Interstitial
   - **Refresh rate**: Manual (controlled by app)
5. AdMob generates **Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXX/1234567890`)

#### iOS Interstitial
1. In AdMob console, select your iOS app
2. Click "Ad units" → "Add ad unit"
3. Select "Interstitial"
4. Configure:
   - **Ad unit name**: "Game Interstitial"
   - **Ad type**: Interstitial
   - **Refresh rate**: Manual (controlled by app)
5. AdMob generates **Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXX/1234567890`)

## Flutter Integration

### Dependencies
```yaml
dependencies:
  google_mobile_ads: ^3.0.0
  # Consent management
  consent_sdk: ^1.0.0  # Or use Google UMP directly
```

### Configuration File
Update `lib/core/config/admob_config.dart`:

```dart
class AdMobConfig {
  // Production IDs (replace with your actual IDs)
  static const String androidAppId = 'ca-app-pub-XXXXXXXXXX~YYYYYYYYYY';
  static const String iosAppId = 'ca-app-pub-XXXXXXXXXX~YYYYYYYYYY';

  static const String androidInterstitialId = 'ca-app-pub-XXXXXXXXXX/1234567890';
  static const String iosInterstitialId = 'ca-app-pub-XXXXXXXXXX/1234567890';

  // Test IDs (Google-provided for testing)
  static const String testAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testIosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  static String get appId => Platform.isAndroid ? androidAppId : iosAppId;

  static String get interstitialId {
    bool isDebug = const bool.fromEnvironment('dart.vm.product') == false;
    if (isDebug) {
      return Platform.isAndroid ? testAndroidInterstitialId : testIosInterstitialId;
    }
    return Platform.isAndroid ? androidInterstitialId : iosInterstitialId;
  }

  static bool get isUsingProductionIds =>
    interstitialId != testAndroidInterstitialId && interstitialId != testIosInterstitialId;
}
```

### Ad Service Implementation
The app includes a complete `AdService` class (`lib/core/services/ad_service.dart`) that handles:

- Ad loading and caching
- Platform-specific initialization
- Consent management integration
- Error handling and retry logic
- Analytics integration

## Platform-Specific Configuration

### Android Configuration

#### AndroidManifest.xml
Add App ID to `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <application>
        <!-- AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXX~YYYYYYYYYY"/>
    </application>
</manifest>
```

#### ProGuard Rules (if using)
Add to `android/app/proguard-rules.pro`:
```proguard
-keep public class com.google.android.gms.ads.** { public *; }
-keep public class com.google.ads.** { public *; }
```

### iOS Configuration

#### Info.plist
Add App ID to `ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXX~YYYYYYYYYY</string>
```

#### SKAdNetwork (iOS 14.5+)
Add SKAdNetwork identifiers for better attribution:
```xml
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <!-- Add more identifiers from Google's list -->
</array>
```

#### App Transport Security
Ensure ATS allows AdMob requests:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsArbitraryLoadsForMedia</key>
    <true/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
</dict>
```

## Testing & Validation

### Test Ad Units
Use Google's test ad units during development:
- **Android**: `ca-app-pub-3940256099942544/1033173712`
- **iOS**: `ca-app-pub-3940256099942544/4411468910`

### Testing Checklist
- [ ] Ads load without errors in debug mode
- [ ] Ads display correctly on different screen sizes
- [ ] Ad dismissal works properly
- [ ] No crashes when ads fail to load
- [ ] Analytics events fire correctly
- [ ] Test on physical devices (ads don't show in simulators)

### Validation Commands
```bash
# Check if production IDs are configured
flutter run --dart-define=validate-ads=true

# Test ad loading
flutter drive --target=test_driver/ads_test.dart
```

## Privacy & Compliance

### Consent Management
The app uses Google User Messaging Platform (UMP) for consent:

```dart
// Initialize consent SDK
await ConsentSdk.initialize();

// Show consent form if required
if (await ConsentSdk.isConsentFormAvailable()) {
  await ConsentSdk.showConsentForm();
}

// Check consent status before showing personalized ads
final canShowPersonalizedAds = await ConsentSdk.canShowPersonalizedAds();
```

### App Tracking Transparency (iOS)
iOS 14.5+ requires ATT permission:
```xml
<key>NSUserTrackingUsageDescription</key>
<string>This app uses tracking to deliver personalized ads and measure campaign effectiveness.</string>
```

### GDPR Compliance
- Consent forms shown in EEA countries
- Right to opt-out of personalized advertising
- Data processing transparency

### Children's Privacy
If app targets children under 13:
- Disable personalized ads
- Use non-personalized ad requests
- Update app store age ratings

## Production Deployment

### Pre-Launch Checklist
- [ ] Replace all test ad unit IDs with production IDs
- [ ] Update AndroidManifest.xml and Info.plist with production App IDs
- [ ] Test ads on release builds
- [ ] Verify consent forms work correctly
- [ ] Check ad serving policies compliance
- [ ] Review ad placement frequency
- [ ] Test on various device configurations

### Launch Process
1. **Update Configuration**: Replace placeholder IDs in `admob_config.dart`
2. **Build Release**: Create production builds with release mode
3. **Test Release Builds**: Verify ads work in release configuration
4. **Submit to Stores**: Upload apps with AdMob integration
5. **Monitor Performance**: Track ad impressions and revenue

### Post-Launch Monitoring
- **AdMob Dashboard**: Monitor impressions, clicks, eCPM
- **Firebase Analytics**: Track ad events and user behavior
- **Crash Reports**: Monitor for ad-related crashes
- **Policy Violations**: Address any AdMob policy issues promptly

## Troubleshooting

### Common Issues

**Ads Not Loading**
- Check internet connectivity
- Verify ad unit IDs are correct
- Ensure app is not in test mode
- Check AdMob account status

**Low Fill Rates**
- Improve ad unit targeting
- Add more ad formats
- Optimize ad placement timing
- Consider mediation partners

**Policy Violations**
- Review AdMob policies regularly
- Remove violating content immediately
- Appeal decisions with proper documentation

### Support Resources
- **AdMob Help Center**: support.google.com/admob
- **AdMob Policy Center**: support.google.com/admob/answer/6128543
- **Flutter AdMob Plugin**: pub.dev/packages/google_mobile_ads
- **Google UMP Documentation**: developers.google.com/admob/ump

## Performance Optimization

### Ad Loading Strategy
- Pre-load ads during game transitions
- Cache ads for immediate display
- Handle load failures gracefully
- Implement retry logic with exponential backoff

### User Experience
- Don't show ads during critical gameplay moments
- Provide clear ad dismissal options
- Balance ad frequency with user retention
- Test ad placements with real users

### Revenue Optimization
- A/B test ad placements and frequencies
- Monitor eCPM by ad unit and geography
- Optimize refresh rates
- Consider rewarded ads for better engagement

---

**AdMob Setup Version**: 2.0
**Last Updated**: October 2025
**Google Mobile Ads SDK**: 3.0.0