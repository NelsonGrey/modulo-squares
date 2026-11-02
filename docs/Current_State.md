# Modulo Squares Current State

**Updated**: 2026-11-02  
**Scope**: the `feat/game-center-only` branch (release 1.1.0). `develop` still describes the 1.0.x Firebase build until this branch merges.  
**Authority**: code and the active workflow take precedence over planning documents.

## Executive summary

Modulo Squares is an iOS falling-number arcade puzzle built with Flutter. As of 1.1.0 it has no backend of its own: identity, the leaderboard and achievements are Game Center, and the best score is also stored on the device. The migration plan and cutover checklist are in [GAME_CENTER_MIGRATION.md](GAME_CENTER_MIGRATION.md); the App Store Connect records are specified in [GAME_CENTER_SETUP.md](GAME_CENTER_SETUP.md).

The shipped 1.0.1 build still uses Firebase and modulosquares.com. Those stay up until 1.1.0 is the dominant version.

## Components

| Component | Implementation | Notes |
|---|---|---|
| Mobile app | Flutter/Dart in `packages/mobile` | Version `1.1.0+1`; iOS only (Android shelved) |
| Gameplay | `GameScreen` -> `FallingModuloGameScreen` | Ten-lane falling divisor game, see [Game_Mechanics.md](Game_Mechanics.md) |
| Identity, leaderboard, achievements | Game Center via `games_services` | `lib/gamecenter/`; connection is optional and prompted on first run |
| Monetization | AdMob + StoreKit | Non-consumable `remove_ads`; entitlement comes from the StoreKit result and Restore Purchases, no server validation |
| Analytics / crash reporting | None | Deliberate, matches Intercept Echo and Memory Survival |
| Website | `nelson-grey` repo, `nelsongrey.com/games/modulo-squares/` | Live; the legal links in Settings point there |
| CI/CD | `.github/workflows/ci-cd.yml` | GitHub-hosted; TestFlight upload from `staging`/`main` |

## Legacy components (retained until decommission)

`packages/web`, `packages/functions` (private companion repo), `packages/firestore-rules`, `packages/firebase-utils`, the `firebase*.json` descriptors and the three Firebase/GCP projects exist only to serve 1.0.x clients and modulosquares.com. Do not extend them. Removal is step 7 of the migration runbook.

## Open items

- Create the Game Center leaderboard and 15 achievements in App Store Connect and run the device checklist in GAME_CENTER_SETUP.md.
- Update Privacy, Support and Marketing URLs and the App Privacy answers in App Store Connect (the fastlane metadata already points at nelsongrey.com).
- Ship 1.1.0, then redirect modulosquares.com and decommission Firebase per the runbook.
- The YouTube tutorial pipeline still expects the old account/sign-in recordings.
- Remaining historical docs (Go-Live Runbook, Security, Analytics, Product/Business requirements) still describe the Firebase era; the index labels them.
