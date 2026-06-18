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

### Approved Event Registry

Use this registry as the source of truth for event naming. New analytics work should reuse existing names when semantics match.

| Event Name | Category | Required Parameters | Optional Parameters | Owner | Status |
|------------|----------|---------------------|---------------------|-------|--------|
| `app_open` | Lifecycle | None | None | Platform/Core | Active |
| `view_instructions` | Navigation | None | None | Game UX | Active |
| `view_leaderboard` | Navigation | None | None | Game UX | Active |
| `view_special_tiles` | Navigation | None | None | Game UX | Active |
| `leaderboard_tab_changed` | Leaderboard | `tab`, `is_daily_context` | `challenge_id` | Game UX | Active |
| `leaderboard_tab_restored` | Leaderboard | `tab`, `is_daily_context` | `challenge_id` | Game UX | Active |
| `weekly_leaderboard_control_changed` | Leaderboard | `control`, `value`, `is_daily_context` | `challenge_id` | Game UX | Active |
| `weekly_leaderboard_control_restored` | Leaderboard | `control`, `value`, `is_daily_context` | `challenge_id` | Game UX | Active |
| `level_start` | Gameplay | `level_num`, `rows`, `cols` | None | Gameplay | Active |
| `level_complete` | Gameplay | `level_num`, `score` | None | Gameplay | Active |
| `out_of_moves` | Gameplay | `level_num`, `score` | None | Gameplay | Active |
| `game_over_no_moves` | Gameplay | `score` | None | Gameplay | Active |
| `move` | Gameplay | `type` | None | Gameplay | Active |
| `restart` | Gameplay | `level` | None | Gameplay | Active |
| `mercy_spawn` | Gameplay | `penalty` | None | Gameplay | Active |
| `daily_start` | Daily Challenge | `challenge_id` | None | Gameplay | Active |
| `daily_submit` | Daily Challenge | `challenge_id`, `score`, `submitted` | None | Gameplay | Active |
| `daily_rank_available` | Daily Challenge | `challenge_id`, `rank_available` | `rank` | Gameplay | Active |
| `weekly_submit` | Weekly Ladder | `week_id`, `score`, `submitted` | None | Gameplay | Active |
| `weekly_rank_available` | Weekly Ladder | `week_id`, `rank_available` | `rank` | Gameplay | Active |
| `weekly_badge_earned` | Weekly Ladder | `week_id`, `badge`, `rank` | None | Gameplay | Active |
| `ad_impression` | Ads | `format` | `trigger`, `level_num` | Monetization | Active |
| `ad_dismissed` | Ads | `format` | `trigger`, `level_num` | Monetization | Active |

#### Registry Rules
1. Do not introduce a new event name without adding a row here.
2. Keep parameter names and types stable once dashboards depend on them.
3. If an event is superseded, mark Status as `Deprecated` and follow the Event Deprecation Policy.

### Shared Parameter Dictionary

This dictionary standardizes commonly reused analytics parameters across leaderboard and gameplay events.

| Parameter | BigQuery Type | Allowed Values / Format | Example | Notes |
|-----------|---------------|-------------------------|---------|-------|
| `tab` | `string_value` | `global`, `daily`, `weekly` | `weekly` | Used by leaderboard tab events |
| `control` | `string_value` | `week`, `top_limit` | `top_limit` | Used by weekly leaderboard control events |
| `value` | `int_value` | For `control=week`: ISO week id; for `control=top_limit`: `10`, `25`, `50` | `25` | Keep numeric for query consistency |
| `is_daily_context` | `int_value` | `0`, `1` | `1` | `1` means leaderboard opened from daily flow |
| `challenge_id` | `int_value` | Positive integer challenge identifier | `2026114` | Optional; present when daily challenge context is known |
| `week_id` | `int_value` | ISO week id used by weekly leaderboard bucket | `202611` | Used by weekly rank and submit events |
| `rank_available` | `int_value` | `0`, `1` | `1` | Boolean encoded as int for analytics filtering |
| `submitted` | `int_value` | `0`, `1` | `0` | Indicates score submission outcome |

#### Example Payloads

`leaderboard_tab_changed`
```json
{
  "tab": "weekly",
  "is_daily_context": 1,
  "challenge_id": 2026114
}
```

`weekly_leaderboard_control_changed`
```json
{
  "control": "top_limit",
  "value": 25,
  "is_daily_context": 0
}
```

`weekly_rank_available`
```json
{
  "week_id": 202611,
  "rank_available": 1,
  "rank": 7
}
```

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

### Operational Thresholds (Suggested)

Use a rolling 7-day baseline with day-over-day checks to avoid noisy alerts.

1. **Leaderboard Interaction Drop**
  - Signal: total `leaderboard_tab_changed` + `weekly_leaderboard_control_changed`
  - Alert when: daily count drops more than 30% versus 7-day average
  - Suggested action: verify release health, navigation entry points, and analytics ingestion

2. **Restore-to-Change Ratio Spike**
  - Signal: `leaderboard_tab_restored` / `leaderboard_tab_changed`
  - Alert when: ratio exceeds 2.0 for 2 consecutive days
  - Suggested action: validate tab-change listener behavior and duplicate event suppression logic

3. **Weekly Depth Selection Skew**
  - Signal: share of `weekly_leaderboard_control_changed` where `control=top_limit` and `value=10`
  - Alert when: share changes by more than +/-20 percentage points week-over-week
  - Suggested action: review UI defaults, chip interaction behavior, and any recent ranking UX changes

4. **Daily Context Coverage Regression**
  - Signal: events with `is_daily_context=1` among leaderboard events
  - Alert when: daily-context share falls below 50% of its 14-day median
  - Suggested action: verify Daily Challenge entry routing and `startOnDaily` propagation

5. **Missing Challenge Context Drift**
  - Signal: leaderboard events in daily context without `challenge_id`
  - Alert when: missing rate exceeds 5%
  - Suggested action: check challenge id wiring from game screen into leaderboard screen params

### Alerting Notes

- Prefer warning/critical tiers (for example 20% and 30% drop thresholds).
- Add release markers to dashboards so expected post-release shifts do not create false positives.
- Route alerts to engineering channel first; escalate to product only when issue persists beyond one day.

### Alert Owners and First Response Runbook

| Alert | Primary Owner | Secondary Owner | First Query to Run | Immediate Checks |
|-------|---------------|-----------------|--------------------|------------------|
| Leaderboard Interaction Drop | Mobile Engineer On-Call | Product Analyst | Query 1 + Query 2 from cookbook | Latest release marker, leaderboard entry points, Firebase export freshness |
| Restore-to-Change Ratio Spike | Mobile Engineer On-Call | QA Engineer | Query 1 with both `leaderboard_tab_changed` and `leaderboard_tab_restored` | Tab listener duplicate suppression, persisted index restore logic |
| Weekly Depth Selection Skew | Product Analyst | Mobile Engineer On-Call | Query 3 from cookbook | UI default changes, chip interaction behavior, recent leaderboard UX commits |
| Daily Context Coverage Regression | Game Feature Owner | Mobile Engineer On-Call | Query 2 + Query 5 from cookbook | Daily Challenge routing, `startOnDaily` propagation into leaderboard screen |
| Missing Challenge Context Drift | Mobile Engineer On-Call | Analytics Owner | Query 5 from cookbook filtered for `is_daily_context=1` and null `challenge_id` | Challenge ID wiring from game screen, analytics payload construction |

#### Escalation Template

When opening an incident, include:
1. Alert name and first trigger timestamp.
2. Current value, baseline value, and percent delta.
3. Release marker proximity (last 24 hours).
4. Result of first query and whether issue reproduces in DebugView.
5. Suspected owner and next update time.

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

## BigQuery Query Cookbook

The snippets below assume Firebase Analytics export tables in BigQuery using the standard pattern:
- `project_id.analytics_<property_id>.events_*`

Adjust project and dataset names for your environment.

### 1) Leaderboard Tab Preference (Last 30 Days)
```sql
SELECT
  ep_tab.value.string_value AS tab,
  COUNT(*) AS event_count
FROM `project_id.analytics_property.events_*`,
UNNEST(event_params) AS ep_tab
WHERE event_name = 'leaderboard_tab_changed'
  AND ep_tab.key = 'tab'
  AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
                      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY tab
ORDER BY event_count DESC;
```

### 2) Daily vs Non-Daily Leaderboard Context Mix
```sql
SELECT
  CAST(ep_ctx.value.int_value AS INT64) AS is_daily_context,
  COUNT(*) AS event_count
FROM `project_id.analytics_property.events_*`,
UNNEST(event_params) AS ep_ctx
WHERE event_name IN ('leaderboard_tab_changed', 'leaderboard_tab_restored')
  AND ep_ctx.key = 'is_daily_context'
  AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
                      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY is_daily_context
ORDER BY event_count DESC;
```

### 3) Weekly Top-Limit Selection Distribution
```sql
WITH controls AS (
  SELECT
    MAX(IF(ep.key = 'control', ep.value.string_value, NULL)) AS control,
    MAX(IF(ep.key = 'value', ep.value.int_value, NULL)) AS value
  FROM `project_id.analytics_property.events_*`,
  UNNEST(event_params) AS ep
  WHERE event_name = 'weekly_leaderboard_control_changed'
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY event_timestamp, user_pseudo_id
)
SELECT
  value AS top_limit,
  COUNT(*) AS selection_count
FROM controls
WHERE control = 'top_limit'
GROUP BY top_limit
ORDER BY selection_count DESC;
```

### 4) Weekly Browsing Breadth (Distinct Weeks per User)
```sql
WITH week_changes AS (
  SELECT
    user_pseudo_id,
    MAX(IF(ep.key = 'control', ep.value.string_value, NULL)) AS control,
    MAX(IF(ep.key = 'value', ep.value.int_value, NULL)) AS week_id
  FROM `project_id.analytics_property.events_*`,
  UNNEST(event_params) AS ep
  WHERE event_name = 'weekly_leaderboard_control_changed'
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY event_timestamp, user_pseudo_id
)
SELECT
  APPROX_QUANTILES(distinct_weeks, 5) AS week_breadth_quintiles,
  AVG(distinct_weeks) AS avg_distinct_weeks
FROM (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT week_id) AS distinct_weeks
  FROM week_changes
  WHERE control = 'week'
  GROUP BY user_pseudo_id
);
```

