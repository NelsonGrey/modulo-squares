# Game Mechanics

**Updated**: 2026-07-20
**Live mode**: falling divisor buckets

## Objective

Guide each falling number into a bucket that divides it evenly. Successful landings add score and fill the progress grid. Misses remove score/progress. Fill all 100 progress squares to advance a level.

The live entry point is `packages/mobile/lib/features/game/game_screen.dart`, which renders `FallingModuloGameScreen`. The rules are implemented in `models/falling_modulo_game_engine.dart`.

## Board and controls

- Ten horizontal lanes.
- Nine scoring buckets numbered `1` through `9` and one dead bucket numbered `0`.
- Bucket order is reshuffled at game start and after every level-up.
- A tile spawns in the center lane and falls automatically.
- Players move left or right using touch controls.
- Each new tile waits 500 ms before falling.
- Horizontal input has a 180 ms base cooldown. Combos shorten it to a minimum of 80 ms.
- Gameplay starts paused behind a Start Game overlay and can be paused from the UI.

## Resolution rules

For falling value `F` and bucket `B`:

| Landing | Condition | Score change | Progress change | Combo |
|---|---|---|---|---|
| Clean division | `B > 0` and `F % B == 0` | `F * B` | `+1` | `+1` |
| Bucket 1 | `B == 1` | `0` | `+1` | `+1` |
| Remainder | `B > 0` and `F % B != 0` | `-(F * B * remainder)` | `-remainder` | reset to `0` |
| Dead bucket | `B == 0` | `-F` | `-1` | reset to `0` |

Score never falls below zero. Negative progress is tracked as deficit and must be recovered before the visible grid fills again.

## Combo movement bonus

| Combo | Horizontal speed multiplier |
|---|---|
| `0-2` | `1.00x` |
| `3-4` | `1.10x` |
| `5-7` | `1.20x` |
| `8+` | `1.30x` |

## Level scaling

- Progress target: 100 filled squares for every level.
- Number range at level `L`: minimum `5 + L`, maximum `15 + 3L`.
- Drop interval: `floor(6000 * 0.96^(L-1))` milliseconds.
- Minimum drop interval: 1200 ms.
- The engine also reports a legacy target-tile value `12 + 2*(L-1)`, but level completion is currently driven by the 100-square fill balance.

There is no fixed maximum level in the active engine.

## Visual cues and persistence

When visual cues are enabled, buckets that evenly divide the current value are highlighted. The preference is stored in SharedPreferences as `fallingMode.visualCuesEnabled`.

The local high score is stored as `fallingMode.highScore`. A new run resets the current run but not the saved high score.

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

`GameBoard`, `GameProvider`, old grid widgets, and `InstructionsScreen` implement an earlier tile-moving mode with obstacles, bonus tiles, daily boards, moves, and mercy spawns. Those classes still have extensive tests, but `GameScreen` no longer routes players to that mode. Do not use legacy rules for store copy or current gameplay documentation.

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
