# iOS Production Fast Track

**Last Updated**: June 2, 2026
**Goal**: Shortest safe path from current state to TestFlight and App Store submission.

---

## Current Status Snapshot

Validated now:
- iOS runner readiness check passes on host machine.
- `flutter analyze` passes in `packages/mobile`.
- Focused falling-game release tests have passed in recent runs.

Still required before publish:
- Real-device release validation.
- Final production config verification (Firebase, AdMob, IAP).
- Signed IPA upload and TestFlight sanity pass.
- App Store metadata and review submission.

---

## Critical Path (Do These First)

1. **Code freeze**
   - Stop feature additions.
   - Allow only release blockers and compliance fixes.

2. **Version bump**
   - Update `packages/mobile/pubspec.yaml` version to next build number.
   - Ensure build number is unique in App Store Connect.

3. **Release quality gates**
   - Run analyze/test/build commands in `packages/mobile`:
     - `flutter analyze`
     - `flutter test`
     - `flutter build ios --release --no-codesign`

4. **Production config audit**
   - Firebase production plist.
   - Production AdMob IDs.
   - `remove_ads` IAP product active in App Store Connect.
   - ATT usage strings and consent flow verified.

5. **Real device acceptance pass**
   - Install release build on physical iPhone.
   - Validate falling-mode gameplay loop, start/pause, progress-grid completion,
     ad behavior by tier, sign-in, leaderboard submission, purchase + restore.

6. **Archive and upload**
   - Build IPA via CI or local fastlane/script path.
   - Upload to TestFlight.
   - Verify processing success and internal tester install.

7. **Submit for review**
   - Finalize metadata, screenshots, privacy labels, and age rating.
   - Submit binary to App Review.

---

## 72-Hour Execution Plan

### Day 0 (Today)
- Freeze scope and branch.
- Run quality gates and fix any blockers.
- Complete production config audit checklist.

### Day 1
- Real-device release test session.
- Fix critical issues only.
- Re-run quality gates.

### Day 2
- Upload signed build to TestFlight.
- Internal test sweep (install, auth, gameplay, ads, IAP, leaderboard).
- Prepare final release notes.

### Day 3
- Submit to App Review.
- Monitor review messages and respond same day.

---

## Go / No-Go Rules

**No-Go (must fix):**
- Any analyzer errors.
- Any deterministic failing tests.
- App crash or broken core gameplay loop on real device.
- Wrong production identifiers/config for Firebase, AdMob, or bundle ID.
- IAP not retrievable/restorable in sandbox real-device test.

**Go (safe to submit):**
- All quality gates green.
- Real-device smoke suite passes.
- TestFlight install verified.
- App Store metadata and compliance sections complete.

---

## Related Docs

- [TestFlight Readiness Checklist](TESTFLIGHT_READINESS_CHECKLIST.md)
- [TestFlight Upload Guide](TESTFLIGHT_UPLOAD_GUIDE.md)
- [iOS Certificate Setup](IOS_CERTIFICATE_SETUP.md)
- [iOS Signing](IOS_SIGNING.md)
- [Player Access Tiers](PLAYER_ACCESS_TIERS.md)
