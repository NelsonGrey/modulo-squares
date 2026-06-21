# Modulo Squares — Go Live Document

**Version**: 1.2  
**Last Updated**: 2026-06-21  
**App Version**: 0.0.2+3 (increment before release to 1.0.0+1)  
**Owner**: Mark Nelson  
**Status**: Soft Launch Complete — Pre-Submission

---

## Readiness Summary

| Area | Status | Blocking? |
|------|--------|-----------|
| Core gameplay (falling mode, dead bucket, 50+ levels) | ✅ Complete | — |
| Firebase backend (3 environments, Cloud Functions v2) | ✅ Complete | — |
| AdMob production IDs configured | ✅ Complete | — |
| Firestore security rules | ✅ Complete | — |
| CI/CD pipeline (iOS) | ✅ Complete | — |
| Analytics instrumentation | ✅ Complete | — |
| Privacy / ATT compliance (iOS) | ✅ Complete | — |
| Store metadata text | ✅ Complete | — |
| Firebase Crashlytics wired | ✅ Wired (PR #73) | — |
| Privacy Policy / Terms pages | ✅ Live at /privacy and /terms | — |
| Guest → player account linking | ✅ Complete | — |
| Settings screen redesign | ✅ Complete (2026-06-21) | — |
| **iOS Store screenshots captured** | ⚠️ iOS 6.5" only (6 shots) | Yes |
| **App Store Connect app record** | ⚠️ Unconfirmed | Yes |
| **IAP "remove_ads" in ASC** | ⚠️ Unconfirmed | Yes |
| **Firebase GitHub Secrets** | ⚠️ Partial | Yes |
| **TestFlight beta** | ❌ Not started | No (soft) |
| **Firebase App Check enforcement** | ❌ Not enabled | No (post-launch) |
| **Google API key restrictions** | ❌ Not applied | No (post-launch) |
| **Android build** | ❌ Disabled in CI | Phase 2 |
| **Google Play Console app record** | ❌ Not created | Phase 2 |
| **Marketing website domain live** | ⚠️ Unconfirmed | No (soft) |

**iOS Launch is the primary gate.** Android can follow in Phase 2.

---

## How to Use This Document

Work through each phase in order. Every item has:
- A checkbox `[ ]` — check it off when done
- A **Validate** step — do not skip; it confirms the item is truly complete
- A **Blocking?** tag where relevant — items marked **BLOCKING** must be done before the next phase begins

The document can be re-run from any phase if work is paused. Checked items survive between sessions.

---

## Phase 0 — Environment Verification (Before Any Build)

Confirm the local development environment and infrastructure are in the expected state.

### 0.1 Tool Versions

```bash
flutter --version        # Must be 3.32.0+
dart --version           # Must be >=3.7.0
node --version           # Must be 18+
firebase --version       # Any recent CLI
bundle exec fastlane --version  # From packages/mobile
```

- [ ] Flutter 3.32.0+ confirmed
- [ ] Node 18+ confirmed
- [ ] Firebase CLI authenticated (`firebase login` → verify correct Google account)
- [ ] Fastlane available in `packages/mobile` (`bundle install` run if not)

**Validate**: `cd packages/mobile && flutter doctor -v` — no blocking issues.

---

### 0.2 Firebase Projects Reachable

```bash
firebase projects:list
```

- [ ] `modulo-squares-dev` listed
- [ ] `modulo-squares-staging` listed
- [ ] `modulo-squares-prod` listed

**Validate**: `firebase use modulo-squares-prod` succeeds without error.

---

### 0.3 GitHub Secrets Audit

Go to: **GitHub → Repository → Settings → Secrets and variables → Actions**

Required secrets and their current status:

| Secret Name | Purpose | Required By |
|-------------|---------|------------|
| `APP_STORE_CONNECT_KEY_ID` | iOS CI signing | iOS build |
| `APP_STORE_CONNECT_ISSUER_ID` | iOS CI signing | iOS build |
| `APP_STORE_CONNECT_KEY` | iOS CI signing (base64 .p8) | iOS build |
| `FASTLANE_APPLE_ID` | Fastlane auth | iOS build |
| `FASTLANE_TEAM_ID` | Apple Developer Team ID | iOS build |
| `MATCH_PASSWORD` | Match repo password | iOS build |
| `FIREBASE_TOKEN` | Firebase deploy | Web/Firebase deploy |
| `FIREBASE_PROJECT_DEV` | Firebase project ref | Web deploy |
| `FIREBASE_PROJECT_STAGING` | Firebase project ref | Web deploy |
| `FIREBASE_PROJECT_PROD` | Firebase project ref | Web deploy |
| `APPLE_TEAM_ID` | iOS manifest env var | iOS CI |

- [ ] All iOS secrets set and non-empty
- [ ] All Firebase secrets set and non-empty
- [ ] `MATCH_PASSWORD` set (if using Fastlane Match for certificates)

**Validate**: Trigger `master-pipeline.yml` → `load-config` job → confirm it completes green.

---

### 0.4 Self-Hosted macOS Runner Online

The iOS build requires a self-hosted runner tagged `self-hosted, macOS, ios`.

```bash
# On GitHub: Settings → Actions → Runners
# Confirm runner is "Idle" or "Active"
```

- [ ] macOS self-hosted runner listed as online in GitHub Actions
- [ ] Runner has Xcode, Flutter, Fastlane, and bundler installed
- [ ] Runner can reach App Store Connect APIs

**Validate**: `scripts/check-ios-runner-readiness.sh`

---

## Phase 1 — iOS App Store Launch (Primary Gate)

### 1.1 App Store Connect — App Record

Go to: **appstoreconnect.apple.com → Apps → (+) New App**

- [ ] App record created with:
  - **Bundle ID**: `com.nelsongrey.modulosquares.app.ios`  
    *(Must match the provisioning profile exactly — not `com.modulo.squares`)*
  - **SKU**: `modulo-squares-ios-1`
  - **Primary Language**: English (US)
  - **Name**: Modulo Squares
  - **Category**: Games → Puzzle
  - **Age Rating**: 4+

- [ ] Age rating questionnaire completed (no objectionable content, gambling, or violence)
- [ ] Export compliance: **No** custom encryption beyond OS standard
- [ ] App privacy questionnaire completed (data collected: analytics via Firebase, identifiers via AdMob ATT)

**Validate**: App record visible at appstoreconnect.apple.com with bundle ID `com.nelsongrey.modulosquares.app.ios`.

---

### 1.2 In-App Purchase — "Remove Ads"

Go to: **App Store Connect → your app → Monetization → In-App Purchases**

- [ ] Product `remove_ads` created with:
  - **Type**: Non-Consumable
  - **Product ID**: `remove_ads`  
    *(Must match the product ID referenced in `PurchaseService`)*
  - **Price**: $2.99 (Tier 3)
  - **Display Name**: Remove Ads
  - **Description**: Remove all ads permanently and enjoy uninterrupted gameplay.
- [ ] Product status: **Ready to Submit**
- [ ] Screenshot attached to IAP (required for review)
- [ ] Sandbox tester account created under **Users and Access → Sandbox → Testers**

**Validate**: On a real iPhone, in a release/TestFlight build, tapping "Remove Ads" shows the StoreKit purchase sheet with the correct price.

---

### 1.3 Game Center Leaderboard

Go to: **App Store Connect → your app → Services → Game Center**

- [ ] Game Center enabled for the app
- [ ] Global leaderboard created:
  - **Leaderboard ID**: Must match the constant in `leaderboard_service.dart`
  - **Score format**: Integer (points, highest first)
  - **Score range**: 0 to max
- [ ] Daily/weekly leaderboard IDs match if using Game Center for those (or confirm they use Firestore only)

**Validate**: Leaderboard appears in App Store Connect. Real device test shows leaderboard populates after game completion.

---

### 1.4 Legal — Privacy Policy and Terms of Service

Both URLs are **required** for App Store submission and for App Store Connect app record setup.

- [ ] Privacy Policy published at a stable public URL (e.g., `https://modulo-squares-prod.web.app/privacy`)
  - Must disclose: Firebase Analytics, AdMob (ATT / ad identifiers), Firestore (anonymous user data)
  - Must include GDPR data deletion / export rights
  - Must include COPPA disclosure (4+ rating)
- [ ] Terms of Service published at a stable public URL
- [ ] Support email configured (e.g., `support@[yourdomain].com` or forwarding address)
- [ ] Privacy Policy URL entered in App Store Connect app record
- [ ] Support URL entered in App Store Connect app record

**Validate**: Visit the Privacy Policy URL from a mobile browser — renders correctly, no 404.

---

### 1.5 Store Listing — Screenshots and Assets

Screenshots are the **highest-impact** missing item. No screenshots = no submission.

#### Required iOS Screenshot Sizes

| Device Class | Size | Count |
|---|---|---|
| iPhone 6.7" (required) | 1290 × 2796 px | 3–10 |
| iPhone 6.5" (required if no 6.7") | 1242 × 2688 px | 3–10 |
| iPhone 5.5" (optional, recommended) | 1242 × 2208 px | 3–10 |
| iPad Pro 12.9" (required if supporting iPad) | 2048 × 2732 px | 3–10 |

