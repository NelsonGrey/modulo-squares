# Achievements & Rewards Design

**Updated**: 2026-07-22
**Status**: Design only — not yet implemented
**Owner**: Mark Nelson

## Definitions

**Achievement** — a named, discrete accomplishment tied to a specific condition. Either binary (earned/not earned) or a tiered track crossed by a numeric threshold. An achievement is a rule, not a payoff.

**Reward** — the payoff granted when an achievement (or a tier of one) is earned: a badge, a cosmetic, a title, a flair. Every reward traces back to an achievement trigger; not every achievement needs a tangible reward beyond recognition.

Keeping the two separate matters for implementation: achievement definitions are static data (id, condition, threshold), and reward-granting is a separate system that reacts to an "achievement unlocked" event.

## Category structure

Mirrors the setup-vs-usage split already familiar from other Circus projects: getting a player properly configured to play, versus actually playing well. A third category covers accomplishments that can only be earned relative to other players.

| Category | Question it answers | Skill-based | Repeatable |
|---|---|---|---|
| Foundation | Is the player set up to succeed? | No | No (one-time) |
| Mastery | Is the player getting good at the game? | Yes | Yes (tiered) |
| Competitive | How does the player stand against others? | Yes | Yes (seasonal) |

## Foundation achievements (setup/onboarding)

One-time, flat, non-tiered. Each fires once, on first occurrence.

| Achievement | Trigger |
|---|---|
| Welcome Aboard | Account created and gamertag chosen |
| Rules Read | Instructions/rules screen viewed |
| Dialed In | Visual Cues enabled at least once |
| Signed & Sealed | Apple or Google sign-in linked (vs. staying anonymous/email-only) |
| Unlocked Premium | Ad-removal purchase completed |
| Restored | Restore Purchases used successfully |

## Mastery achievements (gameplay/performance)

Tiered tracks, skill-based, repeatable. Tier ladder for all Mastery tracks:

| Tier | Name |
|---|---|
| 1 | Factor |
| 2 | Multiple |
| 3 | Prime |
| 4 | Perfect |
| 5 | Modulo |

"Perfect" references perfect numbers (a number equal to the sum of its own divisors — 6, 28, 496...), fitting for a divisibility game. The top tier, **Modulo**, doubles as a brand callback — a player's best rank is literally the game's own name.

### Tracks and thresholds (draft — tune after playtesting)

**Score Chase** — best single-run score
| Factor | Multiple | Prime | Perfect | Modulo |
|---|---|---|---|---|
| 1,000 | 5,000 | 20,000 | 50,000 | 100,000+ |

**Combo Master** — highest combo reached in a run
| Factor | Multiple | Prime | Perfect | Modulo |
|---|---|---|---|---|
| 5 | 8 | 12 | 20 | 30+ |

**Level Climber** — highest level reached
| Factor | Multiple | Prime | Perfect | Modulo |
|---|---|---|---|---|
| 5 | 10 | 20 | 35 | 50+ |

**Precision** — clean-division ratio in a single run (minimum run length applies, e.g. 50+ landings, to prevent trivial short-run qualification)
| Factor | Multiple | Prime | Perfect | Modulo |
|---|---|---|---|---|
| 80% | 90% | 95% | 98% | 100% (no-miss run) |

**Survivor** — squares filled in a single run (endurance)
| Factor | Multiple | Prime | Perfect | Modulo |
|---|---|---|---|---|
| 100 | 300 | 750 | 1,500 | 3,000+ |

**Grinder** — lifetime cumulative squares filled across all runs
| Factor | Multiple | Prime | Perfect | Modulo |
|---|---|---|---|---|
| 500 | 2,500 | 10,000 | 50,000 | 250,000+ |

## Competitive achievements (collective)

Earned only relative to other players. Builds on the existing weekly rank-badge system in `leaderboard_service.dart` (`Bronze → Diamond → Legend`) — that naming stays as-is; it already means something to anyone who has seen the weekly leaderboard, and using a different naming scheme here (math vocabulary is reserved for Mastery) keeps the two badge families visually distinct.

| Achievement | Trigger |
|---|---|
| Weekly Bronze/Silver/Gold/Diamond/Legend | Existing weekly rank badge, promoted to a first-class achievement with its own reward |
| Most Improved | Best week-over-week rank improvement — `getWeeklySeasonProgressWithTrend` already computes this trend/delta |
| Season Veteran | Participated in N consecutive weekly ladders |
| Global Top 50 / Top 10 / #1 | Lifetime placement on the global leaderboard |

**Dependency**: none of this category is reachable today. `Current_State.md` already flags that the shipping `FallingModuloGameScreen` never calls `LeaderboardService` — no score submission, no leaderboard navigation. Competitive achievements (and the "Weekly rank badges" line already in the store description) need that gap closed first.

## Rewards

Deliberately **cosmetic/status only** — no mechanical power (no extra lives, no score multipliers, no faster combos). The game's core appeal is a fair, skill-pure leaderboard; a purchased-or-earned mechanical boost would corrupt that.

Candidate reward types, escalating with tier:
- Gamertag flair/icon shown on leaderboard rows and in Settings
- Bucket/tile color themes unlocked at higher tiers
- Profile frame, with a distinct one for reaching **Modulo** tier in any track
- An in-app "Trophy Case" screen listing all earned achievements and current tier per track

A soft-currency or season-pass layer is a reasonable Phase 2 once there's a server-side ledger, but isn't needed to ship v1.

## Implementation notes

- Foundation achievements and session-local Mastery achievements (Score Chase, Combo Master, Level Climber, Precision, Survivor for a single run) can be evaluated client-side from data already produced during a run.
- Lifetime/cumulative achievements (Grinder, Competitive category) must be server-validated the same way scores are today — otherwise they're as spoofable as an unvalidated score submission would be. Firestore already reserves a `game_stats/{uid}` collection in the security rules for exactly this; nothing populates it yet.
- Recommend a v1 slice before building the full set: Foundation achievements (client-only, cheapest to ship) plus 1-2 Mastery tracks that need no server changes (e.g. Score Chase, Level Climber, using the existing local high-score value), deferring Competitive achievements until leaderboard wiring is decided.

## Open decisions

1. Exact numeric thresholds above are a draft — tune against real playtesting data once available.
2. Whether to wire the falling-mode screen to `LeaderboardService` this release (unblocks Competitive achievements and makes the store description's "Weekly rank badges" claim accurate) or defer both and remove that claim from store copy for now.
3. Scope for initial ship: full design above, or the v1 slice described in Implementation notes.
