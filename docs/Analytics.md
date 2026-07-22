# Analytics

**Updated**: 2026-07-20

Modulo Squares has two analytics surfaces:

- Mobile: Firebase Analytics through `AnalyticsService`.
- Website: Google Tag Manager loading GA4 under Consent Mode.

Firebase Analytics is not initialized by the React site.

## Mobile events currently implemented

| Event | Parameters |
|---|---|
| `is_anonymous` user property | authentication state |
| `app_open` | Firebase built-in event |
| `view_instructions` | none |
| `view_leaderboard` | none |
| `restart` | `level` |
| `level_start` | level/mode parameters |
| `level_complete` | level/score parameters |
| `out_of_moves` | level/moves/score parameters |
| `game_over_no_moves` | `score` |
| `move` | `type` |
| `view_special_tiles` | none |
| `mercy_spawn` | `penalty` |
| `ad_impression` | optional trigger/level |
| `ad_dismissed` | optional trigger/level |
| `daily_start` | daily challenge parameters |
| `daily_submit` | challenge/score/rank context |
| `daily_rank_available` | rank context |
| `weekly_submit` | week/score context |
| `weekly_rank_available` | week/rank context |
| `weekly_badge_earned` | week/badge/rank context |
| `level_retry` | level/attempt context |
| `level_fail_reason` | level/reason context |
| `level_star_result` | level/star context |

Several events originated in the legacy board mode and may not fire during current falling gameplay. Before using a funnel, verify the event's live call site rather than assuming its presence in `AnalyticsService` means it is emitted.

## Website analytics

`packages/web/index.html` initializes Consent Mode with analytics/ad storage denied, restores prior consent from `ms_consent_v1`, and then loads GTM container `GTM-TR4PP272`.

The repository cannot verify which GA4 tags, conversions, audiences, or destinations are configured inside GTM. Validate them in Tag Assistant/GTM Preview and GA4 DebugView.

## Consent rules

- Mobile: ATT and Google UMP are coordinated by `ConsentService`; ads are personalized only when the relevant consent state allows it.
- Web: analytics and ad storage remain denied until the visitor accepts all cookies.
- Policy pages must match the implemented consent and vendor behavior.

## Recommended current funnel

Because the live product is falling mode, use a focused funnel:

1. login/auth success;
2. gamertag completion;
3. start game;
4. first successful division;
5. first level completion;
6. leaderboard view/submission;
7. Remove Ads product view/purchase/restore.

Some of these events are not currently explicit. Add them before treating the funnel as measurable, and document exact names/parameters here.

## Validation checklist

- Confirm Firebase Analytics collection on a debug device.
- Confirm no sensitive fields, email, raw UID, receipt, or free-form gamertag is logged as an event parameter.
- Confirm GTM remains denied before consent and updates after a choice.
- Confirm GA4 receives SPA route changes, not just first load.
- Confirm AdSense behavior and policy disclosures match consent.
- Record dashboard/console verification dates in the go-live runbook.
