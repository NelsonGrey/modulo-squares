# Analytics (Firebase Analytics)

This app uses Firebase Analytics to measure key player interactions while preserving a lightweight and privacy-aware setup. All launches currently sign users in anonymously; the analytics userId is the Firebase Auth UID.

## Setup

- Dependency: `firebase_analytics` (see `pubspec.yaml`).
- Initialization: Firebase is initialized in `lib/main.dart`. The app auto signs in anonymously.
- Observer: `FirebaseAnalyticsObserver` is attached to `MaterialApp.navigatorObservers` to record `screen_view` events.
- Service: All custom events are centralized in `lib/utils/analytics_service.dart`.

## User identity

- On auth state available, we call:
  - `setUserId(uid)` (Firebase Auth UID)
  - `setUserProperty('is_anonymous', 'true'|'false')`
- For launch, all players are anonymous.

## Events

All events are emitted via `AnalyticsService` to keep naming and parameters consistent.

- Lifecycle
  - `app_open`: when the app first renders (AuthGate on first frame)
- Navigation / Views
  - `screen_view`: automatic via `FirebaseAnalyticsObserver`
  - `view_instructions`: user opened How to Play page
  - `view_leaderboard`: user opened leaderboard dialog
  - `view_special_tiles`: user opened special tiles dialog
- Gameplay
  - `level_start` parameters: `{ level_num, rows, cols }`
  - `level_complete` parameters: `{ level_num, score }`
  - `out_of_moves` parameters: `{ level_num, score }`
  - `game_over_no_moves` parameters: `{ score }`
  - `move` parameters: `{ type: 'tap'|'swipe' }`
  - `mercy_spawn` parameters: `{ penalty }`
 - Ads
   - `ad_impression` parameters: `{ format: 'interstitial', trigger?: 'level_complete'|'restart'|..., level_num?: number }`
   - `ad_dismissed` parameters: `{ format: 'interstitial', trigger?: 'level_complete'|'restart'|..., level_num?: number }`

## Where events are called

- `lib/main.dart`
  - App open and user identity
- `lib/screens/game_screen.dart`
  - Level start/complete, moves, mercy spawn, dialogs
  - Interstitial ads shown on level complete and restart (with trigger and level_num)
- `lib/screens/instructions_screen.dart`
  - Tracked via `view_instructions` from `GameScreen`

## Debugging / Validation

- Use DebugView in Firebase Analytics:
  - Android: `adb shell setprop debug.firebase.analytics.app <your.package>`
  - iOS: Run on a device/simulator; events appear in DebugView.
- In code, ensure `AnalyticsService` methods are invoked (search for `AnalyticsService.instance`).

## Privacy & data

- No PII is collected. Anonymous Auth UID is used as userId.
- You can disable analytics collection if required:
  - Call `FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false)` early (e.g., behind a settings toggle).

## Extending events

- Prefer adding a method to `AnalyticsService` rather than calling `logEvent` directly in UI code.
- Keep names snake_case, parameters short and consistent.
- Include sufficient context (level_num, score, etc.) without sending PII.

## References

- `pubspec.yaml`: dependencies
- `lib/main.dart`: initialization, observer, userId setup
- `lib/utils/analytics_service.dart`: analytics wrapper
- `lib/screens/game_screen.dart`: gameplay instrumentation