#### Screenshot Content Plan (Minimum 3, Recommended 5)

1. **Title card** — App name + tagline over the game grid
2. **Active gameplay** — Tile in motion, score visible, mid-level
3. **Level completion** — Win state with score burst
4. **Leaderboard** — Global leaderboard screen showing top players
5. **Special tiles / falling mode** — Showcase unique mechanics

#### Screenshot Procedure

```bash
# Connect real iPhone (release profile) or use Simulator
flutter run --release -d <device>
# Take screenshots directly from device or use Xcode → Window → Devices and Simulators
```

- [ ] iPhone 6.7" screenshots captured (min 3) — *(6.5" captured; need 6.7" or confirm 6.5" covers requirement)*
- [x] iPhone 6.5" screenshots captured — 6 shots in `packages/mobile/assets/store/screenshots/ios-6.5/`:
  - `01-title-rules.png`, `02-active-gameplay.png`, `03-paused-run.png`
  - `04-settings.png`, `05-sign-in-sign-up.png`, `06-create-gamertag.png`
- [ ] App icon 1024×1024 PNG without alpha channel confirmed:
  - Located at `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
  - No gradient-only design (Apple HIG)
- [ ] Screenshots uploaded to App Store Connect
- [ ] App preview video (optional but recommended for puzzle games)

**Validate**: Screenshots visible in App Store Connect preview for each device class.

---

### 1.6 Store Listing — Metadata

Metadata files exist in `packages/mobile/assets/store/metadata/`. Review and finalize for submission.

- [ ] **App Name** (30 chars max): `Modulo Squares` ✅
- [ ] **Subtitle** (30 chars max, optional but recommended): e.g., "Math Puzzle Game"
- [ ] **Short Description** (80 chars): Review `short_description.txt` — ensure it fits
- [ ] **Full Description** (4000 chars max): Review `description.txt` — paste into App Store Connect
- [ ] **Keywords** (100 chars total, comma-separated): Review `keywords.txt`
  - Current: `modulo,puzzle,math,numbers,brain,logic,strategy,grid,tiles,mathematical,thinking,logic,puzzle,game,free,ads`
  - Note: duplicates ("logic", "puzzle") — remove duplicates to maximize keyword coverage
- [ ] **What's New** (optional for initial release): "Welcome to Modulo Squares — clear the grid with math!"
- [ ] **Privacy Policy URL**: Enter live URL from step 1.4
- [ ] **Support URL**: Enter support email or FAQ page URL

**Validate**: App Store Connect listing preview renders correctly with no missing fields flagged.

---

### 1.7 iOS Build — Preflight Quality Gates

Run all quality gates before building the release IPA. **Do not skip.**

```bash
cd packages/mobile

