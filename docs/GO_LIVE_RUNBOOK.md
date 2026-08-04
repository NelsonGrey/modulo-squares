# Modulo Squares — Go Live Document

**Version**: 2.0
**Last Updated**: 2026-07-20
**App Version**: 1.0.0+2
**Owner**: Mark Nelson
**Status**: All four issues from the 2026-07-01 rejection were fixed and a corrected production build reached TestFlight. App Store resubmission/approval/public availability has not been reconfirmed from App Store Connect during this repository audit and remains the release gate.

---

## Readiness Summary

| Area | Status | Blocking? |
|------|--------|-----------|
| Core gameplay (falling mode, dead bucket, 50+ levels) | ✅ Complete | — |
| Firebase backend (3 environments, Cloud Functions v2) | ✅ Complete | — |
| AdMob production IDs configured | ✅ Complete | — |
| Firestore security rules | ✅ Complete | — |
| CI/CD pipeline (iOS) | ✅ Complete | — |
| Analytics instrumentation | ⚠️ App/ad events wired; falling-mode level events not connected | No |
| Privacy / ATT compliance (iOS) | ✅ Complete | — |
| Store metadata text | ✅ Repository copy current; App Store Connect sync unverified | — |
| Firebase Crashlytics wired | ✅ Wired (PR #73) | — |
| Privacy Policy / Terms pages | ✅ Live at /privacy and /terms | — |
| Guest → player account linking | ✅ Complete | — |
| Settings screen redesign | ✅ Complete (2026-06-21) | — |
| iOS Store screenshots (6.5") | ⚠️ Six files in repository; App Store Connect upload last confirmed 2026-07-01 | — |
| App Store Connect app record | ⚠️ Last confirmed 2026-07-01; current state unverified | — |
| IAP "remove_ads" in ASC | ⚠️ Last confirmed 2026-07-01; current state unverified | — |
| **iOS App Store Review** | ⚠️ Last confirmed: build 164 rejection issues resolved and corrected build on TestFlight; current ASC state unverified | BLOCKING |
| **TestFlight beta** | ⚠️ Corrected build uploaded; structured beta status unverified | No (post-approval) |
| **Firebase App Check enforcement** | ❌ Not enabled | No (post-launch) |
| **Google API key restrictions** | ❌ Not applied | No (post-launch) |
| **Android build** | ❌ Disabled in CI | Phase 2 |
| **Google Play Console app record** | ❌ Not created | Phase 2 |
| **Marketing website domain live** | ✅ `https://modulosquares.com` reachable during 2026-07-20 audit | No |

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
flutter --version        # CI uses 3.44.2
dart --version           # Must be >=3.7.0
node --version           # Must be 20+
firebase --version       # Any recent CLI
bundle exec fastlane --version  # From packages/mobile
```

- [ ] Flutter 3.44.2 confirmed (match active CI)
- [ ] Node 20+ confirmed
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
| `FASTLANE_TEAM_ID` | Apple Developer Team ID | iOS build |
| `FIREBASE_TOKEN` | Firebase deploy | Web/Firebase deploy |
| `FUNCTIONS_REPO_PAT` | Read access to private Functions companion repo | Functions deploy |

- [ ] All iOS secrets set and non-empty
- [ ] All Firebase secrets set and non-empty
- [ ] `FUNCTIONS_REPO_PAT` has read-only access to the companion repo

**Validate**: Push to `develop` → `ci-cd.yml` → `quality-check` job → confirm it completes green.

---

### 0.4 GitHub-Hosted Runners (No Self-Hosted Dependency)

As of 2026-07-01, the active pipeline (`.github/workflows/ci-cd.yml`) runs entirely on GitHub-hosted runners (`ubuntu-latest` for tests/web/Firebase, `macos-latest` for the iOS build + TestFlight upload). There is no self-hosted runner to keep online for normal builds/deploys — this was previously a workaround for keeping the repo private, which no longer applies now that the repo is public.

The only self-hosted workflow remaining is `install-ios-on-hades.yml` (manual `workflow_dispatch`), which installs a release build onto a physically connected iPhone for on-device testing — this inherently needs a real Mac with a device attached, so GitHub-hosted runners can't do it. It's optional and non-blocking for App Store submission.

- [x] Confirmed `ci-cd.yml` build-ios job runs on `macos-latest` (GitHub-hosted)
- [ ] (Optional) Self-hosted Mac online and reachable, only if you plan to use `install-ios-on-hades.yml` for on-device testing

---

## Phase 1 — iOS App Store Launch (Primary Gate)

### 1.1 App Store Connect — App Record

Go to: **appstoreconnect.apple.com → Apps → (+) New App**

- [ ] App record created with:
  - **Bundle ID**: `com.modulosquares.app.ios`
    *(Must match the provisioning profile exactly — not `com.modulo.squares`)*
  - **SKU**: `modulo-squares-ios-1`
  - **Primary Language**: English (US)
  - **Name**: Modulo Squares
  - **Category**: Games → Puzzle
  - **Age Rating**: 4+

- [ ] Age rating questionnaire completed (no objectionable content, gambling, or violence)
- [ ] Export compliance: **No** custom encryption beyond OS standard
- [ ] App privacy questionnaire completed (data collected: analytics via Firebase, identifiers via AdMob ATT)

**Validate**: App record visible at appstoreconnect.apple.com with bundle ID `com.modulosquares.app.ios`.

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
- [x] Product status: **Ready to Submit**
- [x] Screenshot attached to IAP (required for review)
- [ ] Sandbox tester account created under **Users and Access → Sandbox → Testers**

**Validate**: On a real iPhone, in a release/TestFlight build, tapping "Remove Ads" shows the StoreKit purchase sheet with the correct price.

---

### 1.3 Leaderboard Scope

The repository uses Firestore/callable Functions for leaderboard infrastructure; it does not integrate Apple Game Center. The current falling gameplay screen does not submit scores or expose leaderboard navigation even though legacy/native leaderboard code and the public web leaderboard exist.

- [ ] Decide whether falling-mode leaderboards are part of this release.
- [ ] If yes, wire authenticated falling-run submission and leaderboard navigation, then test server validation and public display.
- [ ] If no, remove leaderboard promises from store and marketing surfaces for this release.

**Validate**: Release copy and the shipped player path agree; no Game Center configuration is required unless a future implementation adds it.

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
4. **Divisor decision** — Falling number with a valid bucket highlighted by the player's action
5. **Progression** — Later-level speed and the 10×10 progress grid

Do not feature a leaderboard in release screenshots unless navigation and score submission are first connected to the active falling-mode screen and verified end to end.

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
  - Current: `modulo,divisibility,math,puzzle,numbers,arcade,logic,brain,strategy,falling,score`
- [ ] **What's New** (optional for initial release): "Welcome to Modulo Squares — guide falling numbers into the right divisor bucket."
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
- [ ] Profile covers bundle ID `com.modulosquares.app.ios`
- [ ] `CODE_SIGN_STYLE = Manual` in Release scheme (or Automatic + team configured)

**Version**
- [ ] `pubspec.yaml` version bumped for this release:
  ```
  version: 1.0.0+2   # current repository value; build MUST increase for the next upload
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
- [ ] Release decision recorded for leaderboard scope; if included, falling-mode navigation and score submission work end to end
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

**Validate**: Submission status in App Store Connect shows "Waiting for Review" or "In Review."

---

## Phase 2 — Android Launch (Follow Phase 1 by ~2 Weeks)

Android has no build job in `ci-cd.yml` yet (removed 2026-06-30 pending Play Store submission readiness; the old manifest-driven `master-pipeline.yml` approach was retired 2026-07-01). When ready for Phase 2, add a `build-android` job directly to `ci-cd.yml` (`ubuntu-latest`, standard `flutter build appbundle --release` + upload step) rather than reviving the old manifest/reusable-workflow pattern.

### 2.1 Add Android Build Job to ci-cd.yml

- [x] `build-android` job added to `.github/workflows/ci-cd.yml` (2026-07-26), gated the same way as `build-ios` (production/staging only)
- [x] Runs on `ubuntu-latest` (Android builds don't need macOS)

**Validate**: Push triggers `ci-cd.yml` → `build-android` job appears and runs. (Not yet exercised on a real push — `ANDROID_KEYSTORE*` GitHub Secrets below still need to be set first.)

**Sign-in options are now platform-exclusive (fixed 2026-07-31)**: `login_screen.dart` previously showed *both* "Sign in with Google" and "Sign in with Apple" on *both* platforms — confirmed via on-device screenshots that Android was rendering an Apple Sign-In button. Fixed by gating each button on `defaultTargetPlatform` (not `dart:io Platform`, which reports the host OS and would make both buttons vanish during `flutter test` on a Mac): Google only shows on Android, Apple only shows on iOS, Email shows on both. Also gated the Google Sign-In SDK initialization itself to Android-only. Verified via widget tests using `debugDefaultTargetPlatformOverride` (reset as the literal last line inside each test body via try/finally — Flutter's test binding checks debug vars are unset immediately after the test callback returns, before any `tearDown()`/`addTearDown()` callback runs) and confirmed on-device on Android (Google + Email only, no Apple). The website has no sign-in at all (`packages/web/src/firebase.ts` only initializes Firestore, no Auth) — confirmed, nothing to fix there.

**Google Sign-In on Android — fixed and verified on-device 2026-07-31**. Two independent bugs stacked, both now fixed:
1. The `modulo-squares-prod` Firebase Android app (`com.modulosquares.app.android`) had zero SHA certificate fingerprints registered that matched either the debug or release/upload keystore. This guarantees `ApiException 10` (`DEVELOPER_ERROR`) before Google's native account picker even appears, for every real-device or CI-signed build. Fixed by registering SHA-1 and SHA-256 for both the debug keystore (`~/.android/debug.keystore`) and the release/upload keystore (`~/.android-keystores/modulo-squares/upload-keystore.jks`) via the Firebase Android SHA API.
2. After the account picker/consent screen (i.e. after bug 1 was fixed), sign-in still failed with `GoogleSignInException(... IllegalArgumentException: requestedScopes cannot be null or empty)`. `packages/mobile/lib/features/auth/login_screen.dart`'s `_signInWithGoogle` called `authorizationClient.authorizationForScopes([])` / `authorizeScopes([])` with an empty scopes list — Android's `play-services-auth` SDK (unlike iOS) rejects an empty list. Fixed by passing `_kGoogleAuthScopes = ['email']` instead.

Verified end-to-end on a real device (Galaxy S24 Ultra, `flutter build apk --debug`, adb install): Google account picker → consent screen → Firebase sign-in → reached the "Choose Your Gamertag" onboarding screen with no errors. `flutter analyze` clean, all 323 tests pass. Not yet re-verified with a **release**-signed build (the debug-keystore SHA fix should cover it, but confirm on the next real release build before shipping).

---

### 2.2 Android Keystore Setup

The keystore is required for production `.aab` builds. Store it securely — **never commit**.

```bash
# Generate keystore (one-time, if not already done)
cd packages/mobile/android
./generate_keystore.sh
```

The script (and `app/build.gradle.kts`'s fallback defaults) use `upload-keystore.jks` /
alias `upload` — use those, not the `modulo_keystore.jks` / `modulo_key` names from an
earlier draft of this doc, unless you deliberately change the script.

Note: on this JDK, PKCS12 keystores (the default) don't support separate store/key
passwords — `keytool` silently ignores a distinct `-keypass`, so `keyPassword` in
`local.properties` must equal `storePassword`.

- [x] Keystore file generated (2026-07-26) and stored outside the repo at
      `~/.android-keystores/modulo-squares/upload-keystore.jks` (`chmod 600`) — **also
      copy this file and its password into 1Password or equivalent; the local copy is not
      backed up anywhere else**
- [x] `android/local.properties` configured:
  ```
  storeFile=/absolute/path/to/upload-keystore.jks
  storePassword=<password>
  keyAlias=upload
  keyPassword=<same password as storePassword>
  ```
- [x] `android/local.properties` and `*.jks` confirmed in `.gitignore`
- [x] `ANDROID_KEYSTORE` (base64 of the `.jks`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (`upload`), `ANDROID_KEY_PASSWORD` set as GitHub Secrets (confirmed set 2026-07-26)

**Validate**: `flutter build appbundle --release` exits 0 and produces `.aab`. ✅ confirmed 2026-07-26 on a real device build.

---

### 2.3 Google Play Console — App Record

Go to: **play.google.com/console → Create app**

- [x] App created (confirmed via API 2026-07-31 — see §2.3c) — Package name: `com.modulosquares.app.android`
- [ ] Content rating questionnaire completed (expected: Everyone) — draft answers in [PLAY_STORE_LISTING_PREP.md](PLAY_STORE_LISTING_PREP.md). No API for this, Play Console UI only.
- [ ] Data safety form completed — draft answers in [PLAY_STORE_LISTING_PREP.md](PLAY_STORE_LISTING_PREP.md) (covers auth/email identifiers that this checklist's short version below omits). No API for this, Play Console UI only.
  - Analytics data (Firebase): disclosed
  - Advertising ID (AdMob): disclosed
  - Email/name/user ID (sign-in): disclosed
  - No health, financial, or location data

**Validate**: App record visible in Play Console.

*App creation itself required a Google Play Console developer account and could only be done by whoever owns that Google account — confirmed done. Content rating and data safety remain UI-only, no Android Publisher API endpoint exists for either.*

---

### 2.3c Store Listing — Populated via API (2026-07-31)

Once the service account was granted Play Console access, the store listing was completed directly via the Android Publisher API (`androidpublisher.googleapis.com`) using `google-play-console-service@modulo-squares-prod.iam.gserviceaccount.com` — no Play Console UI clicking needed for any of this:

- [x] Title, short description, full description set for `en-US` (from `packages/mobile/assets/store/metadata/`)
- [x] Icon, feature graphic, and all 4 phone screenshots uploaded and committed
- [x] Confirmed via a fresh `edits.insert` read-back after commit — all of the above persisted

**Found in the process**: the **internal testing track already has a completed release** (`versionCode 2`, i.e. `1.0.0+2`) — this app is further along than earlier checklist entries suggested. Production track has zero releases; nothing here is publicly visible yet.

**Auth notes for next time** (cost real time working this out): `gcloud auth print-access-token --impersonate-service-account=...` silently ignores `--scopes` and always returns a `cloud-platform`-only token, which the Android Publisher API rejects (same issue as GA4/GTM/Search Console in §3.2b). The fix is the same: `gcloud auth activate-service-account --key-file=...` then request `https://www.googleapis.com/auth/androidpublisher` explicitly on the *directly activated* identity, not via impersonation. Also: the active `gcloud` account reverted between separate tool calls at least once mid-session — reactivate the service account and use its token within the same shell invocation as the API call rather than assuming it persists across calls.

**Not done — deliberately paused, not blocked**: the `remove_ads` in-app product. The legacy `inappproducts.insert` endpoint returns `PERMISSION_DENIED: Please migrate to the new publishing API` for this app — it's been migrated to the newer `monetization.onetimeproducts` model, which requires structured `purchaseOptions` with regional pricing/availability configs and tax category codes, not just a flat price. Getting a real revenue/compliance product wrong via blind API calls is a different risk tier than an image upload; this needs either careful, deliberate construction with an explicit base price and target regions confirmed first, or doing it through Play Console's guided pricing wizard.

---

### 2.3b Play Console Publishing Automation (added 2026-07-31)

CI can now upload signed `.aab` builds straight to the Play Console internal testing track via `fastlane` (`packages/mobile/android/fastlane/Fastfile`, lanes `internal` and `promote_to_production`), authenticated as the `google-play-console-service@modulo-squares-prod.iam.gserviceaccount.com` service account. Trigger via `workflow_dispatch` → environment `PRODUCTION` → `upload_to_play_store: true`.

- [x] Service account exists in `modulo-squares-prod`, Google Play Android Developer API enabled
- [x] Project-level org-policy exception added for `constraints/iam.disableServiceAccountKeyCreation` on `modulo-squares-prod` (the org-wide default blocks new SA keys; this exception is scoped to just this project)
- [x] JSON key created, stored as GitHub secret `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
- [x] `packages/mobile/android/fastlane/{Appfile,Fastfile}` + `Gemfile` added; `upload-play-store` CI job added to `ci-cd.yml`
- [ ] **Manual, no API exists for this**: once the Play Console app record (2.3 above) exists, invite `google-play-console-service@modulo-squares-prod.iam.gserviceaccount.com` under **Play Console → Users and permissions** with at least "Release to testing tracks" + "View app information" permissions. If Setup → API access doesn't already show `modulo-squares-prod` as the linked GCP project, link it there first — the invite option won't appear otherwise.

**Validate**: after the manual invite, a `workflow_dispatch` run with `upload_to_play_store: true` completes and the build shows up under Play Console → Testing → Internal testing.

---

### 2.4 Android AdMob Configuration

- [x] `androidAppId` in `admob_config.dart` = `ca-app-pub-5198775482699756~4572596676` ✅ (already set)
- [x] `androidInterstitialId` = `ca-app-pub-5198775482699756/2729455367` ✅ (already set)
- [x] AdMob App ID in `android/app/src/main/AndroidManifest.xml` matches production:
  ```xml
  <meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-5198775482699756~4572596676"/>
  ```
- [x] `android:allowBackup="false"` confirmed in `AndroidManifest.xml` ✅

**Validate**: Release build on real Android device shows ads (not blank) and no AdMob initialization errors in logcat. ✅ confirmed 2026-07-26 (ad SDK initialized and served a test creative on a real Galaxy S24 running the signed release build).

---

### 2.5 Android Store Assets

Screenshots required for Play Store submission:

| Type | Min Size | Count |
|------|----------|-------|
| Phone | 1080×1920 | 2–8 |
| Tablet (optional) | 1200×1920 | 1–8 |
| Feature graphic | 1024×500 | 1 (required) |
| App icon | 512×512 PNG | 1 (required) |

- [x] Phone screenshots captured on Android device (release build) — 4 captured 2026-07-26 on a real Galaxy S24, cropped to 1080×2120 (under the 2:1 max ratio) at `output/imagegen/play_store/modulo-squares-phone-*.png`. Consider adding 1-2 more at a later game state — these are all from an early, mostly-empty board.
- [x] Feature graphic created (1024×500) — generated 2026-07-31 via HTML/CSS rendered at exact dimensions (`output/imagegen/play_store/modulo-squares-feature-graphic-1024x500.png`), 24-bit RGB confirmed, no alpha
- [x] Adaptive icon files in `android/app/src/main/res/mipmap-*` directories (pre-existing)
- [x] 512×512 app icon ready at `output/imagegen/play_store/modulo-squares-icon-512.png` (reused from `packages/mobile/web/icons/Icon-512.png`, already the right size/no-alpha)
- [x] All assets uploaded to Play Console — via API 2026-07-31, see §2.3c

**Validate**: Play Console store listing preview renders completely.

---

### 2.6 Android IAP Setup

**Note (2026-07-31)**: this app has been migrated to Play's newer one-time-product model —
`inappproducts.insert` (the endpoint this checklist originally assumed) returns
`PERMISSION_DENIED: Please migrate to the new publishing API`. Use
`monetization.onetimeproducts` instead, either via **Play Console → Monetize → Products →
In-app products** (the Console UI already targets the right API underneath) or via
`onetimeproducts.patch?allowMissing=true`, which requires a `purchaseOptions` array with
regional pricing configs and a `taxAndComplianceSettings.productTaxCategoryCode`, not just
a flat price — deliberately not attempted via raw API calls in this session, see §2.3c.

- [ ] Product `remove_ads` created:
  - **Product ID**: `remove_ads` (must match iOS product ID)
  - **Product type**: One-time product, managed (non-consumable)
  - **Price**: $2.99
  - **Status**: Active
- [ ] Test on real Android device with Google Play test account

**Validate**: In release build, "Remove Ads" purchase completes successfully with test account.

---

### 2.6b Test Lab / Pre-Launch Report Login Credentials (fixed 2026-07-31)

Play Console runs an automatic Robo crawl (pre-launch report) on every upload, and Firebase Test Lab uses the same Robo mechanism for manual runs. Both have a "Login credentials" screen with two *different* kinds of fields — don't confuse them:

- **Username / Password** — the actual test account email and password to type in. Always fill these with a real test account's credentials.
- **Username resource name / Password resource name** — *optional*. This is meant to be the target field's native Android `resource-id` (a technical identifier, hence no spaces allowed) — **not** the visible label text ("Email address"). Guessing at one from the label (e.g. `Email_address`) targets nothing and the crawl fails to sign in.

**Leave the resource name fields blank.** Flutter apps don't expose per-widget native Android resource-ids the way Java/Kotlin apps do (the whole UI renders on one Skia canvas), so a resource name can't reliably target a Flutter `TextField` anyway. The actual fix, already in place in `login_screen.dart`'s email sign-in dialog: both `TextField`s have `autofillHints: [AutofillHints.email]` / `[AutofillHints.password]` — this is a real Android Autofill Framework signal, and it's what Robo's auto-detection actually keys off for Flutter apps, not label heuristics or resource-ids.

**Validate**: with the resource name fields blank and a real test account in Username/Password, a Test Lab Robo run or Play Console pre-launch report should successfully sign in via the email/password flow rather than getting stuck at the login screen.

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

`packages/functions` lives in a separate private repo, [NelsonGrey/modulo-squares-functions](https://github.com/NelsonGrey/modulo-squares-functions) (business logic kept off the public repo). `ci-cd.yml`'s `deploy-functions` job checks it out automatically on every push to `main`/`staging`/`develop` (or via `workflow_dispatch`). The active pipeline deploys Hosting and Functions in separate jobs; it does **not** deploy Firestore rules, so rule changes require the explicit rule-deploy step below.

For a manual deploy from your machine, clone the companion repo into `packages/functions` first (it's gitignored, so this won't touch git state):

```bash
# From repo root — one-time per checkout, or whenever you want the latest functions source
git clone --branch main https://github.com/NelsonGrey/modulo-squares-functions.git packages/functions

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
- [ ] Cloud Functions deployed; validate each callable through its client/emulator contract (no public health endpoint is defined in this repository)
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
- [x] GTM container `GTM-TR4PP272` loads GA4 only — fixed 2026-07-31. The **live published version had 3 unidentified foreign tags** (`GT-NNQN3TRC`, `G-XE3S1JCHE6`, `GT-PLWHPB8L`) firing on every pageview alongside the correct `G-FY0QLHWYJN` tag — none of them matched Modulo Squares' GA4 property, Vehicle Vitals', or Nelson Grey's containers; likely auto-linked by GTM's setup wizard from whatever Google account was signed in during original configuration and never noticed. The default workspace already had them removed, just never published — the live site had been silently serving the stale, contaminated version. Published the already-correct draft as version 5; confirmed live now shows only `Google Tag - GA4`. Also found and soft-deleted an orphaned, zero-data-stream duplicate GA4 property (`modulo-squares`, id `490033756`, recoverable until 2026-09-04) — the real property is `modulo-squares-prod` (id `508678430`), which correctly aggregates web + iOS + Android streams. See §3.2b below for how this was done and how to do it again.
- [ ] Consent-gating for GA4 in GTM (Firebase Analytics is mobile-only) — not yet verified; the tag-identity fix above is separate from whether it respects the consent banner
- [ ] App Store / Google Play download links on landing page
- [ ] SEO meta tags present (title, description, og:image for social sharing)

**Validate**: Visit `https://modulo-squares-prod.web.app` — landing page loads, links work, policy pages accessible.

---

### 3.2b Marketing Tools API Access (added 2026-07-31)

GA4, Google Tag Manager, and Search Console are all reachable via API using a dedicated service account — `marketing-tools-service@modulo-squares-prod.iam.gserviceaccount.com`. AdSense and Google Ads are **not** covered by this (see below).

- [x] APIs enabled on `modulo-squares-prod`: `analyticsadmin`, `analyticsdata`, `tagmanager`, `searchconsole`, `adsense`
- [x] Service account created, invited as a user in all three products' own permission systems (GTM account-level User Management, GA4 Property Access Management, Search Console Users and permissions)
- [x] Key created locally (not committed anywhere — treat like any other credential)

**How to authenticate** (the two gotchas that cost real time getting here):
1. `gcloud auth application-default login --scopes=...` using the default/shared gcloud CLI OAuth client is **blocked by Google** for these products' scopes ("This app is blocked") — not a config error, Google no longer allows its shared client to request Analytics/Tag Manager/Search Console scopes at all. Don't retry this path.
2. `gcloud auth print-access-token --impersonate-service-account=...` silently **ignores `--scopes`** and always mints a `cloud-platform`-only token, which none of these three products' APIs accept. The fix: directly activate the key (`gcloud auth activate-service-account --key-file=...` or `gcloud config set account marketing-tools-service@...`) and pass `--scopes` to `print-access-token` on that *directly activated* identity — that code path honors `--scopes`, impersonation does not.

Working pattern:
```bash
gcloud config set account marketing-tools-service@modulo-squares-prod.iam.gserviceaccount.com
TOKEN=$(gcloud auth print-access-token --scopes="https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/tagmanager.readonly,https://www.googleapis.com/auth/webmasters.readonly" --project=modulo-squares-prod)
curl -s -H "Authorization: Bearer $TOKEN" "https://tagmanager.googleapis.com/tagmanager/v2/accounts"
gcloud config set account admin@nelsongrey.com   # restore default identity when done
```
Mutating calls (GTM `create_version`/`publish`, GA4 property delete, etc.) need broader scopes — `tagmanager.edit.containers` + `tagmanager.edit.containerversions` + `tagmanager.publish` for GTM, `analytics.edit` for GA4. Mutating calls also reliably hit the Claude Code auto-mode classifier as a "sensitive action" — plan on running those yourself rather than expecting the agent to execute them directly.

**Key resource IDs** (found during the 2026-07-31 audit): GTM account `6359833234` ("Nelson Grey", shared across projects), Modulo Squares container `accounts/6359833234/containers/255875092` (`GTM-TR4PP272`), default workspace `.../workspaces/5`; GA4 account `355849154` ("Modulo Squares"), real property `properties/508678430` (`modulo-squares-prod`, web+iOS+Android streams, measurement ID `G-FY0QLHWYJN`).

**AdSense and Google Ads are different auth models, not yet connected**: AdSense's permission system doesn't support inviting a service account as a delegated user the way GA4/GTM/Search Console do — it needs the actual AdSense account owner's own interactive OAuth consent (a custom, Google-verified OAuth client, not the shared gcloud client, which is blocked the same way for AdSense scopes). Google Ads additionally requires a developer token application through Google — not worth pursuing without a concrete decision to run paid Ads campaigns first.

---

### 3.3 Custom Domain (Optional but Recommended)

The intended production domain is `modulosquares.com` and was reachable during the 2026-07-20 audit. Console ownership/DNS configuration should still be rechecked before a release:

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

- [ ] Firebase API key for iOS restricted to bundle ID `com.modulosquares.app.ios`
- [ ] Firebase API key for Android restricted to package name `com.modulosquares.app.android`
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
# Push to main, or via GitHub Actions UI:
# Actions → 🚀 CI/CD Pipeline - Build, Test & Deploy → Run workflow
# environment: PRODUCTION
```

- [ ] `determine-environment` job: green
- [ ] `quality-check` job: green (flutter analyze + flutter test)
- [ ] `build-ios` job: green → IPA uploaded to TestFlight
- [ ] `build-web` job: green → web build artifact produced
- [ ] `deploy-web` job: green → Firebase Hosting deployed
- [ ] `deploy-functions` job: green → Cloud Functions deployed from NelsonGrey/modulo-squares-functions
- [ ] `deployment-summary` job: green

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

The app currently logs `app_open` and ad lifecycle events from active paths. The analytics service defines level and leaderboard events, but the active falling-mode screen does not call the level-event methods, and its leaderboard is not connected. Treat those events as implementation work, not already-verified telemetry.

- [ ] Firebase Console → Analytics → Dashboard is showing data from staging/dev usage
- [ ] DebugView tested for events currently connected to active paths:
  - `app_open` ✅
  - `ad_impression` / `ad_dismissed` ✅
- [ ] Instrument and verify falling-mode `level_start` and `level_complete`
- [ ] If leaderboard ships, connect its UI and submission flow before verifying `leaderboard_tab_changed`
- [ ] Key audiences configured:
  - Users who completed Level 1
  - Users who purchased remove_ads
  - Users who viewed leaderboard, only if that surface ships

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
| iOS bundle ID | `com.modulosquares.app.ios` |
| Android package | `com.modulosquares.app.android` |
| IAP product ID | `remove_ads` |
| AdMob iOS App ID | `ca-app-pub-5198775482699756~9962129501` |
| AdMob Android App ID | `ca-app-pub-5198775482699756~4572596676` |
| iOS Interstitial Ad Unit | `ca-app-pub-5198775482699756/8528576954` |
| Android Interstitial Ad Unit | `ca-app-pub-5198775482699756/2729455367` |
| Current app version | `1.0.0+1` |
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
| `FASTLANE_TEAM_ID` | developer.apple.com → Membership → Team ID |
| `FIREBASE_TOKEN` | `firebase login:ci` → copy token |
| `FUNCTIONS_REPO_PAT` | Fine-grained token with read-only access to `NelsonGrey/modulo-squares-functions` |
| `ANDROID_KEYSTORE` | `base64 -i modulo_keystore.jks \| pbcopy` |
| `ANDROID_KEYSTORE_PASSWORD` | Password set during keytool generation |
| `ANDROID_KEY_ALIAS` | `modulo_key` |
| `ANDROID_KEY_PASSWORD` | Key password set during keytool generation |

---

## Appendix C — Known Issues / Decisions Pending

| Issue | Impact | Decision Needed |
|-------|--------|----------------|
| `firebase_crashlytics` ~~not in `pubspec.yaml`~~ | ✅ Added ^5.2.4 + wired in main.dart (PR #73) | — |
| No Android build job in `ci-cd.yml` | Android launch delayed | Add a `build-android` job directly to `ci-cd.yml` when ready for Phase 2 (see Phase 2.1) |
| Marketing domain (`modulosquares.com`) status | ✅ Publicly reachable 2026-07-20 | Reconfirm Firebase custom-domain ownership/certificate in console |
| Slack webhook `${SLACK_WEBHOOK_URL}` not set | No CI notifications | Optional: add Slack secret for pipeline alerts |
| Bundle ID inconsistency in legacy docs | Confusion risk | Canonical ID is `com.modulosquares.app.ios` — treat older `com.modulo.squares` references as stale |
| `storekit_no_response` in simulator | Non-blocking | Expected behavior; IAP must be tested on real device only |
| App Review rejection 2026-07-01 (build 164, 4 issues) | ✅ Resolved | See Document History 1.6. All 4 issues (2.1a, 2.1b, 5.1.1v, 4.3a) resolved; awaiting resubmission |
| `remove_ads` IAP not submitted for review (2.1b) | ✅ Resolved | IAP review screenshot attached and product status set to "Ready to Submit" in App Store Connect |
| Duplicate/old test app in same storefronts (4.3a) | ✅ Resolved | Old test app removed from sale, then deleted outright from App Store Connect — no longer just restricted, fully gone |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-06-17 | Mark Nelson | Initial comprehensive Go Live document synthesized from full codebase and docs audit |
| 1.1 | 2026-06-17 | Mark Nelson | Mark completed: Crashlytics wired, Privacy/Terms pages live, keywords deduped, all security alerts resolved (PRs #70–73) |
| 1.2 | 2026-06-21 | Mark Nelson | Soft launch complete on main. Added: dead bucket visual, guest→player account linking, sign-out, dark gamertag screen, interstitial ads (gamertag + level transitions), Cloud Functions v2 migration, settings screen redesign + tests. iOS 6.5" screenshots captured (6 shots). Readiness summary updated. |
| 1.3 | 2026-06-22 | Mark Nelson | App submitted for App Store review. Version 1.0.0+1, iPhone-only build. Status updated to In Review. |
| 1.4 | 2026-07-01 | Mark Nelson | App Store rejected build 164 (submitted from 1.0.0+2) on 4 grounds: (1) 2.1(a) Sign in with Apple threw an error on iPad — fixed by adding the missing `com.apple.developer.applesignin` entitlement to `Runner.entitlements`; (2) 2.1(b) `remove_ads` IAP never submitted for review — requires manual ASC action (attach screenshot, mark Ready to Submit); (3) 5.1.1(v) no account deletion flow — added `deleteAccount` Cloud Function (wipes Firestore records + deletes the Auth user) plus a "Delete Account" option in the in-game Settings dialog, with tests; (4) 4.3(a) spam/duplicate storefronts — an old test app on the same account overlaps storefronts; requires manual ASC action to restrict its availability. |
| 1.5 | 2026-07-01 | Mark Nelson | Updated App Review status: 2.1 and 5.1.1 are resolved. `remove_ads` IAP is Ready to Submit with required review screenshot attached in App Store Connect. Remaining blocker is 4.3(a) storefront overlap on the old duplicate/test app. |
| 1.6 | 2026-07-01 | Mark Nelson | 4.3(a) resolved: the old duplicate/test app was removed from sale in App Store Connect, which then allowed it to be deleted outright (not just restricted to no storefronts). All 4 rejection issues from build 164 are now resolved; next step is uploading a new build and resubmitting. |
| 1.7 | 2026-07-01 | Mark Nelson | Retired the unused `master-pipeline.yml` (manifest-driven, manual-only, called external private `nelson-grey` reusable workflows + a duplicate `ios-build-self-contained.yml` iOS build implementation), its `.cicd/projects/modulo-squares.yml` manifest, and self-hosted-runner dependencies — none of it was ever the pipeline actually triggered on push. `ci-cd.yml` (fully GitHub-hosted: `ubuntu-latest`/`macos-latest`, no self-hosted runner) is confirmed as the single real CI/CD pipeline. `install-ios-on-hades.yml` (on-device install/testing) is kept as the one intentional self-hosted exception. Updated Phase 0.3, 0.4, 2.1, 4.1, and Appendix C to match. |
| 1.8 | 2026-07-01 | Mark Nelson | Promoted develop → staging; `ci-cd.yml` build-ios failed first attempt because adding the Sign in with Apple entitlement forced a provisioning profile regen, and the Apple Developer account had hit its certificate cap. Cleared old certificates in the Apple Developer portal, re-ran the failed job, and it succeeded (33m32s) — new build uploaded to TestFlight from `staging`. All 4 App Review rejection issues (2.1a, 2.1b, 5.1.1v, 4.3a) are now fixed in a build that's actually reached TestFlight. Next: promote to `main` and submit for App Store review. |
| 1.9 | 2026-07-01 | Mark Nelson | Promoted staging → main (with explicit "Approved" per branch protection convention). Production `ci-cd.yml` run on main completed fully green in 26m33s — quality-check, build-web, build-ios (production TestFlight upload), and Firebase production deploy all succeeded. All 4 App Review rejection issues are fixed in a real production build now on TestFlight. Only remaining step: select this build in App Store Connect and submit for review. |
| 2.0 | 2026-07-20 | Codex | Reconciled toolchain, private Functions deployment, explicit Firestore rules deployment, current falling-mode metadata, live marketing domain, and externally unverified App Store state after a full repository/documentation audit. |

---

*This document supersedes individual platform checklists for launch purposes. Those files (`Testflight_Readiness_Checklist.md`, `Release_Checklist.md`, `Setup_Checklist.md`) remain valid as reference for their specific scopes.*
