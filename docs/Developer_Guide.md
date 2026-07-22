# Developer Guide

**Updated**: 2026-07-20

## First-day setup

1. Install Node.js 20, Flutter 3.44.2, Firebase CLI, and platform tooling.
2. Run `npm install` at the root.
3. Run `npm install` in `packages/firebase-utils` if workspace installation did not populate it.
4. Run `flutter pub get` in `packages/mobile`.
5. Select the intended Firebase environment before native builds.
6. Run baseline validation before making changes.

```bash
npm run lint
npm run check
npm run build:web

cd packages/mobile
flutter analyze
flutter test
```

See [Environment Setup](Environment_Setup.md) for platform prerequisites.

## Source-of-truth rules

- Active gameplay is `GameScreen` -> `FallingModuloGameScreen`.
- Firebase Hosting serves the React app in `packages/web`, not Flutter `WebsiteScreen`.
- `.github/workflows/ci-cd.yml` is the active delivery workflow.
- `.github/workflows/archive` contains inactive history.
- Cloud Functions source is private and absent from a normal clone.
- `Current_State.md` and `GO_LIVE_RUNBOOK.md` supersede status claims in older plans.

## Mobile development

The mobile app uses GetIt for service registration and direct StatefulWidget state for falling gameplay. Provider/Clean Architecture classes remain for older profile and board-mode features; do not assume every retained abstraction is on the live path.

Useful entry points:

- `lib/main.dart`: initialization and auth/gamertag gate.
- `lib/features/game/game_screen.dart`: gameplay routing boundary.
- `lib/features/game/falling_modulo_game_screen.dart`: active UI and settings.
- `lib/features/game/models/falling_modulo_game_engine.dart`: deterministic game rules.
- `lib/core/services/leaderboard_service.dart`: leaderboard client contract.
- `lib/core/services/purchase_service.dart`: IAP and entitlement reconciliation.
- `lib/core/services/consent_service.dart`: ATT/UMP consent.
- `lib/core/services/ad_service.dart`: interstitial lifecycle.

Run a device build with the correct environment:

```bash
../../scripts/switch-mobile-configs.sh dev
flutter run
```

Do not test production IAP behavior in the simulator. Use StoreKit configuration, sandbox/TestFlight, or a real device as appropriate.

## Web development

```bash
cd packages/web
npm run dev
```

The Vite app reads Firebase and AdSense values from `VITE_*` variables. Keep analytics in GTM/GA4; do not initialize a second web analytics path through Firebase Analytics. Consent must default to denied before GTM loads.

Before a route change, update:

- `src/App.tsx`
- `public/sitemap.xml` for indexable public routes
- navigation/footer as appropriate
- route-level `SEOHead`
- policy copy if data collection or advertising changes

## Firebase utilities

`packages/firebase-utils` is an ESM TypeScript package. Source is in `src`, build output in `dist`.

```bash
cd packages/firebase-utils
npm run lint
npm run check
npm run build
```

Vitest is configured, but `packages/firebase-utils` currently has no test files; its `npm test` command exits nonzero until tests are added.

## Functions work

Clone the private repository into `packages/functions` only if authorized:

```bash
git clone --branch develop \
  https://github.com/NelsonGrey/modulo-squares-functions.git \
  packages/functions
```

The directory is ignored. Confirm the companion repo branch and status separately before deploying. Root scripts such as `test:functions`, `build:functions`, and `deploy:all` require this checkout.

## Environment switching

```bash
npm run config:dev
npm run config:staging
npm run config:prod
```

The script selects Android `google-services.json` and iOS `GoogleService-Info.plist`. Avoid hand-editing generated Firebase options unless intentionally regenerating them.

## Branch and release flow

- Feature work targets `develop`.
- `develop` deployments use development Firebase resources.
- Promotion to `staging` exercises staging Firebase and TestFlight delivery.
- Promotion to `main` uses production resources.
- App Store submission is a separate manual `workflow_dispatch` action with `submit_to_app_store=true`.

Always verify exact branch/upstream state before promotion:

```bash
git status --short --branch
git rev-list --left-right --count @{upstream}...HEAD
```

## Coding and documentation expectations

- Keep game-rule changes in the engine and cover them with deterministic tests.
- Treat leaderboard and purchase data as server-authoritative.
- Do not expose secret material in tracked configuration or command output.
- Keep user-facing legal/store copy aligned with actual ads, analytics, authentication, and deletion behavior.
- Update current docs in the same change as any architecture, workflow, route, API, or release-state change.

## Pre-commit validation

```bash
npm run lint
npm run check
npm run build:web

cd packages/mobile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

For iOS-affecting changes, add `flutter build ios --release --no-codesign`. For Android-affecting changes, add `flutter build appbundle --release` when signing/build tooling is available.
