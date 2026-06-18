# iOS-First Gameplay Refocus Plan

Version: 1.0  
Date: 2026-03-07  
Scope: iOS gameplay quality and retention only (Android release path deferred)

## Objective
Refocus development on making Modulo Squares a challenging and rewarding puzzle game on iOS, while keeping current CI/TestFlight automation in maintenance mode.

## Current Constraints
- Android promotion and ecosystem testing are currently unavailable.
- iOS is the only active distribution target.
- Existing release automation should be treated as stable infrastructure, not a feature investment area.

## Immediate Decisions
- Product focus: gameplay depth, progression clarity, and retention loops.
- Platform focus: iOS only for active delivery, tuning, and test cohorts.
- Engineering focus: game systems first, DevOps only for break/fix.

## What Was Fixed Now
- End-state game flow now surfaces in UI:
  - Level complete shows a modal and advances with `completeLevel()`.
  - Game over shows a modal and restarts with ad-gated restart.
- Core puzzle rules are now deterministic and bounded:
  - Fixed 4x4 board for all levels.
  - Collision resolves to `target % source` with no value inflation.
  - Source tile clears after collision (no random respawn).
  - Curated level presets added for levels 1-5.
- Replay reward groundwork is now live:
  - Star rating calculated on level completion.
  - Best stars and best score persisted per level.
  - Level-complete dialog shows stars and personal best summary.
- Daily challenge foundation is now live:
  - Daily challenge mode can be started/exited from the game screen.
  - Puzzle generation is deterministic per day via seeded board factory.
  - Daily leaderboard service APIs are available in separate Firestore buckets.
  - Daily scores are submitted on challenge completion and the leaderboard button opens daily rankings while in daily mode.
  - Daily completion now shows immediate submission feedback with rank preview when available.
  - Daily analytics funnel events are now emitted:
    - `daily_start`
    - `daily_submit`
    - `daily_rank_available`
- Level diagnostics analytics are now emitted:
  - `level_retry`
  - `level_fail_reason`
  - `level_star_result`
- Files updated:
  - `packages/mobile/lib/features/game/game_screen.dart`
  - `packages/mobile/lib/shared/models/game_board.dart`
  - `packages/mobile/lib/features/game/providers/game_provider.dart`
  - `packages/mobile/lib/core/services/leaderboard_service.dart`

## Priority Backlog

### P0: Core Challenge Loop (1-2 weeks)
1. Stabilize puzzle identity.
- Choose one ruleset and enforce it consistently in docs and code.
- Candidate: deterministic modulo puzzle loop with predictable value transitions.

2. Replace accidental complexity with intentional difficulty.
- Revisit formula in `packages/mobile/lib/shared/models/game_board.dart`:
  - Current non-zero transform `(target + source) * remainder` can create value spikes.
- Cap or normalize value growth so planning remains human-solvable.

3. Introduce curated level sets.
- Add level definitions (seeded or explicit) instead of fully random progression.
- Suggested file targets:
  - `packages/mobile/lib/features/game/models/level_definition.dart`
  - `packages/mobile/lib/features/game/data/level_catalog.dart`

4. Keep iOS build path green only.
- Required checks:
  - `flutter test` in `packages/mobile`
  - iOS debug build
  - TestFlight internal deploy smoke test

Acceptance criteria:
- First 15 levels have intentional difficulty ramp.
- No major progression dead-ends from randomness.
- Median solve time for levels 1-5 is between 1 and 3 minutes.

### P1: Rewarding Progression (2-3 weeks)
1. Add performance-based rewards.
- Star ratings per level (moves used, clear efficiency, mercy usage).
- Persistent best result per level for replay motivation.

2. Add one daily challenge mode.
- One seeded puzzle per day.
- Separate daily leaderboard bucket.

3. Improve post-level feedback.
- Show summary panel: score delta, star result, best comparison.

Suggested file targets:
- `packages/mobile/lib/features/game/providers/game_provider.dart`
- `packages/mobile/lib/features/game/widgets/game_dialogs.dart`
- `packages/mobile/lib/core/services/leaderboard_service.dart`

Acceptance criteria:
- Daily challenge is playable and results are submitted.
- At least one replay incentive exists for each completed level.

### P2: Monetization Alignment (after retention signal)
1. Keep interstitials low-friction.
- Show after meaningful milestones, not during high-cognitive flow moments.

2. Add rewarded ads only for optional benefits.
- Example: optional retry token, optional hint, optional daily bonus.

3. Delay premium expansion.
- Defer premium pass and advanced monetization until retention baseline is verified.

Acceptance criteria:
- Ad placements do not block progression.
- Optional rewards increase session continuation rate.

## iOS-First Working Agreement
- Every gameplay change is validated on iOS simulator and at least one real iOS test device before release candidate.
- Every sprint includes one internal TestFlight build for qualitative feedback.
- Android-specific work is backlog-only until ecosystem access is restored.

## Metrics To Track Weekly
1. Level completion funnel (L1 -> L5 -> L10).
2. Retry rate by level.
3. Mercy spawn frequency.
4. Session length.
5. D1 and D7 retention for iOS cohorts.

## Suggested Next Implementation Slice
1. Add a dedicated level catalog and swap procedural progression to level-driven tuning.
2. Add a dedicated daily leaderboard screen/filter with richer rank context and empty/error states.
3. Resolve localization key drift in `instructions_screen.dart` so broader widget/integration test suites can run green.

## Out Of Scope For This Refocus
- New Android release steps.
- Additional runner/certificate automation unless a production blocker appears.
- New monetization products beyond ad removal and optional rewarded actions.
