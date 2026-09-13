# Game Mechanics

**Updated**: 2026-09-12
**Live mode**: falling divisor buckets

## Objective

Guide each falling number into a bucket that divides it evenly. Successful landings add score and fill the progress grid. Misses remove score/progress. Fill all 100 progress squares to advance a level. Landing in the *highest*-value bucket that evenly divides the falling number — rather than just any valid one — earns a bonus, on top of the normal fill-any-valid-bucket pacing.

The live entry point is `packages/mobile/lib/features/game/game_screen.dart`, which renders `FallingModuloGameScreen`. The rules are implemented in `models/falling_modulo_game_engine.dart`.

## Board and controls

- Ten horizontal lanes.
- Nine scoring buckets numbered `1` through `9` and one dead bucket, shown as a plain "no entry" icon with no number.
- Bucket order is reshuffled at game start and after every level-up.
- A tile spawns in the center lane and falls automatically.
- Players move left or right using touch controls.
- Each new tile waits 500 ms before falling.
- Horizontal input has a 180 ms base cooldown. Combos shorten it to a minimum of 80 ms.
- Gameplay starts paused behind a Start Game overlay and can be paused from the UI.

## Resolution rules

For falling value `F` and bucket `B`, with `H` the highest bucket value (1-9) that evenly divides `F` (`FallingModuloGameEngine.highestDivisorFor`):

| Landing | Condition | Score change | Progress change | Combo |
|---|---|---|---|---|
| Highest divisor | `B > 0`, `F % B == 0`, `B == H`, `H != 1` | `2 * (F * B)` | `+2` | `+1` |
| Highest divisor is 1 | `B == 1 == H` (F is coprime to every other bucket) | `F` (flat bonus, since the base delta for bucket 1 is always `0`) | `+2` | `+1` |
| Clean division (not highest) | `B > 0`, `F % B == 0`, `B != H` | `F * B` | `+1` | `+1` |
| Bucket 1 (not highest) | `B == 1`, `H != 1` | `0` | `+1` | `+1` |
| Remainder | `B > 0` and `F % B != 0` | `-(F * B * remainder)` | `-remainder` | reset to `0` |
| Dead bucket | `B == 0` | `-F` | `-1` | reset to `0` |

Score never falls below zero. Negative progress is tracked as deficit and must be recovered before the visible grid fills again. Buckets carry no advance indication of which are valid or which is highest — the player has to work out the divisibility themselves before dropping. A successful highest-bucket landing is only revealed after the fact, via a distinct gold starburst "★ BONUS!" burst in place of the plain score burst.

## Combo movement bonus

| Combo | Horizontal speed multiplier |
|---|---|
| `0-2` | `1.00x` |
| `3-4` | `1.10x` |
| `5-7` | `1.20x` |
| `8+` | `1.30x` |

## Level scaling

- Progress target: 100 filled squares for every level (a highest-divisor bonus landing counts as 2 toward this).
- Number range at level `L`: minimum `max(10, 5 + L)`, maximum `15 + 3L`. Floored at 10 so the falling number is always a genuine multi-step division problem, never a single digit (the unfloored `5 + L` only matters again from level 5 on, where it already exceeds 10).
- Drop interval: `floor(base * 0.96^(L-1))`, floored at a per-difficulty minimum — see Difficulty below.
- The engine also reports a legacy target-tile value `12 + 2*(L-1)`, but level completion is currently driven by the 100-square fill balance.

There is no fixed maximum level in the active engine.

## Difficulty

`GameDifficulty` (`easy`/`normal`/`hard`) selects the falling tile's speed curve, chosen in Settings → Gameplay and persisted as `fallingMode.difficulty`. All three tiers share the same `0.96` per-level decay; only the starting speed and floor differ, both drawn from the single already-tuned envelope below (`FallingModuloGameEngine.dropIntervalForLevel`):

| Difficulty | Base (level 1) | Floor |
|---|---|---|
| Easy | 6000 ms | 2600 ms |
| Normal (default) | 6000 ms | 1200 ms |
| Hard | 4200 ms | 1200 ms |

Normal reproduces the original single curve exactly. Easy and Hard are deliberately overlapping sub-ranges of it — Easy shares Normal's start and only diverges once Normal drops below Easy's floor (~level 21); Hard starts faster than Normal but converges with Normal's floor by ~level 32, well before Normal reaches it (~level 40). Changing difficulty in Settings takes effect immediately, recomputing the current level's drop interval — it does not wait for a new run.

## Persistence

The local high score is stored as `fallingMode.highScore`. A new run resets the current run but not the saved high score.

There was previously a "Visual Cues" toggle that highlighted every evenly-dividing bucket (and, briefly, the highest one specifically) before the player dropped. It was removed (2026-09-12): pre-drop hinting undercuts the game's core skill of working out the best divisor yourself, so buckets now carry no advance indication at all — feedback (the bonus starburst) only appears after a successful drop.

## Ads and purchases

Interstitial ads can appear at configured transitions such as gamertag completion and level completion. They do not interrupt an actively falling tile. The non-consumable `remove_ads` product disables ads after server validation; Settings also provides Restore Purchases.

The code contains a `premium` product path, but premium content is not part of the currently documented live feature set.

## Accounts and leaderboards

Players authenticate and choose a unique gamertag before native gameplay. The repository contains score submission contracts for global, daily, and weekly leaderboards, and the website exposes global/current-week reads. The current `FallingModuloGameScreen` does not call `LeaderboardService` or navigate to a leaderboard, so falling runs are not presently documented as submitted scores.

Weekly badges are assigned by rank:

| Rank | Badge |
|---|---|
| 1 | Legend |
| 2-3 | Diamond |
| 4-10 | Gold |
| 11-25 | Silver |
| 26-50 | Bronze |
| 51+ | Contender |

## Legacy board-clearing mode

`GameBoard`, `GameProvider`, old grid widgets, and `InstructionsScreen` implemented an earlier tile-moving mode with obstacles, bonus tiles, daily boards, moves, and mercy spawns. `GameScreen` never routed players to that mode, and the confirmed-dead classes and their tests were removed (2026-09-11). Do not use legacy rules for store copy or current gameplay documentation.

## Verification

Primary tests:

- `test/models/falling_modulo_game_engine_test.dart`
- `test/features/falling_modulo_game_screen_test.dart`
- `test/features/game_screen_test.dart`
- `test/integration/game_screen_integration_test.dart`

Run:

```bash
cd packages/mobile
flutter test test/models/falling_modulo_game_engine_test.dart
flutter test test/features/falling_modulo_game_screen_test.dart
```
