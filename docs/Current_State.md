# Modulo Squares Current State

**Audited**: 2026-07-20  
**Scope**: tracked repository, active configuration, workflows, source, tests, store metadata, and documentation  
**Authority**: code and active workflow take precedence over planning documents

## Executive summary

Modulo Squares is a public monorepo with a Flutter mobile game, a React marketing/leaderboard site, Firebase security rules, shared TypeScript Firebase helpers, and extensive release automation. The shipping gameplay is the falling-number mode. A substantial legacy board-clearing implementation remains compiled and tested but is not reachable through `GameScreen`.

The project is on `develop`, synchronized with `origin/develop` at the time of this audit. Local `main` and `staging` branches are stale relative to their remotes; documentation and work should use the remote branches or refresh local refs before branch comparisons.

## Live components

| Component | Current implementation | Notes |
|---|---|---|
| Mobile app | Flutter/Dart in `packages/mobile` | Version `1.0.0+2`; iOS and Android platform projects are tracked |
| Gameplay | `GameScreen` delegates to `FallingModuloGameScreen` | Ten-lane falling divisor game |
| Authentication | Firebase Auth | Apple, Google, and email/password UI; gamertag required after sign-in |
| Data | Cloud Firestore | Users, gamertags, leaderboards, purchases, entitlements, profiles/stats |
| Server API | Firebase callable Functions v2 | Source is in private companion repo, not this public checkout |
| Monetization | AdMob + StoreKit/Google Play IAP | `remove_ads` is live in code; `premium` is represented but future-facing |
| Mobile analytics | Firebase Analytics and Crashlytics | Initialization is guarded so recoverable startup remains possible |
| Website | React 19 + TypeScript + Vite 8 + Tailwind CSS 4 | Firebase Hosting serves `packages/web/dist` |
| Web analytics/ads | GTM/GA4 + AdSense | Consent defaults to denied and is persisted in local storage |
| CI/CD | `.github/workflows/ci-cd.yml` | GitHub-hosted except optional HADES device install workflow |

## Gameplay truth

The active engine uses ten lanes. Each level shuffles buckets `1` through `9` and one dead bucket `0`. A generated number falls in the selected lane.

- Divisible landing: `fallingValue % bucketValue == 0`
- Success score: `fallingValue * bucketValue`; bucket `1` awards zero
- Miss penalty: `fallingValue * bucketValue * remainder`
- Dead-bucket penalty: the falling value
- Score floor: zero
- Combo: increments on success and resets on a miss
- Progress: success adds one square; misses subtract the remainder; dead buckets subtract one
- Level-up: fill balance reaches 100
- Number range: `6..18` at level 1, expanding by level
- Drop interval: 6000 ms at level 1, multiplied by `0.96` per level, with a 1200 ms floor

`GameBoard`, `GameProvider`, `InstructionsScreen`, and related tile-grid code describe the prior board-clearing mode. They remain useful test/reference assets but do not define the current player experience.

## Data and API boundaries

Public Firestore reads are allowed for global, daily, and weekly leaderboard data. Authenticated users can read/write their own user/profile/stat documents and create their initial gamertag index. Client writes to leaderboards, purchases, and entitlements are denied.

The mobile client currently calls these server functions:

- `startScoreSession`
- `submitScore`
- `submitDailyScore`
- `submitWeeklyScore`
- `validatePurchase`
- `getEntitlements`
- `deleteAccount`

These calls exist across the mobile codebase, but the current `FallingModuloGameScreen` does not invoke the leaderboard service. Its implementation must be reviewed in `NelsonGrey/modulo-squares-functions`; this repository documents only the client contract and deployment integration.

## Website truth

The React site has nine routes: home, how it works, download, pricing, leaderboard, privacy, terms, cookies, and support. The leaderboard directly reads the top 50 global and current-week score documents from Firestore.

Google Tag Manager container `GTM-TR4PP272` is loaded from `index.html`. Consent Mode defaults analytics and ad storage to denied. AdSense uses publisher `ca-pub-5198775482699756`; ad slot IDs come from the production Vite environment.

## Delivery truth

The CI workflow maps branches to Firebase environments:

- `develop` -> development
- `staging` -> staging
- `main` -> production

Deployable runs build the web app, deploy Hosting, and check out/deploy the private Functions repository. The iOS/TestFlight job runs only for staging and production; development skips it. App Store submission is a separate manual production-only workflow input and operates on an already uploaded build. Android CI remains intentionally disabled.

## Release state

Repository history confirms that all four issues from the 2026-07-01 App Review rejection were addressed and a production build reached TestFlight. The last documented next step was to select the corrected build and resubmit it in App Store Connect. No indexed App Store listing was found during this audit, so the runbook treats App Store approval/public availability as externally unverified.

## Known documentation and code risks

- The private Functions source is unavailable in a normal public checkout, so API internals cannot be verified here.
- Root scripts that target `packages/functions` fail until the companion repo is cloned.
- The active app and several legacy game classes coexist; imports, not filenames alone, determine live behavior.
- Leaderboard services/screens and public web reads exist, but falling gameplay does not currently submit scores or expose leaderboard navigation; product/store claims must not imply otherwise until wired.
- Flutter's older `WebsiteScreen` contains placeholder links and form behavior, but Firebase Hosting serves the React site instead.
- Android delivery is represented in source and signing docs but is not built by the active CI workflow.
- `packages/firebase-utils` has a configured Vitest command but no test files; the command currently exits nonzero.
- App Check is integrated but production enforcement remains a post-launch/manual control.
- Store status, product status, certificates, secrets, Firebase console settings, DNS, analytics dashboards, and API-key restrictions are external and must be verified in their consoles.

## Canonical documents

Use these documents for current work:

1. `Current_State.md` for the audited implementation snapshot.
2. `GO_LIVE_RUNBOOK.md` for external release gates and historical App Review context.
3. `Game_Mechanics.md`, `System_Architecture.md`, `Database_Schema.md`, and `Api_Documentation.md` for engineering behavior.
4. `Ci_Cd_Setup.md`, `Environment_Setup.md`, and `Testing.md` for operations.
5. `Documentation_Index.md` to identify historical or planning-only material.
