# Copilot instructions for modulo-flutter-project

Purpose: Help AI coding agents be productive in this Flutter + Firebase puzzle game by encoding the project’s architecture, workflows, and conventions.

## Big picture
- Entry: `lib/main.dart` initializes Firebase and routes via `AuthGate` to `LoginScreen` (unauth) or `GameScreen` (auth). L10n via `AppLocalizations` in `lib/l10n/app_localizations.dart`.
- Core logic lives in models and is UI-agnostic: `lib/models/game_board.dart` holds the board state and rules (move/slide, modulo mechanic, special tiles).
- UI composition:
	- Screens: `lib/screens/` (stateful controllers; e.g., `game_screen.dart`, `login_screen.dart`, `leaderboard_screen.dart`).
	- Widgets: `lib/widgets/` (pure UI; e.g., `grid_cell_widget.dart`).
	- Services: `lib/leaderboard_service.dart` (Firestore reads/writes for scores).

## Data and rules that matter
- Game state is an immutable-ish model; operations return a new `GameBoard` (see `copyWith` usage). UI calls `setState` with the new instance.
- Tiles (`TileType`) include normal, locked, obstacle, multiplier, poison, freeze. Effects are applied inside `GameBoard.move/slide` (e.g., multiplier +4 score, poison −3, freeze sets `frozen: true`). If extending rules, update:
	- `TileType` enum and switch logic in `GameBoard`.
	- Rendering in `lib/widgets/grid_cell_widget.dart` (icons/colors/text).
	- Hints/tooltips in `GameScreen` (`_showTileEffectInfo` and the “Special Tiles” dialog).
- Leaderboard uses Firestore. Preferred collection and API are in `lib/leaderboard_service.dart` (collection: `modulo_leaderboard`). Avoid hardcoding collections elsewhere; use the service.

## UI interaction patterns
- `GameScreen` owns transient UI state (selected cell, remaining moves, level) and persists only `highScore` via `SharedPreferences` (key: `highScore`).
- Gestures: Tap selects/moves; swipe triggers `slide` using velocity direction (threshold: `velocity.distanceSquared > 1000`). Maintain this pattern for consistent UX.
- Strings: Use `AppLocalizations.of(context)` only for user-visible text. Treat `lib/constants/app_strings.dart` and `lib/constants/app_constants.dart` as legacy (do not add new entries); add new getters/messages in `lib/l10n/app_localizations.dart` instead. Example: `Text(AppLocalizations.of(context).appTitle)`.

## Firebase and platform setup
- Firebase config: `lib/firebase_options.dart` is generated. Do not edit by hand. `main.dart` currently calls `Firebase.initializeApp()` without options, relying on platform files; if adding web/macOS, initialize with `DefaultFirebaseOptions.currentPlatform`.
- Sign-in: `LoginScreen` supports Google, Apple, and anonymous auth using `firebase_auth`, `google_sign_in`, and `sign_in_with_apple`.

## Conventions and style
- Keep models framework-free (no Flutter imports in `lib/models/**`).
- Prefer immutability: build new board states instead of mutating in place; copy grid with `grid.map(...).toList()` as shown.
- Lints: See `analysis_options.yaml` (some rules disabled); still aim to keep code idiomatic and const-friendly.

## Example: add a new special tile
1) Add enum value to `TileType` and handle in `GameBoard.move/slide` (scoring/effects). 2) Render in `grid_cell_widget.dart` (color/icon/text). 3) Add tooltip text in `GameScreen._showTileEffectInfo` and the “Special Tiles” dialog. 4) Update `hasMoves()` logic if the tile affects move validity.

## Build, run, test
- Install deps: `flutter pub get`.
- Run app: `flutter run` (ensure Firebase iOS/Android config files are present).
- Analyze/lints: `flutter analyze` (rules in `analysis_options.yaml`).
- Tests: `flutter test` (see `test/models/game_board_test.dart`, `test/widgets/widget_test.dart`). Focus unit tests on `GameBoard` rules.

## Gotchas
- Don’t bypass `LeaderboardService`; the leaderboard UI should read via `LeaderboardService.getTopScores` so collection names remain centralized.
- Avoid editing generated files (`lib/firebase_options.dart`) and platform configs in `android/` and `ios/` unless you know the release implications.
- Maintain gesture threshold logic and `remainingMoves`/level-up flow in `GameScreen` when changing UX.

## Cleanup (one-time)
- Migrate any uses of `AppStrings` (in `lib/constants/app_strings.dart` or `lib/constants/app_constants.dart`) to `AppLocalizations`. After zero references, remove the legacy files to eliminate duplication.

Key files: `lib/models/game_board.dart`, `lib/screens/game_screen.dart`, `lib/widgets/grid_cell_widget.dart`, `lib/leaderboard_service.dart`, `lib/l10n/app_localizations.dart`, `lib/main.dart`.

