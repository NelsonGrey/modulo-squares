# Modulo Squares

Modulo Squares is a falling-number arcade puzzle built with Flutter and Firebase. Guide each number into one of ten divisor buckets before it lands, build combos, fill the progress grid, and chase a persistent local high score.

The repository contains the mobile app, the public React website, shared Firebase utilities, Firestore rules, release automation, and project documentation. Server-side Cloud Functions live in a separate private companion repository and are checked out by CI only when Functions are deployed.

## Current status

- Mobile version: `1.0.0+2`
- Primary mobile platforms: iOS and Android; iOS is the current release focus
- Public website: [modulosquares.com](https://modulosquares.com)
- Active branch workflow: `.github/workflows/ci-cd.yml`
- Toolchain used by CI: Flutter `3.44.2`, Dart `>=3.7.0`, Node.js `20`
- Current gameplay entry point: `GameScreen` -> `FallingModuloGameScreen`
- App Store state: the last repository-confirmed state is a corrected production build on TestFlight awaiting manual App Store resubmission; verify App Store Connect before treating that status as current

See [Current State](docs/Current_State.md), [Documentation Index](docs/Documentation_Index.md), and [Go-Live Runbook](docs/GO_LIVE_RUNBOOK.md).

## Repository layout

```text
.
├── .github/
│   ├── actions/                 # Reusable setup actions
│   └── workflows/               # Active and archived GitHub Actions workflows
├── docs/                        # Product, engineering, operations, and release docs
├── icons/                       # Current icon, proposals, and archived icon assets
├── monitoring/                  # Lightweight runner/deployment status server
├── packages/
│   ├── firebase-utils/          # Shared TypeScript Firebase helpers
│   ├── firestore-rules/         # Firestore security rules
│   ├── mobile/                  # Flutter application and tests
│   ├── shared/                  # Reserved shared package area
│   └── web/                     # React/Vite marketing site and public leaderboard
├── scripts/                     # Environment, signing, deployment, and runner helpers
├── shared-ios-setup/            # Reusable Fastlane/Match reference configuration
├── firebase*.json               # Per-environment Firebase configuration
└── package.json                 # Root orchestration scripts
```

`packages/functions/` is intentionally ignored. For a manual Functions deployment, clone the private `NelsonGrey/modulo-squares-functions` repository into that exact path. CI performs this checkout with `FUNCTIONS_REPO_PAT`.

## Product behavior

The native app requires Firebase initialization and authentication. Players sign in with Apple, Google, or email/password, choose a unique gamertag, and then enter falling-mode gameplay. The active game includes:

- ten lanes containing shuffled buckets `1` through `9` plus one dead bucket `0`;
- automatic falling with left/right controls and a 500 ms spawn pause;
- a success when `fallingValue % bucketValue == 0`;
- score, combo, high-score, level, and progress-grid feedback;
- optional divisibility cues, persisted locally;
- interstitial ads and a non-consumable `remove_ads` purchase;
- global, daily, and weekly leaderboard infrastructure backed by callable Functions (the public React leaderboard reads it, but current falling gameplay does not submit or open it);
- sign-out, account linking, purchase restoration, and permanent account deletion.

Older board-clearing classes and tests remain in the tree as legacy/reference code. They are not the app's current gameplay entry point.

## Web application

`packages/web` is a React 19, TypeScript, Vite 8, and Tailwind CSS 4 site. It provides:

- `/`, `/how-it-works`, `/download`, and `/pricing` marketing routes;
- a live Firestore-backed `/leaderboard` route;
- `/privacy`, `/terms`, `/cookies`, and `/support` policy/support routes;
- route-level metadata, `robots.txt`, and `sitemap.xml`;
- Google Tag Manager/GA4 and Google AdSense under consent controls.

The Flutter web target still exists for compatibility, but Firebase Hosting deploys the React build from `packages/web/dist`.

## Local setup

Prerequisites:

- Flutter `3.44.2` recommended; Dart SDK `>=3.7.0 <4.0.0`
- Node.js `20` (`.nvmrc` currently pins `20.3.2`)
- Firebase CLI
- Xcode and CocoaPods for iOS work
- Android Studio/JDK for Android work
- Ruby `3.2.2` for the mobile Fastlane setup

```bash
npm install
npm --prefix packages/firebase-utils install

cd packages/mobile
flutter pub get
cd ../..

npm run dev:web
```

The root `install:all` command installs root and Firebase utility dependencies. Flutter dependencies must be fetched separately.

Environment-specific native Firebase files are already represented by `.dev`, `.staging`, and `.prod` variants. Switch them with:

```bash
npm run config:dev
npm run config:staging
npm run config:prod
```

## Build and validation

```bash
# Flutter
cd packages/mobile
flutter analyze
flutter test --coverage
flutter build ios --release --no-codesign

# Web
cd packages/web
npm run lint
npm run build

# Shared Firebase utilities
cd packages/firebase-utils
npm run lint
npm run check
npm run build
```

From the repository root, `npm run lint`, `npm run check`, `npm run build:web`, and `npm run test:app` wrap the corresponding package commands.

## CI/CD

The active pipeline runs for pushes to `develop`, `staging`, and `main`, for pull requests targeting those branches, and by manual dispatch.

- `quality-check`: Flutter analyze and test on Ubuntu
- `build-web`: React production build on Ubuntu
- `build-ios`: TestFlight build/upload on macOS for deployable `staging` and `main` runs
- `submit-app-store`: manual production-only App Store submission gate
- `deploy-web`: Firebase Hosting deployment
- `deploy-functions`: private Functions checkout and Firebase deployment
- `deployment-summary`: consolidated result summary

The manual `install-ios-on-hades.yml` workflow is the only intentional self-hosted path. Files under `.github/workflows/archive/` are historical and are not active pipelines.

## Firebase environments

| Environment | Project | Branch |
|---|---|---|
| Development | `modulo-squares-dev` | `develop` |
| Staging | `modulo-squares-staging` | `staging` |
| Production | `modulo-squares-prod` | `main` |

Firestore client writes are limited to each signed-in user's `users`, `user_profiles`, and `game_stats` documents plus initial gamertag claims. Leaderboards, purchases, and entitlements are server-authoritative.

## Documentation

Start at [docs/Documentation_Index.md](docs/Documentation_Index.md). It labels each document as current, operational reference, planning, or historical so that old implementation proposals are not mistaken for live behavior.

## License

See [LICENSE](LICENSE).