### 5) Challenge-Specific Leaderboard Engagement
```sql
WITH leaderboard_events AS (
  SELECT
    event_name,
    user_pseudo_id,
    MAX(IF(ep.key = 'challenge_id', ep.value.int_value, NULL)) AS challenge_id,
    MAX(IF(ep.key = 'is_daily_context', ep.value.int_value, NULL)) AS is_daily_context
  FROM `project_id.analytics_property.events_*`,
  UNNEST(event_params) AS ep
  WHERE event_name IN (
    'leaderboard_tab_changed',
    'leaderboard_tab_restored',
    'weekly_leaderboard_control_changed',
    'weekly_leaderboard_control_restored'
  )
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY event_name, event_timestamp, user_pseudo_id
)
SELECT
  challenge_id,
  is_daily_context,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM leaderboard_events
GROUP BY challenge_id, is_daily_context
ORDER BY events DESC;
```

## Query Compatibility Matrix

Use this matrix before analytics schema changes to identify which cookbook queries and dashboards may break.

| Query | Depends On Events | Required Parameters | Failure Mode If Missing | Mitigation |
|-------|-------------------|---------------------|-------------------------|------------|
| Query 1: Leaderboard Tab Preference | `leaderboard_tab_changed` | `tab` | Empty/under-counted tab distribution | Keep `tab` stable; backfill with dual-write during migrations |
| Query 2: Daily vs Non-Daily Context Mix | `leaderboard_tab_changed`, `leaderboard_tab_restored` | `is_daily_context` | Context segmentation collapses into null bucket | Preserve int encoding (`0/1`) and add default in emit path |
| Query 3: Weekly Top-Limit Selection Distribution | `weekly_leaderboard_control_changed` | `control`, `value` | Top-limit distribution unavailable or mixed with week ids | Keep `control` semantics (`top_limit`), keep `value` numeric |
| Query 4: Weekly Browsing Breadth | `weekly_leaderboard_control_changed` | `control`, `value` | Distinct-week breadth inflated/empty | Ensure `control=week` rows keep ISO week id in `value` |
| Query 5: Challenge-Specific Engagement | All 4 leaderboard interaction events | `is_daily_context`, `challenge_id` | Cannot attribute usage to challenge contexts | Keep optional `challenge_id` contract, validate null-rate alerts |

### Dashboard Ownership Map

| Query | Dashboard / Report | Primary Owner | Backup Owner | Refresh Cadence | Incident Channel |
|------|---------------------|---------------|--------------|-----------------|------------------|
| Query 1: Leaderboard Tab Preference | Leaderboard Engagement Overview | Product Analyst | Mobile Engineer On-Call | Daily | #analytics-alerts |
| Query 2: Daily vs Non-Daily Context Mix | Daily Challenge Funnel | Game Feature Owner | Product Analyst | Daily | #analytics-alerts |
| Query 3: Weekly Top-Limit Selection Distribution | Weekly Ladder UX Health | Game UX Owner | QA Engineer | Daily | #analytics-alerts |
| Query 4: Weekly Browsing Breadth | Weekly Retention Deep-Dive | Product Analyst | Analytics Owner | Weekly | #analytics-alerts |
| Query 5: Challenge-Specific Engagement | Challenge Attribution Report | Analytics Owner | Mobile Engineer On-Call | Daily | #analytics-alerts |

#### Ownership Rules
1. Primary Owner is responsible for first triage within business hours.
2. Backup Owner takes over when primary is unavailable or incident exceeds 4 hours.
3. Changes to dashboard/report naming must be reflected in this table in the same PR.

## Analytics Onboarding Checklist

Use this checklist before opening a PR that adds or changes analytics behavior.

### Design
- [ ] Confirm existing event names do not already cover the use case (check Approved Event Registry).
- [ ] Define required parameters and parameter types (`string_value` vs `int_value`).
- [ ] Identify dashboard/query consumers that will use the new signal.

### Implementation
- [ ] Emit through existing analytics pathways and preserve safe no-op behavior when Firebase is unavailable.
- [ ] Keep boolean-style flags encoded consistently (`0`/`1`) when used as numeric filters.
- [ ] Avoid mixed semantics for a single parameter key.

### Validation
- [ ] Verify event payloads in Firebase DebugView.
- [ ] Run relevant BigQuery cookbook queries (or temporary validation query) against staging export.
- [ ] Confirm no regression in existing query compatibility matrix assumptions.

### Documentation
- [ ] Add/update event rows in Approved Event Registry.
- [ ] Update Shared Parameter Dictionary for new parameters.
- [ ] Add a dated entry to Analytics Schema Changelog.
- [ ] Update Dashboard Ownership Map if ownership/report names changed.

### Release Safety
- [ ] If replacing events/params, follow Event Deprecation Policy and dual-write where required.
- [ ] Confirm alert thresholds and incident runbook still apply after the change.
- [ ] Communicate analytics-impact summary in PR description and release notes.

## PR Template Snippet (Analytics Changes)

Copy this into your pull request when adding or modifying analytics behavior:

```md
### Analytics Impact

#### What changed
- Events added/updated/deprecated:
- Parameters added/updated/deprecated:

#### Registry and Docs
- [ ] Approved Event Registry updated
- [ ] Shared Parameter Dictionary updated
- [ ] Analytics Schema Changelog updated
- [ ] Query Compatibility Matrix reviewed

#### Validation Evidence
- DebugView checks performed:
  - [ ] Event names verified
  - [ ] Parameter keys and types verified
- BigQuery checks performed:
  - [ ] Relevant cookbook queries run
  - [ ] Result summary attached

#### Compatibility and Migration
- [ ] Existing dashboards remain compatible
- [ ] Deprecation policy followed (if applicable)
- Dual-write window:
  - Start:
  - Planned removal:

#### Ownership and Alerts
- Primary dashboard owner notified:
- Alert/runbook updates needed:
```

## Common Anti-Patterns

Avoid these patterns when adding or changing analytics instrumentation.

1. **Silent Event Renames**
  - Anti-pattern: replacing an event name without dual-write or changelog updates.
  - Why it hurts: dashboards suddenly flatline and query joins fail.
  - Preferred approach: emit old + new names during compatibility window and follow Event Deprecation Policy.

2. **Mixed-Type Parameter Reuse**
  - Anti-pattern: writing the same parameter key as `string_value` in one event and `int_value` in another.
  - Why it hurts: BigQuery queries become brittle and null-heavy.
  - Preferred approach: keep each shared key type-stable and document in Shared Parameter Dictionary.

3. **Overloaded Parameter Semantics**
  - Anti-pattern: reusing a key like `value` for unrelated concepts without a discriminator.
  - Why it hurts: downstream metrics become ambiguous.
  - Preferred approach: pair generalized keys with explicit context keys (for example `control` + `value`).

4. **Missing Context on Segmentation Events**
  - Anti-pattern: emitting leaderboard events without `is_daily_context` or optional `challenge_id` where applicable.
  - Why it hurts: attribution analysis and funnel comparisons break.
  - Preferred approach: preserve context contract across emit points and monitor null-rate thresholds.

5. **No Validation Evidence in PRs**
  - Anti-pattern: merging analytics changes without DebugView/BigQuery confirmation.
  - Why it hurts: bad payloads can ship unnoticed.
  - Preferred approach: include PR template snippet with concrete validation evidence.

6. **Breaking Query Compatibility Without Matrix Update**
  - Anti-pattern: modifying event parameters but skipping Query Compatibility Matrix updates.
  - Why it hurts: breakages are discovered only after production impact.
  - Preferred approach: update matrix and run compatibility checklist before release.

## Reviewer Checklist (Analytics PRs)

Use this checklist during code review when a PR introduces or changes analytics behavior.

### Schema and Naming
- [ ] Event names match Approved Event Registry (or registry is updated in same PR).
- [ ] Parameter names are consistent with Shared Parameter Dictionary.
- [ ] Parameter types are stable (`string_value` vs `int_value`) across all emit points.

### Compatibility and Migration
- [ ] Query Compatibility Matrix impact is documented.
- [ ] If replacing events/params, dual-write plan and removal timeline are present.
- [ ] Event Deprecation Policy is followed for any rename/removal.

### Validation Quality
- [ ] PR includes DebugView evidence (event names and key parameters).
- [ ] PR includes BigQuery validation summary for affected cookbook queries.
- [ ] Null-rate and segmentation context expectations are explicitly checked (`is_daily_context`, `challenge_id` when applicable).

### Operational Readiness
- [ ] Dashboard Ownership Map reflects any report or owner changes.
- [ ] Alert/runbook implications are addressed.
- [ ] Analytics Schema Changelog has a dated entry describing the change.

### Approval Guidance
1. Request changes if any schema-impacting update lacks migration or validation evidence.
2. Approve only after docs, compatibility, and ownership updates are complete.

### Compatibility Checklist (Pre-Release)
1. Confirm every modified event/parameter appears in the matrix with an explicit mitigation.
2. Run all 5 cookbook queries in staging and compare row counts against previous release baseline.
3. If any query returns null-heavy output (>5% unexpected nulls), block schema removal and keep dual-write.
4. Update Analytics Schema Changelog with compatibility impact and expected dashboard owner actions.

## Release Sign-Off Checklist (Analytics)

Complete this checklist before shipping a release with analytics-impacting changes.

### Data Integrity
- [ ] Event names and parameter keys match Approved Event Registry.
- [ ] Parameter types are stable and unchanged where required.
- [ ] Segmentation-critical fields (`is_daily_context`, `challenge_id` where applicable) meet expected null-rate thresholds.

### Query and Dashboard Health
- [ ] All required cookbook queries execute successfully on staging export.
- [ ] Query outputs are within acceptable variance versus previous release baseline.
- [ ] Dashboard Ownership Map owners reviewed any schema-impacting updates.

### Alert and Runbook Readiness
- [ ] Operational thresholds still reflect expected behavior after change.
- [ ] Alert Owners and First Response Runbook references are up to date.
- [ ] Incident channel routing and escalation template are still valid.

### Migration and Deprecation
- [ ] Dual-write window is active for renamed/replaced events.
- [ ] Planned removal date is documented for deprecated schema.
- [ ] Event Deprecation Policy conditions are satisfied for go/no-go.

