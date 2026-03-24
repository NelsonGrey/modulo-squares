# Analytics (Firebase Analytics)

This document describes the Firebase Analytics implementation in Modulo Squares, including event tracking, user identification, and debugging procedures.

## Overview

The app uses Firebase Analytics to track user behavior, game progression, and monetization metrics while maintaining privacy compliance. All events are centralized through the `AnalyticsService` singleton.

### Key Features
- **Privacy-First**: Graceful degradation when Firebase is unavailable
- **User Identification**: Anonymous auth UID as user ID
- **Comprehensive Tracking**: Game events, UI interactions, and ad performance
- **Debug Support**: Easy testing and validation

## Setup

### Dependencies
```yaml
dependencies:
  firebase_analytics: ^10.4.0
  firebase_auth: ^4.6.0
  firebase_core: ^2.10.0
```

### Initialization
Analytics are initialized in `lib/main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set up analytics observer for screen tracking
  final analyticsObserver = FirebaseAnalyticsObserver(
    analytics: FirebaseAnalytics.instance,
  );

  runApp(ModuloApp(analyticsObserver: analyticsObserver));
}
```

### Service Integration
The `AnalyticsService` is a singleton that safely handles Firebase unavailability:
```dart
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? get _analyticsSafe {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }
}
```

## User Identification

### Anonymous Authentication
- Users are signed in anonymously on app launch
- Firebase Auth UID serves as the analytics user ID
- User property tracks anonymous vs authenticated status

```dart
Future<void> setUserIdFromAuth(User? user) async {
  final a = _analyticsSafe;
  if (a == null || user == null) return;

  await a.setUserId(id: user.uid);
  await a.setUserProperty(
    name: 'is_anonymous',
    value: user.isAnonymous.toString()
  );
}
```

## Event Tracking

### Lifecycle Events
- **`app_open`**: Tracked automatically via FirebaseAnalyticsObserver
- **`screen_view`**: Automatic screen tracking via observer

### Navigation Events
- **`view_instructions`**: User opens instructions/how-to-play
- **`view_leaderboard`**: User opens leaderboard screen
- **`view_special_tiles`**: User views special tiles information

### Leaderboard Events
- **`leaderboard_tab_changed`**: Parameters: `{tab, is_daily_context, challenge_id?}`
- **`leaderboard_tab_restored`**: Parameters: `{tab, is_daily_context, challenge_id?}`
- **`weekly_leaderboard_control_changed`**: Parameters: `{control, value, is_daily_context, challenge_id?}`
- **`weekly_leaderboard_control_restored`**: Parameters: `{control, value, is_daily_context, challenge_id?}`

#### Leaderboard Parameter Reference
- **`tab`**: `global | daily | weekly`
- **`control`**: `week | top_limit`
- **`value`**:
  - for `control=week`: ISO week id used by leaderboard buckets
  - for `control=top_limit`: one of `10 | 25 | 50`
- **`is_daily_context`**: `1` when opened from Daily Challenge flow, else `0`
- **`challenge_id`**: optional daily challenge identifier when available

### Gameplay Events
- **`level_start`**: Parameters: `{level_num, rows, cols}`
- **`level_complete`**: Parameters: `{level_num, score}`
- **`out_of_moves`**: Parameters: `{level_num, score}`
- **`game_over_no_moves`**: Parameters: `{score}`
- **`move`**: Parameters: `{type: 'tap'|'swipe'}`
- **`restart`**: Parameters: `{level}`
- **`mercy_spawn`**: Parameters: `{penalty}` (when extra tiles are added)

### Ad Events
- **`ad_impression`**: Parameters: `{format, trigger?, level_num?}`
- **`ad_dismissed`**: Parameters: `{format, trigger?, level_num?}`

## Implementation Details

### Event Logging
All events are logged through the service singleton:
```dart
// Example usage
await AnalyticsService.instance.logLevelStart(
  level: currentLevel,
  rows: gameBoard.rows,
  cols: gameBoard.cols,
);

// Ad tracking with context
await AnalyticsService.instance.logAdImpression(
  format: 'interstitial',
  trigger: 'level_complete',
  levelNum: currentLevel,
);
```

### Where Events Are Called

#### Main App (`lib/main.dart`)
- App open tracking
- User authentication state changes
- Analytics observer setup

