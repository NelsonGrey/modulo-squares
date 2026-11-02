# System Architecture

**Updated**: 2026-11-02 (release 1.1.0, Game Center)

## System context

```text
Flutter iOS app
  Game engine (local)          best score kept on device (SharedPreferences)
  lib/gamecenter/ ----------> Game Center: leaderboard + 15 achievements
  AdMob + StoreKit             remove_ads entitlement from StoreKit result
        |
        '--> legal / support links --> nelsongrey.com/games/modulo-squares/

GitHub Actions: analyze + test, build iOS, upload to TestFlight
```

There is no application server, database or account system.

## Mobile runtime

Startup in `packages/mobile/lib/main.dart` registers services with GetIt, initializes ads and purchases, then renders `GameScreen`, a thin boundary around `FallingModuloGameScreen`. On first run the game offers to connect to Game Center; the choice is stored and can be changed in Settings.

### Layers

- `core/di`: service registration.
- `core/services`: ads, cache, consent, error handling and purchases.
- `gamecenter/`: Game Center sign-in and connection state, gated leaderboard and achievement calls, the achievement rules tracker (unit-tested), IDs in `game_center_ids.dart`, and fakes for tests.
- `features/game`: the falling mode, Settings page and pause overlay.
- `shared`: reusable models and widgets.

### Game Center behavior

- The game reports the best score to leaderboard `modulo_squares_high_score` and unlocks achievements as the tracker detects them. Calls are no-ops when the player has not connected.
- Game Center keeps only the best score per player, so resubmitting is harmless.
- The leaderboard button opens Game Center's native UI.
- A best score saved on the device by an older build is posted the first time the player connects.

## Security and privacy boundaries

- No account data, analytics or crash data leave the device. AdMob uses the advertising identifier under App Tracking Transparency.
- Entitlements are not server-validated; `remove_ads` is low-value and restorable with the same Apple ID.
- Secrets used by CI (signing, App Store Connect) live in GitHub environments.

## Delivery

`.github/workflows/ci-cd.yml` is the only active pipeline. `develop` runs analyze and tests, `staging` and `main` also upload to TestFlight, and App Store submission is a manual production-only step. Archived workflows under `.github/workflows/archive` are historical.

## Legacy

Firebase Auth, Firestore, Cloud Functions and the React site served 1.0.x. They remain deployed only until 1.1.0 is adopted. See [GAME_CENTER_MIGRATION.md](GAME_CENTER_MIGRATION.md).
