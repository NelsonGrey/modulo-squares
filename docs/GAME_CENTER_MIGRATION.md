# Moving to Game Center + nelsongrey.com

**Decision (2026-10-07):** iOS-only, Game Center instead of Firebase accounts
and the Firestore leaderboard, and the website lives under
`nelsongrey.com/games/modulo-squares/` instead of `modulosquares.com`
(which earns no ad revenue). Android is shelved. Same architecture as
Intercept Echo and Memory Survival.

This is **built but not cut over.** Nothing here is live until the steps in
"Cutover" are done. The live 1.0.1 app still uses Firebase and
`modulosquares.com`, so both must keep running until the new build is
released and adopted.

## What is built (branches, unmerged)

### `modulo-squares` — `feat/game-center-only`
- `lib/gamecenter/`: Game Center auth, opt-in connection (first-run prompt,
  Settings), gated leaderboard/achievement calls, fakes for tests.
- Game screen reports the best score and achievements; the leaderboard button
  opens Game Center's native UI.
- Removed: Firebase (core/auth/firestore/functions/analytics/crashlytics/
  app check), Google + Apple sign-in, gamertag, profile, password flows, the
  in-app leaderboard, delete-account, `GoogleService-Info*.plist`,
  `google-services*.json`, per-env mobile config switching.
- Purchases: `remove_ads` is still the same non-consumable product. The
  server-side `validatePurchase`/`getEntitlements` calls are gone; the
  entitlement is granted from the StoreKit result and restored with Restore
  Purchases (works for existing buyers on the same Apple ID).
- Legal links in Settings point at nelsongrey.com.

### `nelson-grey` — `feat/modulo-squares-pages`
- `games/modulo-squares/`: home, how-to-play, strategy guide, modular
  arithmetic explainer, privacy, terms, cookies, support, plus sitemap entries.

## Cutover (when ready)

1. **App Store Connect**: create the leaderboard + 15 achievements
   (`docs/GAME_CENTER_SETUP.md`). Update Privacy Policy, Support and Marketing
   URLs to the nelsongrey.com pages. Update the App Privacy ("nutrition
   label") answers: no account data, no analytics/crash data, advertising
   identifier via AdMob only.
2. **TestFlight** the new build and run the device checklist in
   `GAME_CENTER_SETUP.md`. Bump the version (1.1.0).
3. **Deploy the website** (`nelson-grey` → merge → Firebase Hosting). Confirm
   `https://nelsongrey.com/games/modulo-squares/privacy` etc. return 200
   *before* submitting, since the app and store listing link there.
4. **Submit 1.1.0** and wait for approval + adoption.
5. **Redirect `modulosquares.com`** to the matching nelsongrey.com paths with
   301s (home, `how-it-works`→`how-to-play`, `strategy-guide`,
   `modular-arithmetic-explained`, `privacy`, `terms`, `cookies`, `support`;
   `download`/`pricing`/`leaderboard`→home). Keep the domain registered for at
   least a year (old store listings, promo kit, backlinks).
6. **`app-ads.txt`**: nelsongrey.com already serves it with the publisher ID.
   Make sure the App Store developer-website URL's domain is nelsongrey.com,
   then confirm AdMob still verifies.
7. **Decommission Firebase** only after 1.1.0 is the dominant version (old
   builds call it): archive `modulo-squares-functions`; remove
   `packages/functions`, `packages/firestore-rules`, `packages/firebase-utils`,
   `packages/web`, the `deploy-web` / `deploy-functions` CI jobs, the
   `setup-firebase` action, `firebase*.json`; shut down the three GCP projects
   (export anything needed first); remove the IAM condition auditor; close the
   related issues (modulo-squares #364–369, functions #12–14).
8. **Docs sweep**: many `docs/*.md` still describe Firebase/auth/leaderboard
   (Firebase_First_Standard, Database_Schema, Backend_Services_Guide,
   Mobile_Config_Setup, Analytics, ...). Rewrite or delete.

## Known trade-offs and follow-ups

- **No crash reporting or analytics** in the app anymore (matches Intercept
  Echo and the new privacy policy). Add something deliberately if wanted.
- **Existing leaderboard data and gamertags are not migrated.** Players on
  1.0.1 keep a local best score (stored on device) and it is posted to Game
  Center the first time they connect.
- **Existing accounts**: users on 1.0.1 lose nothing they can see in 1.1.0
  except the account itself. Server-side account data is removed when the
  Firebase projects are shut down; do this after announcing it in the 1.1.0
  release notes.
- **YouTube tutorial pipeline** (`scripts/store-promo/*youtube*`,
  `lib/main_youtube_capture.dart`): the account/gamertag/sign-in scenes are
  gone from the capture entry point; the render script and asset validator
  still expect the old raw recordings, so re-record/rework that pipeline
  before re-rendering tutorials.
- **Android** build config no longer applies Google Services/Crashlytics; Game
  Center is iOS-only, so Android would need Play Games Services if revived.
- **Social/store copy** that mentions "global leaderboard", gamertags or
  accounts (promo kit copy, app store metadata) should be reviewed.
