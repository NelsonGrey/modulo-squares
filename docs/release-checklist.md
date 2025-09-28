# Release Checklist

This guide lists the steps to ship Modulo on Google Play and the App Store.

## IDs and versions
- Android: set `applicationId` and versions in `android/app/build.gradle.kts` (defaultConfig)
- iOS: set Bundle Identifier and versions in Xcode (Runner target)
- Flutter: bump `version` in `pubspec.yaml` (e.g., 1.0.0+1)

## Firebase
- Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are production
- If using flavors, wire dev/prod options

## AdMob
- Replace test ad unit IDs with production
- Android: add App ID in `AndroidManifest.xml` (APPLICATION_ID meta-data)
- iOS: add `GADApplicationIdentifier` in `Info.plist`
- Consider content rating and TFUA settings

## Privacy and consent
- iOS: `NSUserTrackingUsageDescription` and `SKAdNetworkItems` in `Info.plist`
- Implement ATT prompt and Google UMP where required; gate personalization until consent
- Complete App Store Privacy Nutrition Labels and Play Data Safety forms

## Assets and listings
- Icons, screenshots (iOS 6.7" + 5.5"; Android phone), Play feature graphic
- Descriptions, keywords, categories, privacy policy URL, support URL

## Build and distribute
- Android: `flutter build appbundle` → upload to Play Console (internal testing first)
- iOS: Archive in Xcode → upload to App Store Connect → TestFlight
- Verify events in Firebase DebugView; test ads on real devices

## Pre-submission
- Smoke test: level-up/restart interstitials; analytics events with `trigger` and `level_num`
- Check crash-free sessions
- Review store guidelines for ads frequency and content

## After approval
- Monitor analytics, ANRs/crashes, and ad fill; iterate on frequency caps if needed
