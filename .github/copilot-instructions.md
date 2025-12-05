# Copilot instructions for modulo-squares

Purpose: Guide AI coding agents in this monorepo Flutter + Firebase puzzle game with web promo site, backend functions, and automation.

## Big picture
- Monorepo: `packages/mobile/` (Flutter app), `packages/web/` (React promo site), `packages/functions/` (Firebase Functions), `packages/shared/` (future cross-platform utils), `packages/firebase-utils/`, `packages/firestore-rules/`.
- Mobile entry: `packages/mobile/lib/main.dart` initializes Firebase, auto anonymous auth via `AuthGate`, routes to `WebsiteScreen` (web) or `GameScreen` (mobile).
- Architecture: Feature-based (`features/`), core services (`core/services/`), shared models/widgets (`shared/`), l10n (`l10n/`).
- Core logic: `packages/mobile/lib/shared/models/game_board.dart` (immutable board state, modulo rules, special tiles).
- UI: Features have screens, widgets, providers; shared widgets in `shared/widgets/`.
- Services: `core/services/` (e.g., `leaderboard_service.dart` for Firestore `modulo_leaderboard` collection).
- Web: React/TypeScript/Vite/Tailwind promo site in `packages/web/`.
- Backend: Node.js Firebase Functions in `packages/functions/`.

## Data and rules
- GameBoard immutable; operations return new instances (copyWith). Tiles: normal, obstacle, bonus, etc. Effects in move/slide.
- Update rules: Modify `TileType` enum, `GameBoard` logic, rendering in `shared/widgets/grid_cell_widget.dart`, tooltips in `features/game/game_screen.dart`.
- Leaderboard: Use `LeaderboardService` for Firestore ops.

## UI patterns
- GameScreen manages transient state; persists highScore via SharedPreferences.
- Gestures: Tap select/move; swipe slide (velocity > 1000).
- Strings: `AppLocalizations.of(context)`; no legacy constants.

## Firebase setup
- Mobile: `firebase_options.dart` generated; initialize with `DefaultFirebaseOptions.currentPlatform`.
- Auth: Auto anonymous; no manual login screen.
- Web: Separate Firebase config.

## Conventions
- Models framework-free.
- Immutability: new states via copyWith.
- Lints: `analysis_options.yaml`.

## Workflows
- Mobile: `cd packages/mobile && flutter pub get`, `flutter run`, `flutter test`, `flutter analyze`.
- Web: `cd packages/web && npm install`, `npm run dev`, `npm run build`.
- Functions: `cd packages/functions && npm install`, `firebase emulators:start`.
- Root: `npm install`, `npm run install:all`, `firebase login`, `npm run deploy:all`.
- Docker: Setup with `./setup-docker-auth.sh`; build web/functions images.

## Gotchas
- Use LeaderboardService for centralized Firestore.
- No editing generated Firebase files.
- Maintain gesture thresholds.

Key files: `packages/mobile/lib/shared/models/game_board.dart`, `packages/mobile/lib/features/game/game_screen.dart`, `packages/mobile/lib/core/services/leaderboard_service.dart`, `packages/mobile/lib/main.dart`.

