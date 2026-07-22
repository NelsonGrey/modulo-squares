# Flutter Architecture

**Updated**: 2026-07-20

## Runtime path

```text
main()
  -> service registration
  -> Firebase/platform initialization
  -> ModuloApp
  -> AuthGate
     -> LoginScreen
     -> GamertagScreen
     -> WebsiteScreen (Flutter web only)
     -> GameScreen (native)
        -> FallingModuloGameScreen
```

The app uses several architectural styles because current falling gameplay was added after the original board mode:

- GetIt singletons for cross-cutting services.
- StatefulWidget-local state for falling gameplay.
- Provider/ChangeNotifier for the retained legacy board game.
- data/domain/presentation layers for profile features.

Do not describe the entire package as one uniform Clean Architecture implementation.

## Package layout

```text
lib/
├── core/
│   ├── auth/          # Apple nonce and auth fallback policy
│   ├── config/        # Firebase and AdMob configuration
│   ├── di/            # GetIt service locator
│   └── services/      # ads, analytics, cache, consent, errors, tags, scores, IAP
├── features/
│   ├── auth/          # login, gamertag, profile UI/data/domain code
│   ├── game/          # active falling mode and legacy board mode
│   ├── leaderboard/   # native global leaderboard UI
│   └── website/       # legacy Flutter web surface
├── l10n/              # generated English localization
├── shared/            # legacy models and reusable widgets
└── main.dart
```

## Initialization

`main.dart` initializes services defensively. Firebase-dependent UI is not shown until Firebase is ready. Failures route to a recovery screen with retry instead of leaving the user on an indefinite splash screen.

Analytics observation is attached only when Firebase is initialized. Ads, consent, purchases, and caches are registered lazily through GetIt and guard platform/test conditions.

## Authentication and onboarding

`AuthGate` listens to `FirebaseAuth.authStateChanges()`:

1. Unauthenticated users see `LoginScreen`.
2. Authenticated users are checked for a gamertag with a short retry path for transient Firestore permission propagation.
3. Users without a tag see `GamertagScreen`.
4. Native users enter `GameScreen`; Flutter web users enter `WebsiteScreen`.

Login UI supports Apple, Google, and email/password flows. Anonymous/account-linking support exists in settings-related code paths, but current acceptance should be verified on device.

## Active game architecture

`FallingModuloGameEngine` is a UI-independent rules class. It creates immutable `FallingModuloGameState` values and returns a new state plus a resolution for each landing.

`FallingModuloGameScreen` owns:

- 16 ms ticker and drop clock;
- spawn delay and pause/start state;
- local high score and cue preference;
- movement cooldown;
- result animation/UI;
- settings, sign-out/linking/deletion, and purchases;
- transition ad invocation.

Keep deterministic game rules in the engine. Keep plugin/UI effects in the screen or services.

## Services

| Service | Responsibility |
|---|---|
| `AdService` | Interstitial load/show and analytics hooks |
| `AnalyticsService` | Firebase event logging with initialization guards |
| `CacheService` | SharedPreferences-backed leaderboard/assets cache |
| `ConsentService` | iOS ATT and Google UMP consent coordination |
| `ErrorHandler` | Logging and localized/snackbar error presentation |
| `GamertagService` | validation, uniqueness check, tag lookup/save |
| `LeaderboardService` | callable submissions and Firestore reads/cache |
| `PurchaseService` | product loading, purchase stream, validation, restore |

## Persistence

- Firebase Auth: identity.
- Firestore: gamertags, user records, leaderboards, purchases/entitlements.
- SharedPreferences: falling high score, visual cues, caches, and entitlement hints.
- Platform stores: purchase source of truth, reconciled through server validation.

## Legacy code

The original `GameBoard`, `GameState`, `GameProvider`, grid widgets, dialogs, and `InstructionsScreen` remain in source and tests. They are not reachable from the current native gameplay entry point. Changes to them should be labeled legacy unless the product deliberately reintroduces that mode.

## Testing boundaries

- Pure engine behavior: unit tests.
- active screen/settings: widget tests.
- auth/startup/services: unit/widget tests with Firebase/plugin guards or mocks.
- real auth, ads, consent, IAP, deletion, and backend contracts: device/emulator/integration validation.

See [Testing](Testing.md) and [Game Mechanics](Game_Mechanics.md).
