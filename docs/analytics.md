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