# 1. Static analysis — must exit 0, no issues
flutter analyze --no-pub

# 2. Unit tests — must all pass
flutter test --no-pub

# 3. Simulator smoke build
flutter build ios --simulator
```

- [ ] `flutter analyze` — **No issues found**
- [ ] `flutter test` — **All tests pass**
- [ ] Simulator build succeeds

**Validate**: All three commands exit 0.

---

### 1.8 iOS Production Configuration

Before building the release IPA, confirm every production config is in place:

**Firebase**
- [ ] `packages/mobile/ios/Runner/GoogleService-Info.plist` is the **production** project config
  - Project ID inside must be `modulo-squares-prod` (not dev or staging)
- [ ] `GOOGLE_REVERSED_CLIENT_ID` URL scheme in `Info.plist` matches the `GoogleService-Info.plist` client ID
  - Confirm: `com.googleusercontent.apps.784677197785-acn8nnrs4rhoeipg9ek4u6b1p512nqkm` is the production reversed client ID

**AdMob**
- [ ] `GADApplicationIdentifier` in `Info.plist` = `ca-app-pub-5198775482699756~9962129501` ✅ (already set)
- [ ] `iosInterstitialId` in `admob_config.dart` = `ca-app-pub-5198775482699756/8528576954` ✅ (already set)
- [ ] Confirm ads service returns production IDs in release mode: `AdMobConfig.isUsingProductionIds` → `true` in release builds

**Privacy / ATT**
- [ ] `NSUserTrackingUsageDescription` in `Info.plist` ✅ (already set)
- [ ] ATT prompt fires before first ad impression (test on real device)
- [ ] Consent service (`consent_service.dart`) shows UMP form for EEA users

**Signing**
- [ ] Distribution certificate valid in Keychain (check expiry in Keychain Access)
- [ ] App Store provisioning profile installed and not expired
- [ ] Profile covers bundle ID `com.nelsongrey.modulosquares.app.ios`
- [ ] `CODE_SIGN_STYLE = Manual` in Release scheme (or Automatic + team configured)

**Version**
- [ ] `pubspec.yaml` version bumped for this release:
  ```
  version: 1.0.0+1   # semver+build; build MUST be unique per ASC upload
  ```
- [ ] Build number is **higher than** any previously uploaded build in App Store Connect

**Validate**: `flutter build ipa --release` exits 0. IPA file produced in `build/ios/ipa/`.

---

### 1.9 Real-Device Smoke Test (Release Build)

Install the release build on a real iPhone before uploading:

```bash
flutter run --release -d <REAL_DEVICE_UDID>
```

Verify each item manually:

- [ ] App launches without crash
- [ ] Login screen appears (account-required flow active)
- [ ] Google Sign-In works (OAuth flow completes)
- [ ] Apple Sign-In works (Sign in with Apple flow completes)
- [ ] Game starts after authentication
- [ ] Falling Mode: tile falls, score burst appears, positive burst = gold pill, negative burst = red diamond
- [ ] Start/Pause controls function correctly; game does not auto-start on screen open
- [ ] Progress grid is 10×10 and aligns with bottom lane
- [ ] Level completion triggers correct scoring
- [ ] Interstitial ad appears between levels (free logged-in user); does NOT appear for ad-removed user
- [ ] IAP flow: tapping "Remove Ads" presents StoreKit sheet (sandbox account)
- [ ] Purchase completes with sandbox account; ads disappear
- [ ] Restore Purchases works correctly
- [ ] Leaderboard loads and shows scores
- [ ] Settings / visual cues toggle saves across app restarts
- [ ] App Tracking Transparency prompt appears (first launch only, before first ad)
- [ ] No crashes observed in a 10-minute play session

**Validate**: Zero crashes. All flows above confirmed working on device.

---

### 1.10 Archive and Upload to TestFlight

```bash
# From packages/mobile
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist

