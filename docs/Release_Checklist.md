# Production Release Checklist

This comprehensive guide ensures a smooth production release of Modulo Squares across all platforms (Android, iOS, Web).

## Table of Contents

1. [Pre-Release Preparation](#pre-release-preparation)
2. [Code & Configuration](#code--configuration)
3. [Platform-Specific Setup](#platform-specific-setup)
4. [Assets & Store Listings](#assets--store-listings)
5. [Build & Distribution](#build--distribution)
6. [Post-Release Monitoring](#post-release-monitoring)
7. [Emergency Procedures](#emergency-procedures)

## Pre-Release Preparation

### ✅ Development & Testing
- [x] Run `flutter analyze` - no issues
- [x] Run `flutter test` - all tests pass (42/42)
- [ ] Test on physical devices (iOS, Android)
- [ ] Performance testing completed
- [ ] Memory leak testing completed
- [ ] Beta testing with external users (optional)

### ✅ Version Management
- [ ] Update version in `pubspec.yaml` (semantic versioning: major.minor.patch+build)
- [ ] Update version in Android `build.gradle.kts`
- [ ] Update version in iOS Xcode project
- [ ] Update changelog and release notes

### ✅ Feature Flags & Configuration
- [ ] Disable debug/test features
- [ ] Enable production analytics
- [ ] Configure production AdMob IDs
- [ ] Set production Firebase configuration

## Code & Configuration

### ✅ Firebase Configuration
- [ ] Verify production `google-services.json` in `android/app/`
- [ ] Verify production `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Test Firebase services (Auth, Firestore, Analytics)
- [ ] Verify Firestore security rules
- [ ] Test Firebase Functions (if applicable)

### ✅ AdMob Configuration
- [ ] Replace test ad unit IDs with production IDs
- [ ] Update `lib/core/config/admob_config.dart`
- [ ] Update Android `AndroidManifest.xml` with production App ID
- [ ] Update iOS `Info.plist` with production App ID
- [ ] Test ads in release mode on physical devices
- [ ] Verify consent management (UMP SDK)

### ✅ Privacy & Compliance
- [x] Implement App Tracking Transparency (ATT) for iOS
- [x] Add ATT permission strings to Info.plist
- [ ] Test ATT permission flow
- [ ] Create/update privacy policy
- [ ] Verify GDPR compliance
- [ ] Complete App Store Privacy Nutrition Labels
- [ ] Complete Google Play Data Safety form

## Platform-Specific Setup

### Android Release Setup

#### ✅ Signing Configuration
- [ ] Generate/upload keystore to secure location
- [ ] Create `android/local.properties` with signing info:
  ```
  storePassword=your_keystore_password
  keyPassword=your_key_password
  keyAlias=modulo_key
  storeFile=modulo_keystore.jks
  ```
- [ ] Update `.gitignore` to exclude keystore files
- [ ] Test release build: `flutter build appbundle --release`

#### ✅ Play Store Preparation
- [ ] Create Google Play Console account/app
- [ ] Upload store assets (icons, screenshots, feature graphic)
- [ ] Fill in store listing information
- [ ] Set up pricing and distribution
- [ ] Configure content rating
- [ ] Set up internal/beta testing tracks

### iOS Release Setup

#### ✅ Signing Configuration
- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Create App ID in developer portal
- [ ] Configure Xcode signing (automatic recommended)
- [ ] Test release build: `flutter build ios --release`

#### ✅ App Store Preparation
- [ ] Create App Store Connect account
- [ ] Create app record with bundle ID
- [ ] Upload store assets (icons, screenshots)
- [ ] Fill in app information and metadata
- [ ] Set up pricing and availability
- [ ] Configure in-app purchases (if applicable)

### Web Release Setup (Optional)

#### ✅ Firebase Hosting
- [ ] Configure Firebase Hosting
- [ ] Update `web/index.html` for production
- [ ] Test web build: `flutter build web`
- [ ] Deploy to Firebase Hosting

## Assets & Store Listings

### ✅ App Assets
- [ ] Design app icon (1024x1024 PNG)
- [ ] Generate platform-specific icons
- [ ] Create high-quality screenshots:
  - [ ] Android: 8 phone screenshots (1080x1920+)
  - [ ] iOS: 3-5 screenshots per device type
- [ ] Create Play Store feature graphic (1024x500)
- [ ] Test assets display correctly on all platforms

### ✅ Store Metadata
- [ ] App name (30 chars max)
- [ ] Short description (80 chars)
- [ ] Full description (4000 chars)
- [ ] Keywords for App Store
- [ ] Category selection
- [ ] Privacy policy URL
- [ ] Support/contact information
- [ ] Age rating and content guidelines

## Build & Distribution

### Android Release Process
1. [ ] Build: `flutter build appbundle --release`
2. [ ] Upload `.aab` file to Google Play Console
3. [ ] Create release in internal/beta track first
4. [ ] Test internal release thoroughly
5. [ ] Promote to production when ready

### iOS Release Process
1. [ ] Build: `flutter build ios --release`
2. [ ] Open `ios/Runner.xcworkspace` in Xcode
3. [ ] Archive the app (Product → Archive)
4. [ ] Upload to App Store Connect via Xcode
5. [ ] Wait for processing (~30 minutes)
6. [ ] Submit for review or add to TestFlight

### Web Release Process (Optional)
1. [ ] Build: `flutter build web --release`
2. [ ] Deploy to Firebase Hosting: `firebase deploy --only hosting`
3. [ ] Test deployed web app functionality

## Post-Release Monitoring

### ✅ Analytics & Performance
- [ ] Monitor Firebase Analytics events
- [ ] Track user acquisition and retention
- [ ] Monitor crash reports (Firebase Crashlytics)
- [ ] Track AdMob performance and revenue
- [ ] Monitor app store ratings and reviews

### ✅ Issue Response
- [ ] Monitor app store review responses
- [ ] Address critical bug reports promptly
- [ ] Plan hotfix releases for critical issues
- [ ] Communicate with users about known issues

### ✅ Performance Optimization
- [ ] Monitor app startup time
- [ ] Track memory usage and battery consumption
- [ ] Analyze user flow completion rates
- [ ] Optimize based on real-world usage data

## Emergency Procedures

### Hotfix Release
1. **Identify Issue**: Determine severity and impact
2. **Create Fix**: Develop and test fix on separate branch
3. **Version Bump**: Increment patch version (e.g., 1.0.0 → 1.0.1)
4. **Build & Test**: Create release builds and test thoroughly
5. **Deploy**: Submit to app stores with priority
6. **Communicate**: Inform users about the fix

### Rollback Plan
1. **Assess Impact**: Determine if rollback is necessary
2. **Previous Version**: Identify last stable version
3. **Store Submission**: Submit previous version as update
4. **User Communication**: Explain rollback and expected fix timeline

### Contact Information
- **Google Play Support**: play.google.com/console
- **App Store Connect**: appstoreconnect.apple.com
- **Firebase Support**: firebase.google.com/support
- **AdMob Support**: support.google.com/admob

## Version Information

- **Current Version**: 0.0.1+1
- **Next Version**: [Set version number]
- **Release Type**: [Major/Minor/Patch]
- **Target Release Date**: [Set date]
- **Release Manager**: [Assign person]

## Release Timeline

### Week 1: Preparation
- Code freeze and final testing
- Asset creation and store preparation
- Beta testing and feedback collection

### Week 2: Platform Setup
- Android signing and Play Store setup
- iOS signing and App Store setup
- Final configuration verification

### Week 3: Release
- Build and submit to stores
- Monitor approval process
- Prepare for launch

### Week 4+: Post-Release
- Monitor analytics and user feedback
- Address issues and plan updates
- Plan next release cycle

---

**Release Checklist Version**: 2.0
**Last Updated**: October 2025
**Next Review**: [Set date]

This checklist ensures comprehensive coverage of all release aspects for the Modulo Squares application.