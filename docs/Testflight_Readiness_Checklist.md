# TestFlight Readiness Checklist

Use this checklist before every TestFlight upload. Work top-to-bottom; do not
submit until all items are checked.

---

## 1. Version & Build Number

| Field | Current | Action |
|-------|---------|--------|
| `pubspec.yaml` version | `1.0.0+1` | Bump `+build` for every new upload; bump `semver` for every functional release |
| Bundle ID | `com.nelsongrey.modulosquares.app.ios` | Must match App Store Connect exactly |
| Deployment target | iOS 15.0 | Do not lower without explicit sign-off |

**Version bump procedure:**
```bash
# In packages/mobile/pubspec.yaml
# version: <semver>+<build>   e.g.  0.0.3+3
# The +build number MUST be unique per upload to App Store Connect.
```

---

## 2. Local Quality Gates (automated)

Run `scripts/preflight.sh` from the repo root (see below) or execute manually:

```bash
cd packages/mobile
flutter analyze --no-pub          # must exit 0
flutter test --no-pub             # must exit 0, all tests pass
flutter build ios --simulator     # smoke-build, must exit 0
```

- [ ] `flutter analyze` — **No issues found**
- [ ] `flutter test` — **All tests pass** (run full suite or approved release subset)
- [ ] Simulator build succeeds

---

## 3. Signing & Certificates

- [ ] Distribution certificate valid in Keychain (not expired)
- [ ] Provisioning profile `App Store` is installed and not expired
- [ ] Profile covers bundle ID `com.nelsongrey.modulosquares.app.ios`
- [ ] `CODE_SIGN_STYLE = Manual` configured in Release scheme

Reference: [IOS_CERTIFICATE_SETUP.md](IOS_CERTIFICATE_SETUP.md),
[IOS_SIGNING.md](IOS_SIGNING.md)

---

## 4. App Store Connect Setup

- [ ] App record exists for bundle ID `com.nelsongrey.modulosquares.app.ios`
- [ ] Build number for this upload is **higher than** all previously uploaded builds
- [ ] App privacy questionnaire completed (data collection: none / analytics only)
- [ ] Export compliance acknowledged (no custom encryption beyond OS)
- [ ] Age rating set (appropriate for puzzle/math game)

---

## 5. In-App Purchases (StoreKit)

The `remove_ads` product drives IAP. In simulator, StoreKit returns
`storekit_no_response` — **this is expected and non-blocking** during development.

- [ ] `remove_ads` product is configured in App Store Connect > In-App Purchases
- [ ] Product is in **"Ready to Submit"** or **"Approved"** state in ASC
- [ ] Tested on **real device** with a StoreKit sandbox account
- [ ] Purchase flow + restore flow exercised on real device
- [ ] Sandbox tester account created in App Store Connect > Users

---

## 6. Firebase / Auth

Authentication is account-required in the active production flow.

- [ ] Confirm `google-services.json` / `GoogleService-Info.plist` are for the
  **production** Firebase project (not dev/staging)
- [ ] Required providers for production auth flow are enabled in Firebase
  (Google / Apple / Email as applicable)
- [ ] Firestore security rules deployed (`packages/firestore-rules`)
- [ ] `GOOGLE_REVERSED_CLIENT_ID` URL scheme present in `Info.plist`

---

## 7. Admob / Ads

- [ ] AdMob app ID in `Info.plist` (`GADApplicationIdentifier`) matches the
  **production** AdMob app
- [ ] Test ad unit IDs replaced with **production** ad unit IDs in
  `ad_service.dart` / constants file
- [ ] Interstitial ad cadence gate tested (ads should not fire more than once
  per session under the current threshold)

---

## 8. App Icons & Launch Screen

- [ ] App icon set present in `ios/Runner/Assets.xcassets/AppIcon.appiconset`
  with all required sizes (1x, 2x, 3x for all required roles)
- [ ] No alpha channel in App Store icon (1024×1024 PNG, RGB only)
- [ ] Launch screen (`LaunchScreen.storyboard`) renders correctly on
  iPhone SE (small) and iPhone Pro Max (large) form factors
- [ ] App icon matches 1024×1024 asset (no gradient-only icon per Apple HIG)

Reference: [STORE_ASSETS.md](STORE_ASSETS.md)

---

## 9. Privacy & Permissions

- [ ] `NSUserTrackingUsageDescription` in `Info.plist` (required for AdMob ATT)
- [ ] ATT prompt fires before first ad impression (check `consent_service.dart`)
- [ ] No camera, microphone, contacts, or location permissions requested unless
  actually used
- [ ] App Privacy label in App Store Connect reflects actual data use

---

## 10. Game Center / Entitlements

- [ ] `com.apple.developer.game-center` entitlement in `Runner.entitlements`
  if Game Center leaderboard is enabled
- [ ] Leaderboard ID in code matches the ID configured in App Store Connect
- [ ] Tested authentication on real device (simulator GC is unreliable)

---

## 11. Real-Device Smoke Test

Before every TestFlight upload, install the **Release** build on a real iPhone:

```bash
flutter run --release -d <REAL_DEVICE_UDID>
```

Verify:
- [ ] App launches without crash
- [ ] Falling Mode: tile falls, score burst appears, spawn delay active at start
- [ ] Falling Mode: positive burst = gold pill, negative burst = red diamond
- [ ] Start/Pause controls work and game does not auto-start on screen open
- [ ] Progress grid is 10x10 and aligns with bottom lane area
- [ ] Successful modulo fills progress; failure removes remainder squares
- [ ] Level completion requires full progress grid fill
- [ ] IAP flow: tapping "Remove Ads" prompts StoreKit (sandbox)
- [ ] Interstitial ad: appears between levels for free logged-in users, and does
  not appear for ad-removed users
- [ ] Settings / visual cues toggle saves across restarts (SharedPreferences)

---

## 12. Archive & Upload

```bash
# From packages/mobile
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist

# Then upload via Transporter or:
xcrun altool --upload-app -f build/ios/ipa/*.ipa \
  -u "$APPLE_ID" -p "$APP_SPECIFIC_PASSWORD"
```

- [ ] Archive builds cleanly (`flutter build ipa` exits 0)
- [ ] Upload accepted by App Store Connect (no binary rejection email)
- [ ] Build appears in TestFlight within ~30 minutes
- [ ] Internal testers notified

---

## 13. Go / No-Go Verdict

**Blocking (must fix before upload):**
- Any `flutter analyze` issue
- Any failing test
- Expired signing certificate or provisioning profile
- Build number collision with a previously uploaded build
- Production ad unit IDs not set
- Production Firebase project not configured

**Non-blocking (track, fix in next sprint):**
- `storekit_no_response` in simulator
- Firebase `admin-restricted-operation` in simulator
- Flutter upgrade available notice

---

*Last updated: 2026-06-02*