# Upload via Transporter, Xcode Organizer, or altool:
xcrun altool --upload-app \
  -f build/ios/ipa/*.ipa \
  -u "$APPLE_ID" \
  -p "$APP_SPECIFIC_PASSWORD"

# Or use Fastlane:
cd packages/mobile/ios
bundle exec fastlane beta
```

- [ ] IPA builds cleanly
- [ ] Upload accepted by App Store Connect (no rejection email within 10 minutes)
- [ ] Build appears in TestFlight tab (can take up to 30 minutes)
- [ ] Export compliance question answered (No custom encryption)
- [ ] Internal testers invited and notified
- [ ] Build passes App Store automated review (typically < 30 min for TestFlight)

**Validate**: Build visible in TestFlight. Internal testers can install and launch successfully.

---

### 1.11 TestFlight Beta Period

Before submitting to the App Store, run at least a short internal beta.

- [ ] At least 1 internal tester completes a full play session (3+ levels) and reports no blockers
- [ ] IAP purchase and restore confirmed on TestFlight build
- [ ] Interstitial ad cadence confirmed (fires between levels, not during gameplay)
- [ ] No crash report spikes in App Store Connect → TestFlight → Crashes
- [ ] ATT prompt verified working on iOS 15+ device

Target duration: **3–7 days** (can compress to 24 hours for internal-only if confident).

**Validate**: Zero blocking bugs from TestFlight period. Crash rate < 1%.

---

### 1.12 App Store Submission

After TestFlight beta clears:

Go to: **App Store Connect → your app → Distribution → App Store → (+) Prepare Submission**

- [ ] Select the TestFlight build that passed beta
- [ ] Confirm all metadata (name, description, keywords, screenshots) is finalized
- [ ] Set pricing: **Free**
- [ ] Set availability: **All territories** (or English-speaking markets first: US, GB, CA, AU, NZ)
- [ ] Confirm release date: **Automatic after approval** or set manual date
- [ ] Confirm "Phased Release" setting (recommended: on — rolls out over 7 days)
- [ ] Click **Submit for Review**

Expected review time: 24–72 hours (usually 24 hours for puzzle games with no objectionable content).

**Validate**: Submission status in App Store Connect shows "Waiting for Review" or "In Review."

---

## Phase 2 — Android Launch (Follow Phase 1 by ~2 Weeks)

Android is currently **disabled** in `.cicd/projects/modulo-squares.yml` (`android.enabled: false`). Enable it and complete the steps below when ready.

### 2.1 Enable Android in CI Manifest

Edit `.cicd/projects/modulo-squares.yml`:

```yaml
android:
  enabled: true    # Change from false
```

**Validate**: `master-pipeline.yml` → `build-android` job appears and runs.

---

### 2.2 Android Keystore Setup

The keystore is required for production `.aab` builds. Store it securely — **never commit**.

```bash
# Generate keystore (one-time, if not already done)
cd packages/mobile/android
./generate_keystore.sh

# Or manually:
keytool -genkey -v \
  -keystore modulo_keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias modulo_key
```

- [ ] Keystore file generated and stored in a **secure location outside the repo** (e.g., 1Password, AWS Secrets Manager)
- [ ] `android/local.properties` configured:
  ```
  storePassword=<password>
  keyPassword=<password>
  keyAlias=modulo_key
  storeFile=<absolute/path/to/modulo_keystore.jks>
  ```
- [ ] `android/local.properties` and `*.jks` confirmed in `.gitignore`
- [ ] `ANDROID_KEYSTORE` (base64), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` set as GitHub Secrets

**Validate**: `flutter build appbundle --release` exits 0 and produces `.aab`.

---

### 2.3 Google Play Console — App Record

Go to: **play.google.com/console → Create app**

- [ ] App created:
  - **App name**: Modulo Squares
  - **Default language**: English (US)
  - **App or game**: Game
  - **Free or paid**: Free
- [ ] Package name confirmed: `com.nelsongrey.modulosquares.app.android`
- [ ] Content rating questionnaire completed (expected: Everyone)
- [ ] Data safety form completed:
  - Analytics data (Firebase): disclosed
  - Advertising ID (AdMob): disclosed
  - No health, financial, or sensitive data

**Validate**: App record visible in Play Console.

---

### 2.4 Android AdMob Configuration

- [ ] `androidAppId` in `admob_config.dart` = `ca-app-pub-5198775482699756~4572596676` ✅ (already set)
- [ ] `androidInterstitialId` = `ca-app-pub-5198775482699756/2729455367` ✅ (already set)
- [ ] AdMob App ID in `android/app/src/main/AndroidManifest.xml` matches production:
  ```xml
  <meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-5198775482699756~4572596676"/>
  ```
- [ ] `android:allowBackup="false"` confirmed in `AndroidManifest.xml` ✅

**Validate**: Release build on real Android device shows ads (not blank) and no AdMob initialization errors in logcat.

---

### 2.5 Android Store Assets

Screenshots required for Play Store submission:

| Type | Min Size | Count |
|------|----------|-------|
| Phone | 1080×1920 | 2–8 |
| Tablet (optional) | 1200×1920 | 1–8 |
| Feature graphic | 1024×500 | 1 (required) |
| App icon | 512×512 PNG | 1 (required) |

- [ ] Phone screenshots captured on Android device (release build)
- [ ] Feature graphic created (1024×500)
- [ ] Adaptive icon files in `android/app/src/main/res/mipmap-*` directories
- [ ] All assets uploaded to Play Console

**Validate**: Play Console store listing preview renders completely.

---

### 2.6 Android IAP Setup

Go to: **Play Console → Monetize → Products → In-app products**

- [ ] Product `remove_ads` created:
  - **Product ID**: `remove_ads` (must match iOS product ID)
  - **Product type**: Managed product (one-time)
  - **Price**: $2.99
  - **Status**: Active
- [ ] Test on real Android device with Google Play test account

**Validate**: In release build, "Remove Ads" purchase completes successfully with test account.

---

### 2.7 Android Production Build and Upload

```bash
cd packages/mobile
flutter build appbundle --release
```

- [ ] `.aab` built successfully at `build/app/outputs/bundle/release/`
- [ ] Upload to Play Console internal testing track:
  - Play Console → Testing → Internal testing → Create new release → Upload
- [ ] Internal testing release approved and installable via test link
- [ ] Promote to closed testing (alpha) track for 3–5 days
- [ ] Promote to production when approved

**Validate**: Installed from Play Store internal test link. App launches, plays, and purchases work.

---

## Phase 3 — Backend, Web, and Infrastructure

### 3.1 Firebase Production Deployment

Ensure all Firebase resources are deployed to `modulo-squares-prod`:

```bash
# From repo root
firebase use modulo-squares-prod

# Deploy everything
firebase deploy --project modulo-squares-prod

# Or deploy individually:
firebase deploy --only hosting --project modulo-squares-prod
firebase deploy --only functions --project modulo-squares-prod
firebase deploy --only firestore:rules --project modulo-squares-prod
firebase deploy --only firestore:indexes --project modulo-squares-prod
```

- [ ] Firestore rules deployed (verify `firestore.rules` is current):
  - Leaderboard: public read, write=false ✅
  - Purchases / entitlements: auth-user read, write=false ✅
  - User profiles / game_stats: auth-user read+write ✅
- [ ] Cloud Functions deployed and returning 200 on health endpoint
- [ ] Firebase Hosting serving web app at `https://modulo-squares-prod.web.app`
- [ ] Firebase Authentication: Google, Apple sign-in providers enabled in console

**Validate**:
```bash
curl https://modulo-squares-prod.web.app
# Returns 200 with HTML
```

---

### 3.2 Web Marketing Site

The web package (`packages/web`) is a React + Vite marketing site.

```bash
cd packages/web
npm install
npm run build
```

- [ ] Web app builds without errors
- [ ] Deployed to Firebase Hosting (via CI or manual `firebase deploy --only hosting`)
- [ ] Privacy Policy and Terms of Service pages live at stable URLs
- [ ] Google Analytics or Firebase Analytics connected to web app
- [ ] App Store / Google Play download links on landing page
- [ ] SEO meta tags present (title, description, og:image for social sharing)

**Validate**: Visit `https://modulo-squares-prod.web.app` — landing page loads, links work, policy pages accessible.

---

### 3.3 Custom Domain (Optional but Recommended)

If `modulo-squares.com` (or similar) is the intended domain:

- [ ] Domain purchased and DNS configured
- [ ] Firebase Hosting custom domain added:
  - Firebase Console → Hosting → Add custom domain
  - Add DNS TXT verification record
  - Add CNAME/A records as instructed
- [ ] HTTPS certificate auto-provisioned by Firebase (can take up to 24 hours)

**Validate**: `https://modulo-squares.com` loads the web app with valid TLS certificate.

---

### 3.4 Firebase App Check (Post-Launch Security)

Firebase App Check protects backend APIs from unauthorized clients. This is a post-launch hardening step but should be enabled within the first week.

- [ ] Firebase App Check enabled in Firebase Console for:
  - App Attest (iOS)
  - Play Integrity (Android)
  - reCAPTCHA v3 (Web)
- [ ] App Check enforcement enabled for Firestore and Cloud Functions
- [ ] Mobile app built with App Check SDK (add `firebase_app_check` to pubspec.yaml)
- [ ] Web app initialized with reCAPTCHA v3 key

**Note**: Enable in **monitoring mode** first to confirm no legitimate traffic is blocked before switching to enforcement mode.

---

### 3.5 API Key Restrictions (Post-Launch Security)

From the hardening matrix — apply these in Google Cloud Console after launch:

- [ ] Firebase API key for iOS restricted to bundle ID `com.nelsongrey.modulosquares.app.ios`
- [ ] Firebase API key for Android restricted to package name `com.nelsongrey.modulosquares.app.android`
- [ ] Firebase API key for Web restricted to allowed referrer domains
- [ ] AdMob API key restricted by app

**Validate**: App still authenticates normally. No `403` errors in Firebase logs.

---

### 3.6 Firestore Backups

Verify Firestore automatic backups are configured for production:

- [ ] Firebase Console → Firestore → Backup → Scheduled backup enabled
- [ ] Backup retention: at least 7 days
- [ ] Backup location: same region as Firestore instance
- [ ] Test restore procedure documented (see `scripts/backup-firestore.sh`)

**Validate**: At least one successful backup visible in Firebase Console.

---

## Phase 4 — CI/CD and Automation Verification

### 4.1 Full Pipeline Run

Trigger a complete pipeline run against `main` to confirm the production deployment path works end-to-end.

```bash
# Via GitHub Actions UI:
# Actions → Master CI/CD Pipeline → Run workflow
# action: build_and_deploy
# environment: production
```

- [ ] `load-config` job: green
- [ ] `test` job: green (or continues-on-error with warning)
- [ ] `build-ios` job: green → IPA uploaded to TestFlight
- [ ] `build-web` job: green → Web deployed to Firebase Hosting
- [ ] `deploy-firebase` job: green → Rules + Functions deployed
- [ ] `pipeline-summary` job: green

**Validate**: Pipeline completes green. TestFlight shows a new build. `https://modulo-squares-prod.web.app` shows updated version.

---

### 4.2 Branch Protection Confirmation

From the hardening matrix, all branches should be protected:

- [ ] `main`: PR required, 1 approval required, CODEOWNER review required, no force push, no deletion
- [ ] `staging`: Same protections
- [ ] `develop`: Same protections

**Validate**: Attempt to push directly to `main` — it should be rejected.

---

### 4.3 Dependabot and Security Scanning

- [ ] Dependabot alerts reviewed and critical ones resolved
- [ ] CodeQL workflow (`.github/workflows/codeql.yml`) running and green
- [ ] No exposed secrets in secret scanning alerts

**Validate**: GitHub → Security → no critical unresolved alerts.

---

## Phase 5 — Pre-Launch Monitoring Setup

Configure monitoring before launch so signals are live the moment users start arriving.

### 5.1 Firebase Analytics — Dashboard Baseline

- [ ] Firebase Console → Analytics → Dashboard is showing data from staging/dev usage
- [ ] DebugView tested: all core events firing correctly on real device:
  - `app_open` ✅
  - `level_start` ✅
  - `level_complete` ✅
  - `ad_impression` / `ad_dismissed` ✅
  - `leaderboard_tab_changed` ✅
- [ ] Key audiences configured:
  - Users who completed Level 1
  - Users who purchased remove_ads
  - Users who viewed leaderboard

**Validate**: DebugView shows expected events during a 5-minute play session.

---

### 5.2 Crashlytics

Firebase Crashlytics is referenced in documentation but not listed in `pubspec.yaml`. Add if not already integrated:

```yaml
# pubspec.yaml
dependencies:
  firebase_crashlytics: ^4.0.0
```

```dart
// main.dart — add after Firebase.initializeApp()
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

- [x] `firebase_crashlytics` package added to `pubspec.yaml` (PR #73)
- [x] Crash handler wired in `main.dart` (PR #73)
- [ ] Test crash: `FirebaseCrashlytics.instance.crash()` on a debug build → crash appears in console
- [ ] Crash-free users target: 99.5%

**Validate**: Firebase Console → Crashlytics → Overview shows the app. A forced test crash appears within 5 minutes.

---

### 5.3 AdMob Ad Inspector

Before launch, verify ad serving is healthy on real devices:

- [ ] AdMob Console → Apps → Ad Inspector enabled on test device
- [ ] Interstitial ad loads and fills correctly in production mode
- [ ] Frequency capping configured (maximum 1 interstitial per session threshold)
- [ ] No policy violations flagged in AdMob Console

**Validate**: AdMob Console shows ad requests and fill rate > 80% for the test period.

---

### 5.4 Monitoring Server (Optional)

A monitoring server exists at `monitoring/server.js`. If using it:

- [ ] Deploy monitoring server (Dockerfile.monitor)
- [ ] Status dashboard accessible at the configured URL
- [ ] Alerts configured for Firebase outages or error spikes

---

## Phase 6 — Launch Day Execution

### 6.1 Final Go / No-Go Checklist

Complete this checklist the morning of launch. **All blocking items must be ✅ before proceeding.**

| Check | Status | Blocking? |
|-------|--------|-----------|
| iOS app approved in App Store | ☐ | BLOCKING |
| Privacy Policy URL live | ☐ | BLOCKING |
| Terms of Service URL live | ☐ | BLOCKING |
| Production Firebase config active | ☐ | BLOCKING |
| AdMob production IDs in IPA | ☐ | BLOCKING |
| IAP `remove_ads` = Ready to Submit / Approved | ☐ | BLOCKING |
| Crashlytics wired and receiving data | ☐ | BLOCKING |
| Firebase Hosting web app live | ☐ | Recommended |
| Android build submitted (Phase 2) | ☐ | Phase 2 |
| Social media announcements drafted | ☐ | Optional |

---

### 6.2 App Store Release

- [ ] Release method: Automatic after approval **OR** manually release via App Store Connect
- [ ] If manual: App Store Connect → your app → Pricing and Availability → Release This Version

**Validate**: App appears on App Store search within 1–2 hours.

---

### 6.3 Announce

- [ ] Share download link on relevant channels:
  - Reddit: r/puzzles, r/indiegaming, r/mathgames (read subreddit rules first)
  - Hacker News Show HN (if submitting)
  - Social media accounts
  - Product Hunt (if timing aligns)
- [ ] App Store URL formatted for sharing: `https://apps.apple.com/app/id<APP_ID>`

---

## Phase 7 — Post-Launch Monitoring (Week 1)

Check these every day for the first week. Set calendar reminders.

### 7.1 Daily Metrics Targets (Week 1)

| Metric | Target | Where to Check |
|--------|--------|----------------|
| App installs | 50+/day | App Store Connect → Analytics |
| D1 retention | 45%+ | Firebase Analytics → Retention |
| Crash-free session rate | 99%+ | Firebase Crashlytics |
| App Store rating | 4.0+ | App Store Connect → Ratings |
| AdMob fill rate | 80%+ | AdMob Console |
| IAP conversion | Tracking | Firebase Analytics → `iap_purchase` events |

### 7.2 Monitoring Actions

- [ ] Day 1: Confirm first real installs appear in App Store Connect Analytics
- [ ] Day 1: Confirm Firebase Analytics shows `app_open` and `level_start` from real users
- [ ] Day 2: Check Crashlytics for any non-test crashes
- [ ] Day 3: Check D1 retention in Firebase retention report
- [ ] Day 3: Review App Store reviews (respond to any within 24 hours)
- [ ] Day 7: D7 retention check (target 25%)
- [ ] Day 7: Ad revenue check in AdMob Console

---

### 7.3 Hotfix Procedure (If Critical Bug Found)

1. **Assess**: Is it a crash, data loss, or IAP break? → Hotfix. Is it a visual/UX issue? → Next sprint.
2. **Branch**: `git checkout -b hotfix/1.0.1 main`
3. **Fix and test**: `flutter analyze && flutter test` must pass
4. **Bump version**: `1.0.0+1` → `1.0.1+2` in `pubspec.yaml`
5. **Build and upload**: Run `flutter build ipa --release` → upload to TestFlight
6. **Submit for expedited review**: App Store Connect → Submit with "Expedited Review" request
7. **Communicate**: If data or purchase-affecting bug, post in-app notice or support email

---

### 7.4 App Store Review Responses

Responding to reviews within 24 hours signals product health to Apple's algorithm.

Template for 1-2 star reviews:
> "Thanks for the feedback. We'd love to understand what went wrong — email us at [support email] and we'll make it right."

Template for 5-star reviews:
> "Thanks for playing! More levels and features are coming soon."

---

## Phase 8 — 30-Day Post-Launch Hardening

Complete these in the 30 days after launch when operations are stable.

### 8.1 Security Hardening

- [ ] Firebase App Check enforcement enabled (moved from monitoring → enforce mode) after confirming no false positives
- [ ] Google API key restrictions applied (bundle ID / package restrictions) per Phase 3.5
- [ ] Monthly credential rotation: Firebase tokens, App Store Connect key expiry check
- [ ] Review GitHub Dependabot alerts; patch any critical CVEs within 5 days

### 8.2 Operations

- [ ] Support mailbox monitoring cadence established (check daily)
- [ ] Firestore backup restore tested (actually restore a backup to a test environment)
- [ ] AdMob mediation review: consider adding additional ad networks for better fill rate
- [ ] BigQuery export verified for Firebase Analytics (for retention/funnel analysis)
- [ ] A/B test framework planned for ad frequency optimization (Firebase Remote Config)

### 8.3 Content Roadmap

Based on D7 retention data:

- [ ] If D7 < 20%: Prioritize tutorial improvement and early-level difficulty tuning
- [ ] If D7 >= 25%: Begin Phase 2 feature work (daily challenges, tournament mode)
- [ ] Level design pipeline established for new level packs

---

## Appendix A — Key Resource Reference

| Resource | URL / Path |
|----------|-----------|
| App Store Connect | https://appstoreconnect.apple.com |
| Google Play Console | https://play.google.com/console |
| Firebase Console (prod) | https://console.firebase.google.com/project/modulo-squares-prod |
| AdMob Console | https://apps.admob.com |
| GitHub Actions | https://github.com/mnelson3/modulo-squares/actions |
| Web App (prod) | https://modulo-squares-prod.web.app |
| iOS bundle ID | `com.nelsongrey.modulosquares.app.ios` |
| Android package | `com.nelsongrey.modulosquares.app.android` |
| IAP product ID | `remove_ads` |
| AdMob iOS App ID | `ca-app-pub-5198775482699756~9962129501` |
| AdMob Android App ID | `ca-app-pub-5198775482699756~4572596676` |
| iOS Interstitial Ad Unit | `ca-app-pub-5198775482699756/8528576954` |
| Android Interstitial Ad Unit | `ca-app-pub-5198775482699756/2729455367` |
| Current app version | `0.0.2+3` (bump before release) |
| Testflight checklist | `docs/Testflight_Readiness_Checklist.md` |
| iOS signing guide | `docs/Ios_Signing.md` |
| Security guide | `docs/Security.md` |
| Analytics events | `docs/Analytics.md` |
| Hardening matrix | `docs/SOLUTION_HARDENING_MATRIX.md` |

---

## Appendix B — GitHub Secrets Quick Reference

These secrets must be set in **GitHub → Repository → Settings → Secrets → Actions** before any CI/CD pipeline run will succeed.

| Secret | How to Obtain |
|--------|--------------|
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect → Users → Integrations → API Keys |
| `APP_STORE_CONNECT_ISSUER_ID` | Same page as above |
| `APP_STORE_CONNECT_KEY` | Download .p8, then: `base64 -i AuthKey_XXXXX.p8 \| pbcopy` |
| `FASTLANE_APPLE_ID` | Your Apple developer email |
| `FASTLANE_TEAM_ID` | developer.apple.com → Membership → Team ID |
| `MATCH_PASSWORD` | Password used to encrypt Fastlane Match repo |
| `APPLE_TEAM_ID` | Same as FASTLANE_TEAM_ID |
| `FIREBASE_TOKEN` | `firebase login:ci` → copy token |
| `FIREBASE_PROJECT_DEV` | `modulo-squares-dev` |
| `FIREBASE_PROJECT_STAGING` | `modulo-squares-staging` |
| `FIREBASE_PROJECT_PROD` | `modulo-squares-prod` |
| `ANDROID_KEYSTORE` | `base64 -i modulo_keystore.jks \| pbcopy` |
| `ANDROID_KEYSTORE_PASSWORD` | Password set during keytool generation |
| `ANDROID_KEY_ALIAS` | `modulo_key` |
| `ANDROID_KEY_PASSWORD` | Key password set during keytool generation |

---

## Appendix C — Known Issues / Decisions Pending

| Issue | Impact | Decision Needed |
|-------|--------|----------------|
| `firebase_crashlytics` ~~not in `pubspec.yaml`~~ | ✅ Added ^5.2.4 + wired in main.dart (PR #73) | — |
| Android disabled in CI manifest | Android launch delayed | Set `android.enabled: true` when ready for Phase 2 |
| Marketing domain (modulo-squares.com) status | Lower discoverability | Confirm DNS and Firebase Hosting custom domain |
| Slack webhook `${SLACK_WEBHOOK_URL}` not set | No CI notifications | Optional: add Slack secret for pipeline alerts |
| Bundle ID inconsistency in legacy docs | Confusion risk | Canonical ID is `com.nelsongrey.modulosquares.app.ios` — treat older `com.modulo.squares` references as stale |
| `storekit_no_response` in simulator | Non-blocking | Expected behavior; IAP must be tested on real device only |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-06-17 | Mark Nelson | Initial comprehensive Go Live document synthesized from full codebase and docs audit |
| 1.1 | 2026-06-17 | Mark Nelson | Mark completed: Crashlytics wired, Privacy/Terms pages live, keywords deduped, all security alerts resolved (PRs #70–73) |
| 1.2 | 2026-06-21 | Mark Nelson | Soft launch complete on main. Added: dead bucket visual, guest→player account linking, sign-out, dark gamertag screen, interstitial ads (gamertag + level transitions), Cloud Functions v2 migration, settings screen redesign + tests. iOS 6.5" screenshots captured (6 shots). Readiness summary updated. |

---

*This document supersedes individual platform checklists for launch purposes. Those files (`Testflight_Readiness_Checklist.md`, `Release_Checklist.md`, `Setup_Checklist.md`) remain valid as reference for their specific scopes.*
