# Production Release Checklist

**Updated**: 2026-07-20
**App version**: `1.0.0+2`

Use [GO_LIVE_RUNBOOK.md](GO_LIVE_RUNBOOK.md) for current launch blockers and review history. This checklist is for a repeatable release.

## Source and version

- [ ] Confirm target branch is synchronized with its upstream.
- [ ] Confirm `pubspec.yaml` version/build is intentional.
- [ ] Review user-facing changes and update store metadata/screenshots.
- [ ] Update current documentation and release notes.
- [ ] Confirm private Functions branch is compatible with the public client.

## Validation

- [ ] `npm ci` succeeds at the root.
- [ ] `npm run lint` passes.
- [ ] `npm run check` passes.
- [ ] `npm run build:web` passes.
- [ ] `flutter analyze` passes in `packages/mobile`.
- [ ] `flutter test --coverage` passes.
- [ ] iOS release build or TestFlight build succeeds.
- [ ] Android app bundle succeeds when Android is in release scope.
- [ ] Firestore rules and private Functions tests pass.

## Mobile acceptance

- [ ] Apple, Google, and email sign-in work on supported real devices.
- [ ] New and returning gamertag flows work.
- [ ] Falling game start/pause/movement/scoring/level-up work.
- [ ] Visual cues and high score persist.
- [ ] Resolve leaderboard scope: wire falling-run submission/navigation and test it, or remove leaderboard claims from release/store surfaces.
- [ ] ATT/UMP and interstitial cadence comply with policy.
- [ ] `remove_ads` purchase and restore work; ads remain removed after restart.
- [ ] Sign out/account link paths work.
- [ ] Delete Account removes the account and expected backend data.

## Website acceptance

- [ ] All nine routes render directly and through client navigation.
- [ ] Canonical metadata, robots, and sitemap are correct.
- [ ] Leaderboard loads current Firestore data and handles empty/error states.
- [ ] Consent defaults to denied and saved choices restore correctly.
- [ ] GTM/GA4 and AdSense behavior matches policy disclosures.
- [ ] Mobile/tablet/desktop layout and keyboard accessibility are checked.

## Deployment

- [ ] Promote through `develop` -> `staging` -> `main` as appropriate.
- [ ] Confirm `quality-check`, `build-web`, and `build-ios` results.
- [ ] Confirm Hosting deployment and production route smoke test.
- [ ] Confirm private Functions checkout/deployment result.
- [ ] Deploy Firestore rules explicitly if changed.
- [ ] Confirm TestFlight build processing and internal smoke test.

## Store submission

- [ ] App Store record, bundle ID, privacy answers, support/privacy URLs, screenshots, and age rating are current.
- [ ] `remove_ads` is associated with the submission as required.
- [ ] Correct TestFlight build is selected.
- [ ] Dispatch production App Store submission only after manual verification.
- [ ] Record review state/date in `GO_LIVE_RUNBOOK.md`.

## Post-release

- [ ] Confirm production authentication, Firestore, Functions, ads, purchases, and deletion.
- [ ] Check Crashlytics, Analytics, Functions logs, Hosting, and cost dashboards.
- [ ] Confirm public store listing/version if approved.
- [ ] Triage regressions and document rollback/hotfix decisions.
