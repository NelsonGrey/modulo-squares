# Store Assets

**Updated**: 2026-07-20

Store-console requirements change. Verify current Apple/Google requirements at submission time; this file records repository sources and current product messaging.

## Canonical sources

| Asset | Location |
|---|---|
| Master icon | `icons/icon-modulo-squares.png` |
| Mobile launcher source | `packages/mobile/assets/icons/icon.png` |
| iOS icon set | `packages/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset` |
| Android icons | `packages/mobile/android/app/src/main/res/mipmap-*` |
| React web icons | `packages/web/public` |
| Flutter web icons | `packages/mobile/web` |
| Store description | `packages/mobile/assets/store/metadata/description.txt` |
| Short description | `packages/mobile/assets/store/metadata/short_description.txt` |
| Keywords | `packages/mobile/assets/store/metadata/keywords.txt` |
| iOS screenshots | `packages/mobile/assets/store/screenshots/ios-6.5` |

The clean-landing-centered icon was promoted to production on 2026-07-07. The prior icon set is archived under `icons/archive/2026-07-08-previous-icon`.

## Current product story

Store copy and screenshots must show the falling divisor-bucket game:

- guide a falling number across ten lanes;
- choose a bucket that divides it evenly;
- build combos and fill the progress grid;
- avoid the dead bucket and remainder penalties;
- compete on global/weekly leaderboards;
- play free with an optional one-time Remove Ads purchase.

Do not use the retired 4x4 tile-clearing description.

## Current screenshot set

The repository contains six iOS 6.5-inch screenshots:

- `01-title-rules.png`
- `02-active-gameplay.png`
- `03-paused-run.png`
- `04-settings.png`
- `05-sign-in-sign-up.png`
- `06-create-gamertag.png`

Before submission, verify that App Store Connect accepts this device class for the current app configuration and add any required sizes directly from a current simulator/device.

## Icon generation

```bash
./scripts/apply-new-icon.sh icons/icon-modulo-squares.png
```

Review every platform output and confirm the iOS marketing icon is 1024x1024 RGB without alpha.

## Submission checklist

- [ ] Metadata describes falling mode and fits current store limits.
- [ ] Screenshots match the submitted binary and contain no debug overlays.
- [ ] Icon matches the binary and has no prohibited transparency.
- [ ] Privacy/support/marketing URLs are live.
- [ ] Privacy answers reflect Auth, Firestore, Analytics, Crashlytics, AdMob/AdSense, ATT/UMP, and IAP.
- [ ] `remove_ads` product copy and review screenshot are current.
- [ ] Android feature graphics/screenshots are created when Phase 2 begins.

Store-console upload status is tracked in [GO_LIVE_RUNBOOK.md](GO_LIVE_RUNBOOK.md), not inferred from local files.
