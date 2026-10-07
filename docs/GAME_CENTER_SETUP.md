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

| ID | Name | Earned when |
| --- | --- | --- |
| `modulo_squares_first_level` | First Level | Complete level 1 (reach level 2) |
| `modulo_squares_level_5` | Level 5 | Reach level 5 |
| `modulo_squares_level_10` | Level 10 | Reach level 10 |
| `modulo_squares_score_1000` | 1,000 Points | Score 1,000 in a run |
| `modulo_squares_score_5000` | 5,000 Points | Score 5,000 in a run |

Each needs a title, pre-earned and earned descriptions, a 512x512 image, and a
point value (keep the total at or under the 1000-point cap).

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
4. Cracking level 2 pops the "First Level" banner.
5. With no Game Center account on the device, the leaderboard button shows
   "Game Center is unavailable..." and play is unaffected.
6. Reviewers can play the whole game without connecting.
