# Testing

**Updated**: 2026-07-20

## CI baseline

The active quality job runs:

```bash
cd packages/mobile
flutter analyze
flutter test --coverage
```

The web job installs dependencies with `npm ci` and runs `npm run build`, which includes TypeScript compilation. Linting for web and Firebase utilities is available from the root but is not currently a separate step in `ci-cd.yml`.

## Flutter test layout

| Area | Location | Purpose |
|---|---|---|
| Startup/auth gate | `test/app_startup_test.dart`, `test/auth` | Initialization and fallback decisions |
| Active gameplay engine | `test/models/falling_modulo_game_engine_test.dart` | Scoring, movement, progress, levels, timing |
| Active gameplay UI | `test/features/falling_modulo_game_screen_test.dart` | Overlay, settings, account deletion, run reset |
| Gameplay routing | `test/features/game_screen_test.dart`, `test/integration/game_screen_integration_test.dart` | Confirms falling mode is the default |
| Authentication UI | `test/features/login_screen_test.dart`, integration tests | Provider controls and auth behavior |
| Website surface | `test/features/website` | Legacy Flutter web UI |
| Core services | `test/services` | ads, consent, purchases, analytics, cache, leaderboard |
| Legacy board mode | `test/models/game_board_test.dart`, provider tests | Retained non-live engine coverage |
| Guardrails | `test/guardrails/no_legacy_strings_test.dart` | Prevents selected retired copy from returning |

Some mocks are generated with Mockito/build_runner and are tracked beside their tests.

## Common commands

```bash
cd packages/mobile

# Entire suite
flutter test

# Current game rules and UI
flutter test test/models/falling_modulo_game_engine_test.dart
flutter test test/features/falling_modulo_game_screen_test.dart
flutter test test/integration/game_screen_integration_test.dart

# Coverage
flutter test --coverage
```

## Static analysis and formatting

```bash
cd packages/mobile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
```

## Web and shared TypeScript

```bash
cd packages/web
npm run lint
npm run build

cd ../firebase-utils
npm run lint
npm run check
npm run build
```

The React website currently has no dedicated unit/browser test suite. `packages/firebase-utils` configures Vitest but has no test files, so its test script currently exits 1 with `No test files found`. Build and lint checks catch compilation and static issues, but route behavior, consent, ads, responsive layout, live Firestore loading, and Firebase utility runtime behavior need additional automated coverage.

## Manual release checks

Automated tests do not replace:

- Apple, Google, and email sign-in on real supported devices;
- gamertag creation and returning-user lookup;
- StoreKit product loading, purchase, restore, and ad removal;
- ATT and UMP consent flows;
- level transition/ad cadence;
- account deletion including backend data cleanup;
- TestFlight launch and production Firebase connectivity;
- public site route, sitemap, cookie consent, GA4, AdSense, and leaderboard checks.

Use [GO_LIVE_RUNBOOK.md](GO_LIVE_RUNBOOK.md) for external release validation.

## Test design guidance

- Inject a seeded `Random` or deterministic state for engine tests.
- Keep Firebase/platform plugins behind testable boundaries and tolerate uninitialized Firebase where the UI intentionally supports it.
- Assert public behavior rather than internal widget tree shape.
- Label tests for legacy board mode so they are not mistaken for current product acceptance criteria.
- Add a regression test for every App Review or production incident fix.
