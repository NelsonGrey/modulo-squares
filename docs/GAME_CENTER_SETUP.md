# Game Center Setup (App Store Connect)

The app reports to Game Center by **ID**; nothing is auto-created. These
records must exist in App Store Connect with exactly these IDs
(`packages/mobile/lib/gamecenter/game_center_ids.dart`) before a build that
uses them ships. Mirrors `intercept-echo/docs/STORE_SETUP.md`.

App Store Connect → app `com.modulosquares.app.ios` → Features → Game Center →
enable Game Center, then create:

## Leaderboard

| Field | Value |
| --- | --- |
| Type | Classic |
| ID | `modulo_squares_high_score` |
| Reference name | High Score |
| Score format | Integer |
| Sort | High to low |
| Score range | 0 – 100000000 |

The app submits the player's best score at natural breakpoints (level
complete, new run, leaving the screen, backgrounding, and on first connect).
Game Center keeps only the best score per player, so resubmitting is harmless.

## Achievements

Fifteen achievements, 335 points total (Game Center allows 100 achievements
and 1,000 points). The rules live in
`packages/mobile/lib/gamecenter/achievement_tracker.dart` and are unit-tested;
the IDs are in `game_center_ids.dart`. Each needs a title, a pre-earned and an
earned description, a 512x512 image and the point value. All are visible (not
hidden) and none are repeatable.

| ID | Title | Description | Pts |
| --- | --- | --- | --- |
| `modulo_squares_first_clean` | Clean Division | Land a number in a bucket that divides it evenly. | 5 |
| `modulo_squares_first_bonus` | Top Bucket | Land a number in the highest dividing bucket for a bonus. | 10 |
| `modulo_squares_lucky_seven` | Lucky Seven | Land a number cleanly in the 7 bucket. | 10 |
| `modulo_squares_first_level` | Level Up | Complete level 1. | 5 |
| `modulo_squares_level_5` | Rising | Reach level 5. | 10 |
| `modulo_squares_level_10` | Veteran | Reach level 10. | 25 |
| `modulo_squares_level_20` | Modulo Master | Reach level 20. | 50 |
| `modulo_squares_score_1000` | Four Digits | Score 1,000 points in a single run. | 10 |
| `modulo_squares_score_5000` | High Roller | Score 5,000 points in a single run. | 25 |
| `modulo_squares_score_25000` | Grand Total | Score 25,000 points in a single run. | 50 |
| `modulo_squares_combo_5` | On a Roll | Chain 5 clean landings in a row. | 10 |
| `modulo_squares_combo_10` | Hot Streak | Chain 10 clean landings in a row. | 25 |
| `modulo_squares_combo_25` | Unstoppable | Chain 25 clean landings in a row. | 50 |
| `modulo_squares_perfect_level` | Flawless | Complete a level without a single miss. | 25 |
| `modulo_squares_hard_level_5` | Hard Mode | Reach level 5 on Hard difficulty. | 25 |

Notes:
- "Reach level N" and score achievements apply within a run; a new run does
  not re-earn them, and earning one is permanent.
- Achievements earned while the player is not connected to Game Center are
  remembered on the device and granted the next time they connect.
- All are one-shot; none use percent-complete (incremental) progress.
- Art is not in the repo yet: 15 icons at 512x512 are still needed.

## Entitlement

`ios/Runner/Runner.entitlements` already carries
`com.apple.developer.game-center`. (Sign in with Apple was removed: the game
no longer has accounts.)

## Behaviour to verify on a real device (TestFlight)

Signed into a Game Center account in iOS Settings:

1. First launch shows "Connect to Game Center?". **Connect** signs in;
   **Not now** is remembered and the game stays fully playable.
2. Leaderboard button (app bar) opens Game Center's native board; a score
   posted from the previous run appears.
3. Settings → Game Center shows the player's alias, Leaderboard and
   Achievements shortcuts, and Disconnect.
4. Completing level 1 pops the "Level Up" banner, and a first clean landing pops "Clean Division".
5. With no Game Center account on the device, the leaderboard button shows
   "Game Center is unavailable..." and play is unaffected.
6. Reviewers can play the whole game without connecting.
