# System Architecture

**Updated**: 2026-07-20

## System context

```text
Native Flutter app --------------------+
  Firebase Auth                        |
  Firestore reads/owned writes         |--> Firebase projects (dev/staging/prod)
  Callable Functions ------------------+      Auth, Firestore, Functions,
  Analytics/Crashlytics/App Check      |      Analytics, Crashlytics, Hosting
  AdMob + platform IAP                 |
                                       |
React website -------------------------+
  public Firestore leaderboard reads   |
  GTM/GA4 + AdSense under consent       |

GitHub Actions
  builds Flutter and React
  uploads iOS to TestFlight
  deploys Hosting
  checks out private Functions repo and deploys Functions
```

## Repository boundaries

### Public repository

- Flutter clients and platform projects
- React website
- Firestore rules
- Firebase environment descriptors
- shared Firebase utilities
- build/release automation
- public product and engineering documentation

### Private companion repository

Cloud Functions business logic is stored in `NelsonGrey/modulo-squares-functions`. It is checked out to ignored path `packages/functions` by CI or manually by an authorized developer. The public repository therefore exposes client contracts and deployment wiring, not server implementation details.

## Mobile runtime

Startup in `packages/mobile/lib/main.dart`:

1. Register services with GetIt.
2. Initialize Firebase and guarded platform services.
3. Attach Firebase Analytics navigation observation when Firebase is ready.
4. Show a recovery screen if required Firebase initialization fails.
5. Observe Firebase Auth state.
6. Require a gamertag after authentication.
7. Render the React-independent Flutter `WebsiteScreen` on Flutter web or `GameScreen` on native platforms.

`GameScreen` is intentionally a thin boundary around `FallingModuloGameScreen`.

### Mobile layers

- `core/auth`: provider-specific authentication support and nonce generation.
- `core/config`: generated Firebase options and AdMob IDs.
- `core/di`: service registration.
- `core/services`: ads, analytics, cache, consent, error handling, gamertags, leaderboard, and purchases.
- `features/auth`: login/gamertag/profile UI and profile data/domain code.
- `features/game`: active falling mode plus retained legacy board mode.
- `features/leaderboard`: leaderboard UI.
- `features/website`: legacy Flutter web surface; not Firebase Hosting's current site.
- `shared`: legacy/reusable models and widgets.

## Web runtime

`packages/web` is the deployed Firebase Hosting application. React Router maps nine routes. Only the leaderboard route initializes Firestore data access; authentication is not part of the public React site.

The consent bootstrap executes before GTM. Consent defaults to denied and can be restored from `ms_consent_v1`. The React banner updates Consent Mode and dispatches an event used by ad slots.

## Firebase data plane

- Authenticated client-owned data: `users`, `user_profiles`, `game_stats`.
- Public read/server write: global, daily, and weekly leaderboards.
- Owner read/server write: `purchases`, purchase transactions, and `entitlements`.
- Authenticated claim index: `gamertags` can be created once; updates/deletes are denied by public rules.

Server-authoritative writes pass through callable Functions. Details are in [API Documentation](Api_Documentation.md) and [Database Schema](Database_Schema.md).

## Environment model

| Branch | Environment | Firebase project | iOS delivery |
|---|---|---|---|
| `develop` | development | `modulo-squares-dev` | TestFlight deployable run |
| `staging` | staging | `modulo-squares-staging` | TestFlight deployable run |
| `main` | production | `modulo-squares-prod` | TestFlight plus optional manual review submission |

Environment selection is controlled by the active GitHub workflow and `scripts/switch-mobile-configs.sh`.

## Security boundaries

- Firebase Auth identities gate owned records and callable Functions.
- Firestore rules deny all client writes not explicitly allowed.
- Leaderboard sessions and purchase validation are server-controlled.
- App Check is initialized in the mobile client; enforcement is an external Firebase console setting.
- Production secrets remain in GitHub environments/Secrets and local ignored files.
- The private Functions checkout keeps server business logic out of the public repository.

## Delivery architecture

`.github/workflows/ci-cd.yml` is the only active full delivery pipeline. Archived workflow files are retained under `.github/workflows/archive` and must not be cited as current automation.

The optional `install-ios-on-hades.yml` workflow uses a self-hosted Mac and connected iPhone. Normal CI, TestFlight, Hosting, and Functions deployment use GitHub-hosted runners.

## Known architecture debt

- Active and legacy game implementations coexist.
- The Flutter `WebsiteScreen` contains placeholder behavior but is not the deployed site.
- Root Functions scripts depend on an absent-by-default private checkout.
- Android artifacts exist, but no Android job runs in active CI.
- `packages/firebase-utils` is built and linted but not consumed by the Flutter client.