### Approvals
- [ ] Analytics owner sign-off recorded.
- [ ] Primary dashboard owner sign-off recorded.
- [ ] Release manager acknowledges analytics readiness in release notes.

## Analytics Schema Changelog

Use this section to track event/parameter changes that can impact dashboards, alerts, and downstream queries.

### 2026-03-24
- Added leaderboard tab interaction events:
  - `leaderboard_tab_changed`
  - `leaderboard_tab_restored`
- Added weekly leaderboard control events:
  - `weekly_leaderboard_control_changed`
  - `weekly_leaderboard_control_restored`
- Added leaderboard context parameters:
  - `is_daily_context`
  - `challenge_id` (optional)
- Added documented query cookbook and operational alert thresholds.

### 2025-10 (Baseline)
- Established core analytics coverage for lifecycle, navigation, gameplay, and ad events.
- Introduced safe no-op behavior for analytics calls when Firebase is unavailable.

## Event Deprecation Policy

Use this policy when renaming, removing, or replacing analytics events/parameters.

### Compatibility Window
1. Keep deprecated event names live for at least one full production release cycle.
2. Keep deprecated parameters live for at least 30 days after dashboard/query migration.
3. Do not remove old and new schemas in the same release.

### Required Migration Steps
1. Add the replacement event/parameter first and document it in the schema changelog.
2. Update dashboards and BigQuery queries to support both old and new schemas.
3. Add a temporary validation query that compares old vs new event volume.
4. Announce target removal date in release notes and analytics channel.
5. Remove deprecated schema only after compatibility window and validation pass.

### Rollback Safety
1. If replacement event volume drops below 90% of deprecated baseline for 24 hours, pause deprecation.
2. If alert thresholds regress after deprecation, restore old event emission in a hotfix.
3. Record rollback actions in this document under Analytics Schema Changelog.

### Naming Guidance
1. Prefer additive changes (`*_v2` or new parameter) over destructive renames.
2. Keep parameter types stable (`int_value` stays numeric, `string_value` stays string).
3. Avoid overloading one parameter with mixed semantic meanings.

## Metrics Glossary

Use these definitions consistently across dashboards, runbooks, and quarterly audit reports.

| Metric / Term | Definition | Formula / Interpretation |
|---------------|------------|--------------------------|
| Null-Rate | Percentage of events where a required/expected parameter is missing | `(missing_param_events / total_events_in_scope) * 100` |
| Dual-Write Window | Period where old and replacement schema are emitted in parallel | Ends only after compatibility checks and owner sign-off |
| MTTD | Mean Time To Detect incident conditions | `avg(detection_time - incident_start_time)` |
| MTTR | Mean Time To Resolve incidents to verified healthy state | `avg(resolution_time - incident_start_time)` |
| Alert Precision | Share of fired alerts that were true actionable incidents | `true_positive_alerts / total_alerts_fired` |
| Alert Recall | Share of true incidents detected by alerts | `detected_incidents / total_incidents` |
| Baseline Variance | Percent deviation from rolling baseline used by thresholds | `((current - baseline) / baseline) * 100` |
| Compatibility Pass | Outcome indicating schema changes did not break critical queries | All cookbook queries pass with acceptable variance and null-rate |

### Glossary Usage Notes
1. Include explicit metric formulas in incident notes when reporting MTTD, MTTR, or baseline variance.
2. Treat null-rate thresholds as metric-specific; default to 5% only when no stricter threshold exists.
3. If a new operational metric is introduced, add it here in the same PR.

## Known Limitations

### Export Latency
Firebase Analytics events are batched and exported asynchronously. Production dashboards typically show data with a **1-2 hour delay**:

| Scenario | Typical Latency | Maximum | Notes |
|----------|-----------------|---------|-------|
| Event collection to local app | < 100ms | N/A | In-app real-time observability |
| Local app to Firebase backend | ~1 minute | 5 minutes | Batching and network dependent |
| Firebase backend to BigQuery export | 30 minutes - 2 hours | 3-4 hours | Standard Firebase export window |
| **Total end-to-end latency** | **~1-2 hours** | **~4 hours** | All dashboards rely on BigQuery exports |

**Implication**: Fresh deployments or event schema changes won't appear in production dashboards for 1-2 hours. Use DebugView for immediate validation.

### DebugView vs Production
Firebase's DebugView shows events in real-time but with differences from production:

| Characteristic | DebugView | Production |
|---|---|---|
| Event delivery | Real-time (< 1 minute) | Batched (1-2 hour export delay) |
| Sample of users | Single debug device | 100% of users (if unsampled) |
| Validation | More lenient (show expected events) | Strict (export only valid events) |
| Schema matching | Best-effort conversion | Type-strict validation |
| Parameters | All custom params | Only schematized parameters |

**Implication**: If an event appears in DebugView but not in BigQuery production data 2+ hours later, check:
1. Parameter types (must match schema)
2. Parameter count (dropped params count as event loss)
3. Event naming (case-sensitive; exact match required)

### Sampling and Event Loss
Firebase Analytics automatically handles sampling and drops invalid events:

1. **Sampling**: If enabled in Firebase console for cost control, ~1% or more of users' events may be discarded. Production tables in BigQuery show `analytics_<property>.events_*` only for _included_ users/events.
2. **Type Validation**: Custom parameters that don't match their declared schema type are dropped silently; the event is still logged but the parameter is missing.
3. **Quota Enforcement**: Events exceeding Firebase's size limits (~500 bytes per event) are rejected. Large payloads should be split.

**Implication**: Always validate via DebugView _before_ checking production. A 100% null-rate in production may indicate sampling, sampling + type mismatch, or missing feature flag enabling the event tracking.

### BigQuery Time Zone and Date Bucketing
BigQuery export timestamps are in UTC. Events logged at 11 PM California time appear in the _next day's_ partition in BigQuery:

```sql
-- Events on "2026-03-24" in PT timezone may appear in:
SELECT COUNT(*) FROM `project.analytics_<property>.events_*`
WHERE DATE(TIMESTAMP_MICROS(event_timestamp), 'US/Pacific') = '2026-03-24'
  AND event_name = 'leaderboard_tab_changed'
-- This query will be slower due to timezone conversion; pre-compute if repeated
```

**Implication**: Always use UTC for queries or explicitly convert. Aggregating by event date without timezone correction skews results by up to 24 hours for US-based users.

### Parameter Constraints
Custom parameters have Firebase enforced limits:

| Constraint | Limit | Consequence |
|---|---|---|
| Max parameters per event | 25 | Excess parameters silently dropped |
| Max string length per parameter | 2048 characters | Truncated to 2046, logged as-is |
| Parameter name length | 40 characters | Names longer than 40 chars rejected |
| Reserved parameter names | Prefix `firebase_*`, `ga_*` | Events rejected if conflicting |

**Implication**: Leaderboard context parameters (`tab`, `control`, `value`, `week_id`, `challenge_id`) are all < 40 chars and unconstrained. If new parameters are added, validate names and content length in code review.

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

## Frequently Asked Questions

### General Analytics

**Q: Why don't I see my events in the dashboard immediately?**
A: Firebase batches events and exports them asynchronously. Expect a 1-2 hour delay from event collection to BigQuery production tables. Use DebugView for real-time validation (< 1 minute) and to confirm the event schema is correct. Dashboards are never real-time; they always reflect BatchWrite exports from 1-4 hours ago.

**Q: How do I test analytics locally?**
A: Use Firebase DebugView in the Firebase console while running the debug build:
1. Start the app in debug mode: `flutter run --debug`
2. Open Firebase Console → Project → Analytics → DebugView
3. Events appear in real-time; filter by device ID, user ID, or event name
4. Verify parameter types, values, and structure before committing code

**Q: What's the difference between DebugView and BigQuery production data?**
A: See [Known Limitations: DebugView vs Production](javascript:void(0)). TL;DR: DebugView is real-time and lenient; production is batched, strict, and delayed 1-2 hours. An event that appears in DebugView but not in BigQuery 2+ hours later suggests a schema mismatch (parameter type, missing required param, invalid enum value).