#### Game Screen (`lib/features/game/game_screen.dart`)
- Level start/complete events
- Move tracking (tap vs swipe)
- Game over conditions
- Mercy spawn events
- Restart actions
- Ad impressions on level completion/restart

#### Leaderboard Screen (`lib/features/leaderboard/leaderboard_screen.dart`)
- Leaderboard view events

#### Game Leaderboard Screen (`lib/features/game/leaderboard_screen.dart`)
- Tab interaction and restoration events (`leaderboard_tab_changed`, `leaderboard_tab_restored`)
- Weekly control interaction and restoration events (`weekly_leaderboard_control_changed`, `weekly_leaderboard_control_restored`)
- Context enrichment for all above events (`is_daily_context`, optional `challenge_id`)

#### Auth Flow
- Instructions view tracking
- Special tiles info tracking

## Debugging & Validation

### Firebase Debug Mode

#### Android
```bash
adb shell setprop debug.firebase.analytics.app com.nelsongrey.modulosquares.app
```

#### iOS
Enable debug mode in Xcode or use:
```bash
# In iOS Simulator
killall -9 SpringBoard
```

### Validation Steps
1. **Launch App**: Check Firebase DebugView for `app_open` event
2. **Play Game**: Verify `level_start`, `move`, and `level_complete` events
3. **View Ads**: Confirm `ad_impression` and `ad_dismissed` events
4. **Open Leaderboards**: Confirm tab and weekly-control events appear with expected params
5. **Check User ID**: Verify anonymous user ID is set correctly

### Testing Analytics
```dart
// In tests, analytics calls are no-ops when Firebase is unavailable
test('analytics service handles missing Firebase gracefully', () {
  // Firebase not initialized in test environment
  final service = AnalyticsService.instance;

  // Should not throw exceptions
  expect(() async => await service.logAppOpen(), returnsNormally);
});
```

## Privacy & Compliance

### Data Collection
- **No PII**: Only anonymous Firebase Auth UIDs
- **Consent-Aware**: Ad personalization gated by user consent
- **Minimal Tracking**: Only essential game and monetization events

### Disabling Analytics
```dart
// Disable analytics collection
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);

// Re-enable
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
```

### GDPR Compliance
- Analytics respects user's consent choices
- No sensitive data collection
- Easy opt-out mechanism available

## Performance Considerations

### Event Batching
Firebase Analytics automatically batches events for efficiency.

### Error Handling
The service gracefully handles Firebase unavailability:
- Widget tests don't require Firebase initialization
- Network failures don't crash the app
- Missing Firebase doesn't prevent game functionality

### Memory Impact
- Minimal memory footprint
- Events stored locally until network available
- Automatic cleanup of old events

## Analytics Strategy

### Key Metrics to Monitor
1. **User Acquisition**: `app_open` frequency and sources
2. **Engagement**: Session duration, level completion rates
3. **Monetization**: Ad impression/dismissal rates, revenue per user
4. **Retention**: Daily/weekly active users, return rates
5. **Leaderboard Funnel**: tab preference, weekly depth usage, week-browsing behavior
6. **Game Balance**: Level difficulty, mercy spawn frequency

### A/B Testing Setup
Future A/B tests can use custom parameters:
```dart
await analytics.logEvent(
  name: 'experiment_impression',
  parameters: {
    'experiment_id': 'difficulty_balance',
    'variant': 'easy_mode',
  },
);
```

## Troubleshooting

### Common Issues

**Events Not Appearing**
- Check Firebase DebugView (may take 1-2 hours for production)
- Verify Firebase project configuration
- Ensure events are called on main thread

**User ID Not Set**
- Confirm anonymous authentication is working
- Check Firebase Auth initialization order

**Ad Events Missing Context**
- Ensure `trigger` and `level_num` parameters are provided
- Verify ad service integration

### Debug Checklist
- [ ] Firebase DebugView enabled
- [ ] Anonymous auth working
- [ ] Events called with correct parameters
- [ ] Network connectivity available
- [ ] Firebase project permissions correct

## Future Enhancements

- **Custom Dashboards**: Real-time analytics views
- **Funnel Analysis**: User progression tracking
- **Revenue Analytics**: Advanced monetization metrics
- **A/B Testing**: Experiment framework integration
- **Cohort Analysis**: User segmentation and retention

---

**Last Updated**: March 2026
**Analytics Version**: 1.0
**Firebase Analytics SDK**: 10.4.0