**Q: Can I change event names or parameter names after releasing?**
A: No—it creates a schema break. Old events with the old name stop being captured. Use the [Event Deprecation Policy](#event-deprecation-policy): create a new event/parameter, maintain both in parallel for 1 release + 30 days, then deprecate the old one. This ensures dashboards don't break and data continuity is maintained.

**Q: What happens if the same event fires twice in quick succession?**
A: Both events are logged independently. There's no deduplication. If you need to prevent duplicate events, add application-level debouncing (e.g., track the last event timestamp and ignore events within 100ms).

**Q: How do I ensure an event is always sent, even if the network is offline?**
A: Firebase Analytics handles local queueing automatically. If the device goes offline, events are buffered locally and sent when connectivity is restored (up to a queue limit, then oldest events are dropped). You don't need to handle this explicitly.

**Q: Can I send very large payloads as event parameters?**
A: No—Firebase limits events to ~500 bytes total. Custom parameters have a 2048 character limit per string and 25 parameters max per event. If you need to send more data, either:
1. Split across multiple events
2. Store the data in Firestore and reference it by ID in the event
3. Use user properties for static context instead of repeating it in every event

### Leaderboard-Specific Questions

**Q: Why are there four leaderboard events instead of one?**
A: The four events (`leaderboard_tab_changed`, `leaderboard_tab_restored`, `weekly_leaderboard_control_changed`, `weekly_leaderboard_control_restored`) distinguish between user-initiated changes and automatic restoration by the system. This allows product analysts to:
- Separate intentional user preferences from accidental state resets
- Measure whether particular UI states are "sticky" or are being reset
- Track feature adoption (if restorations are > changes, users may not understand persistence)

**Q: What's the difference between `tab_changed` and `tab_restored`?**
A: `tab_changed` fires when the user taps a leaderboard tab (intentional action). `tab_restored` fires when the app restores the user's previous session state on app relaunch (automatic, unintentional). This matters for analytics: if 90% of "changes" are actually app restarts, engagement metrics are misleading.

**Q: Should I cache the last tab/control selection to avoid too many events?**
A: No—log every user action. Let downstream analytics deduplicate if needed. Filtering at source loses valuable signal (e.g., toggling between tabs rapidly is a different user behavior than settling on one tab). BigQuery queries can group events by user/session if needed.

**Q: What if a user changes the tab while the control selection is still loading?**
A: Both events will fire independently. Don't try to suppress the `tab_changed` event because the control is still loading—that's normal user behavior. The `is_daily_context` parameter ensures the event is correctly attributed to either daily or weekly context.

**Q: Why is `is_daily_context` a parameter instead of splitting into separate events?**
A: Using `daily_leaderboard_tab_changed` and `weekly_leaderboard_tab_changed` instead would create maintenance burden (twice the events to update, twice the queries to write). By parameterizing the context, we have one canonical event, and BigQuery queries filter by context when needed. This also makes it easier to introduce completely new contexts later without schema explosion.

**Q: What does `challenge_id` do? It's optional, but when should I include it?**
A: `challenge_id` is included when leaderboard interaction happens _within_ a challenge-specific scope (e.g., leaderboard filtered by "this week's tournament"). If the user is viewing the global, unfiltered leaderboard, omit `challenge_id` (send it as null or don't include the parameter). This distinguishes "browsing global leaderboard" from "checking progress in a specific challenge."

**Q: If a user switches contexts (daily ↔ weekly), do I log two events or one?**
A: Only one event: `tab_changed` with the new tab and matching `is_daily_context` value. Don't log an "exited daily context" event—the old context is implicitly dropped when a new tab is selected.

### Schema and Migration

**Q: How do I know if a schema change will break existing queries?**
A: Use the [Query Compatibility Matrix](#query-compatibility-matrix) in the approval checklist. Before changing an event or parameter:
1. Pick one of the 5 cookbook queries from the matrix
2. Simulate your change in a BigQuery sandbox table
3. Run the query against the modified schema; if it fails or drops > 5% of rows, the change breaks compatibility
4. Consult [@analytics-owner](#ownership-contacts) before merging

**Q: What's the difference between adding a new event and adding a parameter to an existing event?**
A: - **New event**: No existing queries are affected; old dashboards don't break. Safe to add anytime.
- **New parameter on existing event**: Existing queries still work (parameter is optional in UNNEST), but queries looking for that parameter won't see older events. Only add parameters before a release, not mid-release.

**Q: Can I rename a parameter without breaking dashboards?**
A: Not directly. Follow the deprecation policy: create the new parameter name, log both old and new names in parallel for 1 release + 30 days, then stop logging the old name. Queries that hardcode the old name will show a drop in recent data; those queries need to be updated during the deprecation window.

### Queries and Dashboards

**Q: Why do my queries return nulls for the new leaderboard parameters?**
A: Null parameters occur when:
1. **Event pre-dates the parameter**: The app version that logs the parameter wasn't deployed yet → events from old app versions lack the parameter
2. **Parameter type mismatch**: DebugView shows the param, but BigQuery rejected it because the value type didn't match the schema (string vs number)
3. **Parameter name typo**: Check exact capitalization and spelling; `tab` ≠ `Tab` ≠ `tabs`
4. **Sampling**: If sampling is enabled, a subset of users' events are dropped entirely

Use DebugView to verify the parameter exists and has the correct type, then check the app version deployed and event_timestamp to understand which events are affected.

**Q: How do I write a query that counts "sessions with leaderboard interaction"?**
A: Use the [BigQuery Query Cookbook: Browsing Breadth](#bigquery-query-cookbook) sample, which groups leaderboard events by user_pseudo_id and session_id. Count distinct sessions with at least one leaderboard_* event. Be aware of the [latency caveat](#export-latency): today's results will be incomplete; use 2+ days ago for stable counts.

**Q: Can I export analytics data to something other than BigQuery?**
A: Not yet. Firebase Analytics exports to BigQuery only (standard in all projects). Exporting to data warehouse, data lake, or third-party tool requires a custom ETL pipeline from BigQuery. Contact [@analytics-owner](#ownership-contacts) for guidance on integration patterns.

### Performance and Troubleshooting

**Q: Will logging too many events slow down the app?**
A: No—Firebase Analytics is asynchronous and non-blocking. Events are queued and sent in batches without blocking UI threads. You can log thousands of events per session without performance impact. The limiting factor is quota (25 parameters per event, ~500 bytes per event max).

**Q: What size should my event buffer be?**
A: Firebase handles buffering automatically. Local queue limit is ~200 events; older events are discarded if the queue fills. In practice, this rarely happens because Firebase flushes the queue periodically and on network connectivity changes. You don't need to manage this manually.

**Q: How do I know if events are being dropped due to quota limits?**
A: Check:
1. **DebugView**: Event appears in real-time → event was collected successfully
2. **BigQuery 2+ hours later**: Event missing → dropped during export (likely quota/type violation)
3. **Check event size**: Each parameter and event name counts toward the ~500 byte limit. Long parameter values or many params increase drop risk.

If events disappear between DebugView and BigQuery, it's almost always a parameter type mismatch (schema defines string, you sent number).

**Q: Is there a cost to logging events?**
A: Firebase Analytics is free for all events. BigQuery export consumes BigQuery quota (storage and query costs); large datasets may incur charges. See [COST_EFFECTIVE_CICD.md](../docs/COST_EFFECTIVE_CICD.md) for Firebase and BigQuery pricing considerations. Sampling parameters in the Firebase console can reduce BigQuery costs by discarding a percentage of events.

## Best Practices Guide

### Event Design

**DO:**
- **Log intentional user actions**: Tab taps, control changes, feature interactions. One event per semantic action.
- **Parameterize context**: Use parameters (`is_daily_context`, `challenge_id`) instead of creating separate events for each context variation (e.g., don't create `daily_tab_changed` and `weekly_tab_changed` events; instead use parameters).
- **Use enums for parameters**: Define allowed values (`tab: "global" | "daily" | "weekly"`) and validate on the client side. This prevents invalid values from appearing in the event stream.
- **Include high-cardinality identifiers as parameters**: `challenge_id`, `user_id`, `session_id` should be parameters, not event names (event names should be low-cardinality for grouping).
- **Document parameter semantics**: Include examples and allowed values in the event registry. Ambiguous parameters cause bugs downstream.
- **Test in DebugView before deploying**: Every event schema change should be validated in DebugView with the actual app behavior before reaching production.
- **Version your events**: When making breaking changes, create `event_v2` and deprecate `event_v1` rather than renaming (renaming breaks data continuity).

**DON'T:**
- **Don't log personally identifiable information (PII)**: Usernames, email, real names, locations, phone numbers. Firebase keeps event logs; PII violates privacy.
- **Don't log authentication tokens or secrets**: Session tokens, API keys, passwords should never appear in events.
- **Don't create overly specific event names**: Don't create `leaderboard_tab_tapped_at_3pm_on_tuesday` for events. Use a single `tab_changed` event with parameters for context.
- **Don't assume parameter order matters**: Event parameters are a map, not ordered. `{tab: "daily", control: "week"}` is identical to `{control: "week", tab: "daily"}`.
- **Don't log the same information in multiple parameters**: Avoid `{tab_name: "daily", tab_id: 1, tab_label: "Daily"}`. Pick one canonical parameter name.
- **Don't send raw JSON objects as event parameter values**: Firebase expects strings, numbers, or arrays. Passing `{nested: {object: true}}` will be rejected or serialized unexpectedly.
- **Don't rely on null values to mean "not set"**: If a parameter is optional, omit it entirely instead of setting it to null (null may be converted to the string "null").
- **Don't log streaming data (coordinates, accelerometer, GPS)**: High-frequency sensor data doesn't belong in analytics events. Use telemetry APIs or stream processing instead.

### Parameter Guidelines

**DO:**
- **Use consistent naming**: `tab` for leaderboard tabs, `control` for leaderboard controls. Avoid `selected_tab`, `current_tab`, `tab_name` for the same concept.
- **Use snake_case consistently**: `is_daily_context`, `challenge_id`. Never mix `camelCase` with `snake_case`.
- **Declare types explicitly**: Document whether each parameter is string, number, boolean. Types are strict in BigQuery.
- **Validate ranges**: For numeric parameters, enforce allowed values (e.g., `top_limit` must be one of `[10, 25, 50]`). Reject invalid values in the app.
- **Use consistent string values**: `is_daily_context: true/false` (boolean) is better than `context: "daily"/"global"` (string enum). Fewer cardinality, smaller event size.
- **Include contextual parameters in every event of a category**: If `leaderboard_tab_changed` includes `is_daily_context`, then `leaderboard_tab_restored` should too, so queries don't have to handle missing parameters.
- **Test edge cases**: Empty strings, zero, negative numbers, very long strings. Verify the app handles and logs these correctly.

**DON'T:**
- **Don't rename parameter types mid-release**: If `top_limit` was logged as a string `"10"` in v1, don't switch to numeric `10` in v2 without deprecation. This breaks old data.
- **Don't mix boolean and string for the same concept**: `is_daily: true` vs `context_type: "daily"` in different events. Pick one convention and stick to it.
- **Don't create parameters with unbounded cardinality**: Avoid `parameter: user_id` (millions of unique values; wastes quota). Use Firebase user ID feature instead.
- **Don't log dynamic property values that change frequently**: `app_version`, `device_model` are better handled as app-level properties set once, not in every event.
- **Don't assume "undefined" parameters are safe**: If a parameter is missing and the schema requires it, the entire event may be rejected by BigQuery validation.

### Schema Evolution

**DO:**
- **Plan schema additions before the release**: Announce new events/parameters in the PR checklist so reviewers know what to expect in downstream queries.
- **Use the deprecation window**: Give dashboards 1 release + 30 days to migrate off old event/parameter names before retiring them. Publish a deprecation notice in DOCUMENTATION_INDEX.md.
- **Check backward compatibility**: Before merging a schema change, verify that the 5 cookbook queries still work and don't have sudden data drops.
- **Test with sampled data**: If changing an event that already has production data, test queries on real BigQuery data (not just sandbox) to catch surprises.
- **Document why parameters are optional**: If a parameter is conditional (e.g., `challenge_id` only appears when in a challenge), explain in the event registry exactly when it's present.
- **Coordinate with analytics owners**: Use the [Analytics Onboarding Checklist](#analytics-onboarding-checklist) and [@analytics-owner](#ownership-contacts) approval before shipping schema changes.

**DON'T:**
- **Don't ship unnamed events or parameters**: Every event and parameter must be in the [Approved Event Registry](#approved-event-registry) before it goes to production.
- **Don't change parameter semantics without renaming**: If `challenge_id` was a leaderboard challenge ID and you want it to mean "any challenge ID," create `challenge_context_id` instead. Reuse causes confusion.
- **Don't break producer-consumer contracts**: Inform mobile team, analytics team, and dashboard owners before changing event definitions. Coordinate PRs if possible.
- **Don't deploy schema changes on Friday**: Schema changes have 1-2 hour latency. If something breaks, you'll be debugging over the weekend. Deploy earlier in the week.

### Query and Dashboard Best Practices

**DO:**
- **Use the cookbook queries as templates**: The [5 BigQuery Query Cookbook](#bigquery-query-cookbook) patterns are tested and compatible with the event schema. Start with them and customize.
- **Aggregate by user_pseudo_id, not user_id**: Firebase's `user_pseudo_id` is stable and available even for anonymous users. `user_id` (set via setUserId) is only available for identified users.
- **Filter by date using `event_date` or `TIMESTAMP_MICROS(event_timestamp)`**: Always use UTC and be aware of [BigQuery Time Zone and Date Bucketing](#bigquery-time-zone-and-date-bucketing) edge cases.
- **Use UNNEST for parameters**: `SELECT * FROM table, UNNEST(event_params) AS param WHERE param.key = 'tab'` is the standard pattern.
- **Cache expensive queries**: If a query takes > 10 seconds, materialize results to a table and refresh daily (via scheduled query or ETL).
- **Join production BigQuery exports with Firestore for rich context**: Use `user_pseudo_id` to join events with user profiles in Firestore for additional attributes.
- **Set up alerts for null-rate spikes**: Every metric query should have an alert for unexpected null-rate increases (sign of a data pipeline break).

**DON'T:**
- **Don't query real-time data (same day)**: Production dashboards are 1-2 hours behind. If you need today's results, use DebugView or query raw events in near-real-time tables (if available).
- **Don't assume event ordering within a session**: If you need precise event order, use `event_timestamp` to sort, not the row order from BigQuery.
- **Don't forget DISTINCT when counting users**: `SELECT COUNT(*) FROM events` counts events, not users. Use `COUNT(DISTINCT user_pseudo_id)` for user counts.
- **Don't hardcode event names**: Define canonical event names as constants in your analytics module, not as magic strings in queries. This reduces typos.
- **Don't create huge JOIN expressions**: Dashboards with 10+ table joins are slow and unmaintainable. If you need that much context, prepares a materialized view first.
- **Don't expose raw parameters in dashboards**: If a parameter has 1,000 unique values, show a top-10 breakdown instead of a dropdown with all 1,000 options.

### Incident Response Best Practices

**DO:**
- **Check DebugView immediately when events drop**: It's the fastest way to rule out client-side bugs vs server issues.
- **Use the [Dashboard Ownership Map](#dashboard-ownership-map) to route incidents**: Quickly identify who owns a dashboard and contact them.
- **Log incident facts in the [Quarterly Audit Report](#quarterly-audit-report-template)**: "On 2026-03-24, leaderboard_tab_changed events dropped 50% for 2 hours due to Firebase quota limits." Prevents repeat incidents.
- **Create a runbook for each high-priority dashboard**: Step-by-step troubleshooting, escalation contacts, common fixes.
- **Set MTTD (Mean Time To Detect) targets**: "Any events dropping to 0 for 5+ minutes should trigger an alert." Measure actual MTTD and improve root causes.
- **Communicate with downstream teams**: If a data quality issue exists, notify product teams and update dashboard caveats.

**DON'T:**
- **Don't assume "no events" means fraud or user churn**: Could be a deployment issue, Firebase outage, or client-side logging bug. Investigate systematically using the [Troubleshooting](#troubleshooting) section.
- **Don't over-respond to noise**: Event counts naturally vary by time of day. Thresholds should be based on historical baselines, not static numbers.
- **Don't silence alerts permanently**: If an alert triggers repeatedly, don't mute it; fix the root cause or adjust the threshold.
- **Don't forget to update the Monthly Maintenance Cadence**: Mark incidents, document root causes, and assign follow-ups to prevent recurrence.

### Review and Approval Best Practices

**DO:**
- **Use the [PR Impact Template](#pr-impact-template-snippet)**: Every analytics PR should include a summary of schema changes, compatibility impact, and testing evidence.
- **Reference the [Reviewer Checklist](#reviewer-checklist)** when approving: Verify naming, compatibility, validation quality, and readiness before approving.
- **Ask for DebugView evidence**: Require screenshots or logs showing the event appears in DebugView before approving schema changes.
- **Review the [Common Anti-Patterns](#common-anti-patterns)** beforehand**: Many recurring issues are documented there and can be caught in review.
- **Coordinate timing with the release manager**: Schema changes should go out with mobile releases, not mid-sprint. Sync with [@release-manager](#ownership-contacts).
- **Require updated documentation**: If events or parameters change, the PR should also update the [Approved Event Registry](#approved-event-registry) and parameter dictionary.

**DON'T:**
- **Don't approve PRs without evidence**: Require actual test results, DebugView screenshots, or BigQuery query results—not just "I think it will work."
- **Don't approve breaking changes without deprecation**: If an event/parameter name changes, require the deprecation policy be applied.
- **Don't skip the compatibility matrix**: Verify that the [Query Compatibility Matrix](#query-compatibility-matrix) changes don't break cookbook queries.
- **Don't approve during code review conflicts**: If there's disagreement about event naming or schema, escalate to [@analytics-owner](#ownership-contacts) before merging.

## Integration Checklist: Adding a New Event

Use this step-by-step checklist when adding a new analytics event. Each phase should be completed before proceeding to the next. Estimated time: 2-3 hours for a straightforward event, 1 day for complex events with multiple parameters.

### Phase 1: Design (30 minutes)

- [ ] **Define the event semantics**: What user action or system state change does this event represent?
  - Example: "User switches leaderboard tab" → `leaderboard_tab_changed`
  - Avoid: "User interaction event" (too vague)
- [ ] **Choose the event name**: Use snake_case, lowercase, descriptive (max 40 chars). Cross-check against existing events in the [Approved Event Registry](#approved-event-registry) for naming consistency.
  - NEW events: `context_feature_action` (e.g., `leaderboard_tab_changed`)
  - DEPRECATIONS: Append `_legacy` or `_v1` to old name, not new name
- [ ] **List required parameters**: What context is essential to understand the event?
  - Which are always present (required)?
  - Which are conditional (optional)?
- [ ] **Define parameter names and types**: Use consistent naming (`is_daily_context`, not `daily_context` or `is_daily`). Decide types: string enums, numeric IDs, boolean flags.
  - Example: `{tab: string, is_daily_context: boolean, challenge_id?: string}`
- [ ] **Document allowed values**: If a parameter is an enum, list all valid values.
  - Example: `tab` ∈ `{global, daily, weekly}`
- [ ] **Check Firebase limits**: Total event size ~500 bytes, max 25 params. Count bytes if params are long.
  - If over budget, split into two events or move to user properties
- [ ] **Reference the event in design doc**: Link this analytics event from the feature design doc or issue. Ensure product and engineering agree on the tracking.
- [ ] **Follow naming conventions**: Compare against [Best Practices: Parameter Guidelines](#parameter-guidelines). Align with existing parameter names if tracking similar concepts.

### Phase 2: Implementation (1 hour)

- [ ] **Add event to the AnalyticsService**: Create a method that invokes `logEvent()` with the event name and parameters.
  ```dart
  Future<void> logLeaderboardTabChanged({
    required String tab,
    required bool isDailyContext,
    String? challengeId,
  }) async {
    final analytics = _analyticsSafe;
    if (analytics == null) return;
    
    await analytics.logEvent(
      name: 'leaderboard_tab_changed',
      parameters: {
        'tab': tab,
        'is_daily_context': isDailyContext,
        if (challengeId != null) 'challenge_id': challengeId,
      },
    );
  }
  ```
- [ ] **Validate parameters in code**: Enforce enum values, type checks, and range constraints before logging.
  ```dart
  assert(
    ['global', 'daily', 'weekly'].contains(tab),
    'Invalid tab: $tab'
  );
  ```
- [ ] **Call the event at the right place**: Fire the event immediately after the user action, on the main thread (AnalyticsService is thread-safe).
  - Leaderboard tab taps → Fire in `onTabSelected()` callback
  - Don't fire in render/build methods (too frequent)
- [ ] **Test with DebugView in the emulator/simulator**: 
  - Run `flutter run --debug`
  - Trigger the user action
  - Check Firebase Console → Analytics → DebugView
  - Verify the event appears with correct name, parameters, and types (within 1 minute)
- [ ] **Capture DebugView screenshots**: Include them in the PR for evidence (required for approval).
- [ ] **Test offline behavior**: Disconnect network, trigger event, reconnect. Verify the event appears in DebugView when connectivity is restored.
- [ ] **Test on a real device**: Emulator networking can differ from production. Test on an iPhone/Android if possible.
- [ ] **Check for duplicate logging**: Ensure the event fires exactly once per user action (not multiple times on screen redraws).

### Phase 3: Documentation (45 minutes)

- [ ] **Add event to the Approved Event Registry**: Add a new row in the registry table with:
  - Event name: `leaderboard_tab_changed`
  - Category: `user_interaction` or `gameplay`
  - Required params: `tab, is_daily_context`
  - Optional params: `challenge_id`
  - Owner: `@game-feature-owner` or `@analytics-owner`
  - Status: `active`
- [ ] **Document all parameters in the Shared Parameter Dictionary**: Add entries for any new parameters, including:
  - Type (string, number, boolean)
  - Allowed values (if enum)
  - Example payload
  - Semantics (when is it set? what does it mean?)
- [ ] **Add a BigQuery query example in the Cookbook**: Write and test a sample query that uses the new event.
  ```sql
  -- Count daily leaderboard interactions by user
  SELECT
    user_pseudo_id,
    COUNT(*) as interaction_count,
    ARRAY_AGG(DISTINCT param.value.string_value) as tabs_viewed
  FROM `project.analytics_*.events_*`
  CROSS JOIN UNNEST(event_params) AS param
  WHERE event_name = 'leaderboard_tab_changed'
    AND DATE(TIMESTAMP_MICROS(event_timestamp), 'US/Pacific') = '2026-03-24'
    AND param.key = 'tab'
  GROUP BY user_pseudo_id
  ```
- [ ] **Update the Query Compatibility Matrix**: List which cookbook queries use the new event. If the event is incompatible with an existing query, document the workaround.
- [ ] **Write an FAQ entry** (if non-obvious): Add Q&A to the [FAQ](#frequently-asked-questions) if you anticipate common questions about this event.
  - Example: "Q: When is `challenge_id` included? A: Only when the leaderboard is filtered to a specific challenge."
- [ ] **Link from docs/DOCUMENTATION_INDEX.md**: Ensure the event is discoverable from the main documentation index.

### Phase 4: Code Review Validation (30 minutes)

- [ ] **Create a PR with all changes**: Include implementation, tests, and documentation.
- [ ] **Use the PR Impact Template**: Include the [PR Impact Template Snippet](#pr-impact-template-snippet) in the PR description:
  ```markdown
  ## Analytics Impact
  - **New Events**: `leaderboard_tab_changed`
  - **New Parameters**: `is_daily_context`, `challenge_id`
  - **Breaking Changes**: None
  - **Compatibility**: All cookbook queries still work
  - **DebugView Evidence**: [attach screenshot]
  ```
- [ ] **Request review from @analytics-owner**: Approval required for schema changes.
- [ ] **Address reviewer comments**: 
  - If naming is questioned, be prepared to rename (do it before shipping)
  - If compatibility is questioned, run queries in BigQuery and show results
  - If documentation is incomplete, add missing details before merge
- [ ] **Verify compatibility matrix passes**: Reviewer will check all 5 cookbook queries still work.
- [ ] **Link to the feature issue/design doc**: Ensure traceability for product context.

### Phase 5: Release and Deployment (30 minutes)

- [ ] **Merge to develop branch**: Ensure CI passes (no secrets, pre-commit checks).
- [ ] **Coordinate with mobile release**: Analytics events need to be released with the app version that logs them. Don't merge events mid-release cycle.
- [ ] **Tag the release**: When mobile app version tags, events are live.
- [ ] **Wait for production export**: Events logged in production take 1-2 hours to appear in BigQuery. Don't expect real-time dashboards to show new events immediately.
- [ ] **Validate in production after 2 hours**: 
  - Run your BigQuery cookbook query against production data
  - Verify event count > 0 and parameters are populated
  - If null-rate > 5%, investigate immediately (likely a schema mismatch)
- [ ] **Add to documentation changelog**: Update the [Schema Changelog](#schema-changelog) with:
  ```markdown
  **2026-03-24**: Added leaderboard_tab_changed event with tab, is_daily_context, challenge_id parameters. @game-feature-owner.
  ```
- [ ] **Notify downstream users**: Send a message to `#notifications` or relevant channel about the new event so analysts know to expect it.
- [ ] **Set up any new dashboards**: If this event powers a new dashboard, create it now that production data is flowing.
- [ ] **Create a runbook** (if event is critical): If this event is business-critical, add it to the [Dashboard Ownership Map](#dashboard-ownership-map) and create a troubleshooting runbook.

### Phase 6: Post-Launch Monitoring (Ongoing, 15 minutes daily for 1 week)

- [ ] **Monitor null-rate**: Set a threshold (default 5%) and alert if null-rate spikes. Check daily for the first week.
- [ ] **Monitor event count trend**: Event volume should be consistent with user activity. Sudden drops indicate a bug.
- [ ] **Check no queries broke**: Verify the 5 cookbook queries still run without errors or performance regression.
- [ ] **Review incident logs**: If any production incidents related to this event, add to the [Quarterly Audit Report](#quarterly-audit-report-template).
- [ ] **Collect feedback**: Ask product and engineering teams if the event is meeting their needs. Adjust parameters in the next release if feedback suggests improvements.

### Common Integration Pitfalls and How to Avoid Them

| Pitfall | Why It Happens | Prevention |
|---------|---|---|
| Event appears in DebugView but not in BigQuery 2+ hours later | Parameter type mismatch (FirebaseAnalytics logged string "10" but schema expects number) | Verify in DebugView that raw_value types match schema; use `int` in Dart for numbers, not `String("10")` |
| Same event fires 5+ times per action | Event called in Widget.build() method | Fire events in callbacks (onTap, onChanged), not render methods |
| Null-rate jumps to 50% after release | Parameter renamed but old queries hardcoded old name | Use deprecation policy: launch old+new param names together for 1 release |
| Integration takes 3 days instead of 3 hours | Skipped DebugView validation early, discovered schema errors too late | Do Phase 2 (Implementation) + DebugView test before starting Phase 3 (Documentation) |
| Reviewer rejects PR for naming | Event name inconsistent with existing events | Check [Approved Event Registry](#approved-event-registry) before coding; propose naming early |
| BigQuery query returns 0 rows | Event name typo in query (case-sensitive) | Define event names as constants in AnalyticsService; reuse the same constant in queries |
| Event fires in old app versions but new schema expects it | Didn't coordinate release timing | Always release analytics changes with the mobile app version increment, not separately |

### Troubleshooting Integration Issues

**DebugView shows 0 events but code calls analytics.logEvent():**
- Check `_analyticsSafe` is not returning null (Firebase not initialized)
- Verify you're on the main thread (AnalyticsService.logEvent is not awaited; check logs for exceptions)
- Ensure Firebase project credentials are correct in `firebase.json`
- Restart the emulator

**DebugView shows event with null/truncated parameters:**
- Check parameter value length (>2048 chars are truncated)
- Verify parameter type (Dart String is logged as string_value; int as int_value; bool as bool_value in raw_value)
- Check for special characters in parameter names (must be [a-z0-9_]; no hyphens or spaces)

**BigQuery query returns "event_params is not a repeated field" error:**
- Use UNNEST(event_params) to flatten the repeated field into rows
- Verify the event_table includes `event_params` column (should be automatic for Firebase exports)

**Event count in BigQuery is 10x lower than expected:**
- Check if sampling is enabled in Firebase console (may discard 90% of events)
- Verify parameter validation in code isn't rejecting valid events (add logging to catch assertions)
- Check if old app versions without the event are still in active use (diluting counts)

## Query Templates Gallery

These reusable templates complement the cookbook and are intended for fast copy/paste adaptation.

### How to Use These Templates

1. Replace `project_id.analytics_property_id.events_*` with your export table.
2. Replace date windows in `_TABLE_SUFFIX` with the desired range.
3. Keep parameter extraction patterns consistent (`UNNEST(event_params)`).
4. Prefer UTC for stable daily aggregates; convert timezone only when needed.

### Template 1: Daily Event Volume (Baseline)

```sql
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS day,
  event_name,
  COUNT(*) AS event_count
FROM `project_id.analytics_property_id.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20260301' AND '20260331'
  AND event_name IN (
    'leaderboard_tab_changed',
    'leaderboard_tab_restored',
    'weekly_leaderboard_control_changed',
    'weekly_leaderboard_control_restored'
  )
GROUP BY day, event_name
ORDER BY day, event_name;
```

Use when validating rollout health and checking for abrupt drops after a release.

### Template 2: Parameter Null-Rate by Event

```sql
WITH extracted AS (
  SELECT
    event_name,
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'tab') AS tab,
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'control') AS control,
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'value') AS value,
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'challenge_id') AS challenge_id
  FROM `project_id.analytics_property_id.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20260320' AND '20260324'
    AND event_name LIKE '%leaderboard%'
)
SELECT
  event_name,
  COUNT(*) AS total_rows,
  SAFE_DIVIDE(COUNTIF(tab IS NULL), COUNT(*)) AS tab_null_rate,
  SAFE_DIVIDE(COUNTIF(control IS NULL), COUNT(*)) AS control_null_rate,
  SAFE_DIVIDE(COUNTIF(value IS NULL), COUNT(*)) AS value_null_rate,
  SAFE_DIVIDE(COUNTIF(challenge_id IS NULL), COUNT(*)) AS challenge_id_null_rate
FROM extracted
GROUP BY event_name
ORDER BY total_rows DESC;
```

Use for schema validation and alert tuning when new parameters launch.

### Template 3: Distinct User Reach and Session Reach

```sql
WITH base AS (
  SELECT
    event_name,
    user_pseudo_id,
    (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id') AS ga_session_id
  FROM `project_id.analytics_property_id.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20260320' AND '20260324'
    AND event_name IN ('leaderboard_tab_changed', 'weekly_leaderboard_control_changed')
)
SELECT
  event_name,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS unique_users,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))) AS unique_sessions
FROM base
GROUP BY event_name
ORDER BY events DESC;
```

Use to measure adoption breadth without conflating repeated actions from the same users.

### Template 4: Enum Distribution Quality Check

```sql
WITH tabs AS (
  SELECT
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'tab') AS tab
  FROM `project_id.analytics_property_id.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20260320' AND '20260324'
    AND event_name = 'leaderboard_tab_changed'
)
SELECT
  COALESCE(tab, 'NULL_OR_MISSING') AS tab_value,
  COUNT(*) AS row_count,
  SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER()) AS pct
FROM tabs
GROUP BY tab_value
ORDER BY row_count DESC;
```

Use to catch invalid enum values (anything outside `global|daily|weekly`) and data quality drift.

### Template 5: Challenge-Level Engagement

```sql
SELECT
  (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'challenge_id') AS challenge_id,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM `project_id.analytics_property_id.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20260320' AND '20260324'
  AND event_name IN ('leaderboard_tab_changed', 'weekly_leaderboard_control_changed')
GROUP BY challenge_id
HAVING challenge_id IS NOT NULL
ORDER BY events DESC
LIMIT 100;
```

Use to compare challenge-specific leaderboard usage and identify underperforming challenges.

### Template 6: Release Regression Guardrail (Pre vs Post)

```sql
WITH pre AS (
  SELECT COUNT(*) AS c
  FROM `project_id.analytics_property_id.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20260310' AND '20260316'
    AND event_name = 'leaderboard_tab_changed'
),
post AS (
  SELECT COUNT(*) AS c
  FROM `project_id.analytics_property_id.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20260317' AND '20260323'
    AND event_name = 'leaderboard_tab_changed'
)
SELECT
  pre.c AS pre_count,
  post.c AS post_count,
  SAFE_DIVIDE(post.c - pre.c, NULLIF(pre.c, 0)) AS pct_change;
```

Use after app releases to detect sudden telemetry regressions.

### Template 7: Hourly Pattern (UTC)

```sql
SELECT
  TIMESTAMP_TRUNC(TIMESTAMP_MICROS(event_timestamp), HOUR) AS hour_utc,
  event_name,
  COUNT(*) AS event_count
FROM `project_id.analytics_property_id.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20260320' AND '20260324'
  AND event_name LIKE 'leaderboard_%'
GROUP BY hour_utc, event_name
ORDER BY hour_utc, event_name;
```

Use to identify outages, ingestion stalls, and unusual hourly traffic shifts.

### Template 8: Fast Incident Triage Snapshot

```sql
WITH latest_day AS (
  SELECT
    event_name,
    COUNT(*) AS c
  FROM `project_id.analytics_property_id.events_*`
  WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('UTC'), INTERVAL 1 DAY))
    AND event_name LIKE 'leaderboard_%'
  GROUP BY event_name
),
prior_7d_avg AS (
  SELECT
    event_name,
    AVG(c) AS avg_c
  FROM (
    SELECT
      event_name,
      _TABLE_SUFFIX AS d,
      COUNT(*) AS c
    FROM `project_id.analytics_property_id.events_*`
    WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('UTC'), INTERVAL 8 DAY))
      AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('UTC'), INTERVAL 2 DAY))
      AND event_name LIKE 'leaderboard_%'
    GROUP BY event_name, d
  )
  GROUP BY event_name
)
SELECT
  l.event_name,
  l.c AS latest_count,
  p.avg_c AS prior_7d_avg,
  SAFE_DIVIDE(l.c - p.avg_c, NULLIF(p.avg_c, 0)) AS deviation
FROM latest_day l
LEFT JOIN prior_7d_avg p USING (event_name)
ORDER BY ABS(deviation) DESC;
```

Use during incidents to prioritize which events have the largest deviations from baseline.

### Template Maintenance Rules

1. Keep template event names aligned with the Approved Event Registry.
2. If a parameter is deprecated, annotate affected templates in the same PR.
3. Validate every template at least once per month as part of the monthly maintenance cadence.

## Advanced Troubleshooting Runbooks

Use this section for Sev-1/Sev-2 analytics incidents and hard-to-diagnose data quality regressions.

### Incident Severity Triage

| Severity | Trigger | Expected Response | Incident Commander |
|---|---|---|---|
| Sev-1 | Event family at 0 for 60+ minutes in production, or critical KPI dashboard blank during release | 15-minute response, open war room, hourly updates | `@mobile-oncall` |
| Sev-2 | Event volume down >40% vs 7-day baseline for 2+ hours, null-rate >20% on required params | 30-minute response, owner triage + mitigation plan | `@analytics-owner` |
| Sev-3 | Query latency/perf degradation, dashboard staleness, isolated challenge-level anomalies | Same business day triage and backlog fix | `@product-analyst` |

### 15-Minute First Response Protocol

1. Confirm export window first: BigQuery is delayed 1-2 hours, occasionally up to 4 hours.
2. Run Template 8 (Fast Incident Triage Snapshot) from Query Templates Gallery.
3. Compare DebugView vs BigQuery for one impacted event.
4. Check release timeline: did a new app build ship in the affected window?
5. Open incident thread and include: event names, deviation %, impacted dashboards, likely blast radius.

### Decision Tree: Where Is The Break?

1. DebugView missing + BigQuery missing:
   Client instrumentation failure, feature flag off, or app path not executed.
2. DebugView present + BigQuery missing after 2+ hours:
   Schema/type mismatch, invalid parameter names, or quota rejection.
3. BigQuery present + dashboard missing:
   Query bug, stale cache/materialized table lag, or dashboard filter mismatch.
4. BigQuery delayed across many event families:
   Export backlog or upstream Firebase/BigQuery latency.

### Runbook A: Event Volume Drops To Zero

Symptoms:
- One or more critical events show 0 in daily/hourly dashboards.
- Alert fires for deviation below threshold.

Checks:
1. Verify if issue is event-specific or global:

```sql
SELECT
  event_name,
  COUNT(*) AS c
FROM `project_id.analytics_property_id.events_*`
WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('UTC'), INTERVAL 1 DAY))
  AND event_name LIKE 'leaderboard_%'
GROUP BY event_name
ORDER BY c DESC;
```

2. Compare against prior 7 days:

```sql
SELECT
  _TABLE_SUFFIX AS day,
  COUNT(*) AS c
FROM `project_id.analytics_property_id.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('UTC'), INTERVAL 8 DAY))
  AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('UTC'), INTERVAL 1 DAY))
  AND event_name = 'leaderboard_tab_changed'
GROUP BY day
ORDER BY day;
```

Mitigation:
1. If DebugView also shows 0: rollback recent instrumentation change or disable feature path.
2. If only BigQuery shows 0: wait for export window, then escalate to `@analytics-owner` with query evidence.
3. If tied to release: gate rollout until event volume recovers to baseline band.

### Runbook B: Required Parameter Null-Rate Spike

Symptoms:
- `tab` or `is_daily_context` suddenly null in >20% of rows.

Checks:

```sql
WITH e AS (
  SELECT
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'tab') AS tab,
    (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'is_daily_context') AS is_daily_context_int,
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'is_daily_context') AS is_daily_context_str
  FROM `project_id.analytics_property_id.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20260320' AND '20260324'
    AND event_name = 'leaderboard_tab_changed'
)
SELECT
  COUNT(*) AS total,
  SAFE_DIVIDE(COUNTIF(tab IS NULL), COUNT(*)) AS tab_null_rate,
  SAFE_DIVIDE(COUNTIF(is_daily_context_int IS NULL AND is_daily_context_str IS NULL), COUNT(*)) AS context_missing_rate,
  COUNTIF(is_daily_context_int IS NULL AND is_daily_context_str IS NOT NULL) AS context_type_drift_rows
FROM e;
```

Mitigation:
1. Type drift detected: hotfix app to restore canonical type and dual-write if needed.
2. Missing key only on specific app versions: segment by app version and coordinate release fix.
3. Update compatibility matrix and annotate affected templates.

### Runbook C: Duplicate Event Explosion

Symptoms:
- Event count spikes 2x-10x with stable DAU.
- Session-level event frequency appears implausible.

Checks:

```sql
WITH per_session AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id') AS sid,
    COUNT(*) AS c
  FROM `project_id.analytics_property_id.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20260320' AND '20260324'
    AND event_name = 'leaderboard_tab_changed'
  GROUP BY user_pseudo_id, sid
)
SELECT
  APPROX_QUANTILES(c, 100)[OFFSET(50)] AS p50,
  APPROX_QUANTILES(c, 100)[OFFSET(95)] AS p95,
  MAX(c) AS max_c
FROM per_session;
```

Mitigation:
1. Investigate client call site for logging inside render/build paths.
2. Add short debounce guard where user intent is singular.
3. Backfill dashboard metric using distinct session/action if raw counts are inflated.

### Runbook D: Dashboard Broken, Raw Data Healthy

Symptoms:
- BigQuery query returns expected rows, but dashboard tiles are blank or stale.

Checks:
1. Run dashboard query manually in BigQuery and verify output schema.
2. Confirm dashboard filter defaults (date range, environment, event_name).
3. Confirm scheduled query/materialized table refresh timestamps.

Mitigation:
1. If schema changed: patch dashboard query to support both old and new params during migration window.
2. If cached extract stale: force refresh and verify next scheduled run status.
3. If Looker/BI model broke: pin to last-known-good view and file follow-up fix.

### Runbook E: Challenge-Level Data Missing

Symptoms:
- Global leaderboard events present, challenge-scoped reporting empty.

Checks:

```sql
SELECT
  COUNT(*) AS total,
  COUNTIF((SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'challenge_id') IS NOT NULL) AS with_challenge_id,
  SAFE_DIVIDE(
    COUNTIF((SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'challenge_id') IS NOT NULL),
    COUNT(*)
  ) AS challenge_coverage
FROM `project_id.analytics_property_id.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20260320' AND '20260324'
  AND event_name IN ('leaderboard_tab_changed', 'weekly_leaderboard_control_changed');
```

Mitigation:
1. Verify challenge context propagation from UI state to analytics call.
2. Ensure optional param is sent only when scoped; avoid sending empty strings.
3. Add regression test for challenge-scoped leaderboard navigation.

### Runbook F: BigQuery Cost Or Latency Spike

Symptoms:
- Queries exceed expected runtime/cost after schema updates.

Checks:
1. Confirm `_TABLE_SUFFIX` pruning is used in all templates.
2. Detect unnecessary repeated UNNEST and wide SELECT patterns.
3. Compare scan bytes before/after query edits.

Mitigation:
1. Add partition/date filters first, then event filters.
2. Materialize daily aggregates for high-frequency dashboards.
3. Replace repeated scalar subqueries with one UNNEST + conditional aggregation when feasible.

### Escalation And Handoff Template

Use this message in `#analytics-alerts` or incident channels:

```text
[Analytics Incident] Severity: Sev-2
Detected: 2026-03-24 18:10 UTC
Events Impacted: leaderboard_tab_changed, weekly_leaderboard_control_changed
Deviation: -53% vs 7-day baseline
Null-Rate: tab=2%, is_daily_context=41%
DebugView Status: present
BigQuery Status: present with type drift
Suspected Cause: recent app build logs is_daily_context as string
Owner: @analytics-owner
Next Update: 30 minutes
```

### Post-Incident Checklist

1. Add incident summary to Quarterly Audit Report template section 6.
2. Update threshold/alert if sensitivity was too high or too low.
3. Add or update template query that would have shortened detection time.
4. Record concrete prevention action in Monthly Maintenance Cadence.

## Performance Tuning Guide

Use this guide to keep analytics queries fast, cost-efficient, and stable as data volume grows.

### Performance Targets

| Workload | Target Runtime | Target Scan Size | Refresh Cadence |
|---|---|---|---|
| Daily dashboard tiles | < 10 seconds | < 2 GB/query | Hourly or daily |
| Incident triage queries | < 30 seconds | < 10 GB/query | On-demand |
| Weekly product deep dives | < 2 minutes | < 50 GB/query | Weekly |
| Quarterly audit workloads | < 5 minutes | < 150 GB/query | Quarterly |

If a query exceeds two thresholds in a row, optimize before adding new features to it.

### Core Optimization Principles

1. Prune data early with `_TABLE_SUFFIX` before heavy joins or UNNEST.
2. Filter by event family before extracting parameters.
3. Select only required columns; avoid `SELECT *` in production dashboards.
4. Prefer pre-aggregated tables for repeated dashboard access.
5. Use UTC defaults and convert timezone only in final presentation layers.

### Query Shape Patterns

#### Pattern A: Fast Path (Preferred)

```sql
SELECT
  event_name,
  COUNT(*) AS c
FROM `project_id.analytics_property_id.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20260320' AND '20260324'
  AND event_name LIKE 'leaderboard_%'
GROUP BY event_name;
```

Why it performs well:
1. Date pruning limits scanned partitions.
2. Event filter reduces row set before aggregation.
3. No repeated parameter extraction.

#### Pattern B: Slow Path (Avoid)

```sql
SELECT *
FROM `project_id.analytics_property_id.events_*`
WHERE event_name LIKE '%leaderboard%';
```

Why it is expensive:
1. No table suffix pruning means scanning broad date ranges.
2. Wide projection (`*`) reads unnecessary fields.
3. Wildcard with leading `%` can prevent efficient pruning behavior.

### Parameter Extraction Optimization

Use one UNNEST pass with conditional aggregation for multi-parameter use cases.

Preferred:

```sql
WITH flat AS (
  SELECT
    event_timestamp,
    user_pseudo_id,
    event_name,
    ep.key,
    ep.value
  FROM `project_id.analytics_property_id.events_*`,
  UNNEST(event_params) ep
  WHERE _TABLE_SUFFIX BETWEEN '20260320' AND '20260324'
    AND event_name = 'leaderboard_tab_changed'
)
SELECT
  user_pseudo_id,
  MAX(IF(key = 'tab', value.string_value, NULL)) AS tab,
  MAX(IF(key = 'challenge_id', value.string_value, NULL)) AS challenge_id,
  MAX(IF(key = 'is_daily_context', CAST(value.int_value AS STRING), NULL)) AS is_daily_context
FROM flat
GROUP BY user_pseudo_id;
```

Avoid repeated scalar subqueries if extracting many keys from the same event.

### Cost Control Checklist

- [ ] `_TABLE_SUFFIX` is always present for wildcard tables.
- [ ] Query scans only required date range (default last 7 days for triage).
- [ ] Event filter included before UNNEST when possible.
- [ ] Projection excludes high-volume nested columns not in use.
- [ ] Dashboard SQL avoids duplicate heavy CTEs.
- [ ] Query result cache is enabled where safe.

### Dashboard Latency Reduction

1. Precompute daily aggregates for top tiles:
   - `analytics_daily_event_volume`
   - `analytics_daily_null_rate`
   - `analytics_daily_challenge_reach`
2. Refresh aggregate tables with scheduled queries once per hour for near-real-time dashboards.
3. Keep dashboard queries as thin reads over aggregate tables (no raw wildcard scans at render time).

Example scheduled aggregate:

```sql
CREATE OR REPLACE TABLE `project_id.analytics_marts.daily_leaderboard_metrics` AS
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS day,
  event_name,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `project_id.analytics_property_id.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('UTC'), INTERVAL 30 DAY))
  AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('UTC'), INTERVAL 1 DAY))
  AND event_name LIKE 'leaderboard_%'
GROUP BY day, event_name;
```

### Partitioning And Clustering Guidance

For derived marts/tables:
1. Partition by day/date for predictable pruning.
2. Cluster by high-frequency filter columns:
   - `event_name`
   - `user_pseudo_id`
   - `challenge_id` (if used often)
3. Revisit clustering keys quarterly as query patterns evolve.

### Query Review Rubric (Before Merge)

| Check | Pass Criteria |
|---|---|
| Date pruning | Uses `_TABLE_SUFFIX` or partition date filter |
| Event filtering | Limits to specific event names/families |
| Projection hygiene | No `SELECT *` in production query paths |
| Parameter extraction | Single-pass UNNEST for multi-parameter use |
| Runtime | Meets workload target for intended use |
| Scan cost | Within target scan size for workload class |

### Common Performance Anti-Patterns

1. Wide wildcard scans across months for dashboard tiles.
2. Repeating the same expensive CTE in multiple chart queries.
3. Converting timezones inside all intermediate CTEs.
4. Joining raw event tables directly to multiple dimensional tables in BI layer.
5. Using non-sargable filters (`LIKE '%value%'`) on high-cardinality fields.

### Incident Tuning Playbook

When query runtime regresses suddenly:
1. Compare execution details for last-known-good query vs current query.
2. Reduce date window to isolate whether regression is volume-driven or shape-driven.
3. Replace repeated scalar subqueries with flattened UNNEST.
4. Materialize heavy intermediate result for incident window.
5. Backport optimized query to dashboard and document change in audit report.

### Monthly Performance Maintenance

- [ ] Review top 10 most expensive analytics queries by scan bytes.
- [ ] Identify dashboards still reading raw wildcard tables and migrate them to marts.
- [ ] Drop unused derived tables and stale scheduled queries.
- [ ] Validate scheduled aggregate freshness SLAs.
- [ ] Update this guide with newly observed anti-patterns.

### SLA Escalation Thresholds

Escalate to `@analytics-owner` and `@product-analyst` if any condition persists for 24 hours:
1. Dashboard median runtime > 20 seconds.
2. Incident triage query runtime > 90 seconds.
3. Query cost increases > 50% week-over-week without volume growth.
4. Scheduled aggregate freshness lag > 2 refresh cycles.

## Future Enhancements

- **Custom Dashboards**: Real-time analytics views
- **Funnel Analysis**: User progression tracking
- **Revenue Analytics**: Advanced monetization metrics
- **A/B Testing**: Experiment framework integration
- **Cohort Analysis**: User segmentation and retention

## Ownership Contacts Appendix

Use role aliases instead of personal names so the document remains stable across team changes.

| Role Alias | Scope | Primary Channel | Escalation Channel | Typical Response SLA |
|------------|-------|-----------------|--------------------|----------------------|
| `@analytics-owner` | Analytics schema governance, compatibility approvals | `#analytics-alerts` | `#eng-oncall` | 1 business day |
| `@mobile-oncall` | Runtime instrumentation regressions in mobile app | `#eng-oncall` | `#incident-war-room` | 30 minutes (active incident) |
| `@game-feature-owner` | Daily/weekly challenge flow attribution and UX signal integrity | `#gameplay-dev` | `#analytics-alerts` | 4 business hours |
| `@product-analyst` | Dashboard interpretation, KPI drift triage | `#product-analytics` | `#analytics-alerts` | 1 business day |
| `@release-manager` | Release go/no-go decisions for analytics-impacting changes | `#release-coordination` | `#eng-oncall` | Same day |

### Contact Usage Rules
1. Mention both primary and backup role aliases for Sev-1/Sev-2 analytics incidents.
2. For dashboard breakages, include the affected query number from the Query Compatibility Matrix.
3. For schema changes, notify `@analytics-owner` before removing deprecated events/parameters.

## Monthly Analytics Maintenance Cadence

Run this checklist once per month to keep analytics instrumentation and reporting healthy.

### Schema Hygiene
- [ ] Review Analytics Schema Changelog entries from the past month.
- [ ] Confirm deprecated events/parameters still in dual-write window or eligible for retirement.
- [ ] Verify Approved Event Registry status flags (`Active` / `Deprecated`) are current.

### Data Quality
- [ ] Review null-rate trends for segmentation-critical parameters (`is_daily_context`, `challenge_id`).
- [ ] Check type consistency in BigQuery for shared parameters (`tab`, `control`, `value`, `week_id`).
- [ ] Validate that event volumes do not show unexplained discontinuities after releases.

### Query and Dashboard Health
- [ ] Re-run all cookbook queries and compare against prior-month baseline.
- [ ] Remove or fix stale dashboard tiles that rely on deprecated schema.
- [ ] Confirm Dashboard Ownership Map still reflects active report names and owners.

### Alerting and Operations
- [ ] Review false-positive and false-negative rates for operational thresholds.
- [ ] Tune warning/critical thresholds where needed and document rationale.
- [ ] Confirm runbook links and escalation channels are still valid.

### Governance and Communication
- [ ] Share a monthly analytics health summary in the analytics channel.
- [ ] Capture follow-up actions with owners and target dates.
- [ ] Update this cadence checklist if recurring maintenance gaps are observed.

## Quarterly Analytics Audit Report Template

Use this template to produce a quarterly audit artifact for analytics reliability and decision quality.

### Report Metadata
- Quarter:
- Prepared by:
- Review date:
- Stakeholders:

### 1) Executive Summary
- Overall analytics health (Green / Yellow / Red):
- Top 3 risks identified:
- Top 3 improvements delivered:

### 2) Schema and Instrumentation Review
- Events added this quarter:
- Events deprecated this quarter:
- Events pending retirement:
- Parameter contract violations observed (if any):

### 3) Data Quality Findings
- Null-rate trends for critical params (`is_daily_context`, `challenge_id`):
- Type consistency issues discovered:
- Missing/duplicate event anomalies:

### 4) Query and Dashboard Reliability
- Cookbook query pass/fail summary:
- Dashboard breakages or stale tiles resolved:
- Compatibility matrix gaps identified:

### 5) Incident and Alert Analysis
- Alert volume by category:
- False positive / false negative notes:
- Mean time to detect (MTTD):
- Mean time to resolve (MTTR):

### 6) Governance and Process Compliance
- PR template compliance rate:
- Reviewer checklist adherence:
- Deprecation policy compliance status:

### 7) Action Plan (Next Quarter)
| Priority | Action | Owner Alias | Target Date | Success Metric |
|----------|--------|-------------|-------------|----------------|
| P0 | | | | |
| P1 | | | | |
| P2 | | | | |

### 8) Sign-Off
- `@analytics-owner`:
- `@mobile-oncall`:
- `@product-analyst`:
- `@release-manager`:

---

**Last Updated**: March 2026
**Analytics Version**: 1.1
**Firebase Analytics SDK**: 10.4.0
