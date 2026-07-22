# Modulo Squares - Social Media Execution Plan

> **Marketing plan (reviewed 2026-07-20):** Launch-state text below reflects its 2026-06-22 planning date. Verify App Store availability and current calls to action before publishing scheduled copy.

**Version**: 1.0
**Date**: 2026-06-22
**Owner**: Mark Nelson
**Launch state**: iOS submitted for App Store Review; Android is Phase 2

---

## Objective

Launch Modulo Squares on social channels with a practical, repeatable plan that drives first installs, collects player feedback, and creates a small community around daily puzzle challenges.

This plan implements the broader guidance in [Social Media Strategy](Social_Media_Strategy.md). Use this document as the launch checklist, copy bank, asset map, and weekly operating cadence.

## Ground Rules

- Do not claim Android availability until the Android release is live.
- Use `https://modulosquares.com/download` as the public link until the final App Store URL is confirmed.
- Replace `TODO_APP_STORE_URL` everywhere before posting approval-day copy.
- Lead with gameplay, puzzle tension, and scores. Avoid generic startup or app-launch language.
- No paid ads until App Store retention, uninstall, rating, and first-session completion data are reviewed.
- Reddit posting must be slow and authentic: comment first, post sparingly, and follow each subreddit rule page.

## Accounts To Create Or Confirm

| Platform | Handle | Purpose | Status |
|---|---|---|---|
| X / Twitter | `@modulosquares` preferred, `@modulosquaresgame` fallback | Fast launch updates, daily score prompts, dev updates | TODO |
| Reddit user | `u/modulosquares` preferred | Community participation and launch posts | TODO |
| Reddit community | `r/ModuloSquares` preferred | Owned support and challenge hub | TODO |
| TikTok | `@modulosquares` preferred | Short gameplay clips | TODO |
| Instagram | `@modulosquares` preferred | Reserved handle and reposted short clips | TODO |
| YouTube | Modulo Squares | Reserved handle and future how-to videos | TODO |
| Product Hunt | Mark Nelson / Modulo Squares | Launch listing after app stability is confirmed | TODO |

### Profile Setup

Use the same profile image everywhere:

- Preferred source: `packages/web/public/icon-modulo-squares.png`
- Alternate source: `packages/mobile/assets/icons/icon.png`

Bio copy:

```text
Math puzzle game for iPhone. Guide falling numbers to their modulo buckets. Free to play.
https://modulosquares.com/download
```

Short bio for character-limited platforms:

```text
Math puzzle game for iPhone. Guide numbers to their modulo buckets.
```

Pinned post after approval:

```text
Modulo Squares is live on iPhone.

Guide falling numbers into their modulo buckets, chain clean runs, and climb the leaderboard.

Download: TODO_APP_STORE_URL
```

## Asset Map

| Asset | Path | Use |
|---|---|---|
| App icon | `packages/web/public/icon-modulo-squares.png` | Profile image, launch cards |
| iOS screenshot 1 | `packages/mobile/assets/store/screenshots/ios-6.5/01-title-rules.png` | Rules / intro post |
| iOS screenshot 2 | `packages/mobile/assets/store/screenshots/ios-6.5/02-active-gameplay.png` | Primary launch image |
| iOS screenshot 3 | `packages/mobile/assets/store/screenshots/ios-6.5/03-paused-run.png` | Score / challenge post |
| iOS screenshot 4 | `packages/mobile/assets/store/screenshots/ios-6.5/04-settings.png` | Feature/support post |
| iOS screenshot 5 | `packages/mobile/assets/store/screenshots/ios-6.5/05-sign-in-sign-up.png` | Account / leaderboard post |
| iOS screenshot 6 | `packages/mobile/assets/store/screenshots/ios-6.5/06-create-gamertag.png` | Gamertag / identity post |
| Store description | `packages/mobile/assets/store/metadata/description.txt` | App Store and Product Hunt copy source |
| Short description | `packages/mobile/assets/store/metadata/short_description.txt` | Social bios and short posts |
| Keywords | `packages/mobile/assets/store/metadata/keywords.txt` | App Store search positioning |

Missing assets to produce before launch week:

- 10-15 second vertical gameplay clip showing one successful sequence.
- 10-15 second vertical gameplay clip showing a near miss or recovery.
- Square launch card with app icon, gameplay screenshot, and "Now on iPhone".
- Product Hunt gallery set using the App Store screenshots.

## Phased Launch Plan

### Phase A - App Review Waiting Room

Timing: now through App Store approval.

Checklist:

- [ ] Create or confirm all social accounts.
- [ ] Apply consistent profile image, bio, and download link.
- [ ] Create `r/ModuloSquares` if available.
- [ ] Comment genuinely in 5-10 relevant Reddit threads without promoting the app.
- [ ] Prepare Product Hunt draft but do not schedule it yet.
- [ ] Capture or export two vertical gameplay clips.
- [ ] Save approval-day posts as drafts.
- [ ] Build a simple tracking sheet using the metrics table below.

Allowed posts before approval:

- Development clips without "download now" language.
- Puzzle challenge prompts.
- "Coming soon to iPhone" teasers.
- Replies and comments where the app is relevant and disclosed honestly.

Avoid before approval:

- "Available now" language.
- App Store URL placeholders in public posts.
- Posting the same copy across multiple subreddits.

### Phase B - Approval Day / Day 0

Trigger: App Store status is approved and the app is available for download.

Checklist:

- [ ] Replace `TODO_APP_STORE_URL` in all saved posts.
- [ ] Confirm `https://modulosquares.com/download` resolves to the correct App Store path.
- [ ] Pin the launch post on X and Reddit profile/community.
- [ ] Post one X launch thread.
- [ ] Post one TikTok gameplay clip.
- [ ] Post one Reddit launch post in the best-fit subreddit after checking rules.
- [ ] Ask early players for bug reports, difficulty feedback, and ratings only after they have played.
- [ ] Log every post URL in the metrics tracker.

### Phase C - First 14 Days

Cadence:

- Reddit: 2-3 posts total across 14 days, each in a different relevant community.
- X: 4-5 posts per week.
- TikTok: 2 clips per week.
- Instagram: repost TikTok clips only if the account is ready.
- Owned community: one weekly challenge thread in `r/ModuloSquares`.

Focus:

- Find which message works: "math puzzle", "falling-number puzzle", "modulo challenge", or "score chase".
- Reply to every meaningful comment within 24 hours.
- Record common confusion and feed it back into onboarding, App Store copy, and FAQ.

### Phase D - Days 15-30

Checklist:

- [ ] Review App Store Analytics source data.
- [ ] Review Firebase/analytics retention and first-session completion.
- [ ] Choose the top 2 social formats by installs or click-through.
- [ ] Run one weekly leaderboard/challenge post.
- [ ] Prepare Product Hunt launch only if the app is stable and the first reviews are acceptable.
- [ ] Decide whether to begin Android waitlist messaging.

## 30-Day Calendar

| Day | Platform | Action | Asset | Goal |
|---|---|---|---|---|
| -5 to -1 | Reddit | Comment on puzzle/math/game threads without promotion | None | Build trust |
| -3 | X | Coming-soon gameplay teaser | Gameplay clip | Start awareness |
| -2 | TikTok | Post a satisfying gameplay sequence | Vertical clip | Test short-form hook |
| -1 | All drafts | Finalize launch copy with placeholders | Screenshots | Prepare |
| 0 | X | Launch post + pinned post | Active gameplay screenshot | Announce |
| 0 | TikTok | "Can you beat this run?" clip | Vertical clip | Reach non-followers |
| 0 or 1 | Reddit | One launch post in best-fit subreddit | Active gameplay screenshot | Feedback and installs |
| 2 | X | Score challenge prompt | Paused-run screenshot | Engagement |
| 3 | Reddit | Puzzle-specific post, not duplicate launch copy | Rules screenshot | Feedback |
| 4 | TikTok | Near miss or recovery clip | Vertical clip | Watch time |
| 5 | X | Dev note about modulo mechanic | None or screenshot | Explain concept |
| 7 | Reddit owned | First weekly challenge thread | Paused-run screenshot | Community habit |
| 10 | TikTok | "One rule that makes this hard" clip | Vertical clip | Education |
| 14 | X/Reddit owned | Week 1 recap and high-score prompt | Score screenshot | Retention |
| 21 | X/TikTok | Best-performing format repeat | Top asset | Scale winner |
| 30 | Product Hunt | Launch or defer based on stability | Gallery | Discovery |

## Copy Bank

### Approval-Day X Post

```text
Modulo Squares is live on iPhone.

It is a falling-number puzzle game where every move is about remainders: guide each number into the right modulo bucket, keep the board clean, and chase a better run.

Download: TODO_APP_STORE_URL
```

### X Score Challenge

```text
Today's Modulo Squares challenge:

Play one run. No restarts. Post your score.

Download: TODO_APP_STORE_URL
```

### X Dev Note

```text
The core rule in Modulo Squares is simple:

a number belongs in a bucket when the remainder matches.

The hard part is making that decision while the board keeps moving.
```

### Reddit Launch Post

Title:

```text
I made a falling-number puzzle game about modulo arithmetic, and it is now live on iPhone
```

Body:

```text
I built Modulo Squares, a mobile puzzle game where falling numbers need to be guided into buckets based on their modulo result.

The rule is simple, but the pressure comes from making quick decisions as the board fills up. I wanted it to feel like a small arcade puzzle that rewards pattern recognition instead of memorization.

It is free on iPhone: TODO_APP_STORE_URL

I would genuinely appreciate feedback on the first-session experience, difficulty curve, and whether the rules are clear from the first run.
```

### Reddit Puzzle Challenge Post

Title:

```text
Puzzle prompt: how quickly can you sort numbers by their remainder?
```

Body:

```text
I have been working on a puzzle game built around a small modulo rule:

numbers fall in, and each one belongs in the bucket matching its remainder.

The interesting part is that it becomes less about doing math slowly and more about recognizing patterns under pressure.

If you try it, I am especially interested in whether the rule clicks quickly or needs a clearer tutorial.

Download: TODO_APP_STORE_URL
```

### TikTok Script 1 - The Hook

```text
Visual: Start mid-game with numbers falling.
On-screen text: "This puzzle is just remainders... until it gets fast."
Action: Show 2-3 correct placements, then one close call.
End card: "Modulo Squares - now on iPhone"
Caption: Can you keep the board clean?
```

### TikTok Script 2 - Near Miss

```text
Visual: Board nearly full.
On-screen text: "One wrong bucket ends the run."
Action: Recover from a bad board state.
End card: "Beat this run?"
Caption: Modulo Squares is live on iPhone.
```

### TikTok Script 3 - Explain The Rule

```text
Visual: Number 17 appears, buckets show possible modulo targets.
On-screen text: "17 mod 5 = 2"
Action: Place it correctly, then speed up through several examples.
End card: "A math puzzle that turns into reflexes."
Caption: Free on iPhone.
```

### Product Hunt Short Description

```text
A falling-number puzzle game about modulo arithmetic, quick decisions, and cleaner runs.
```

### Product Hunt Maker Comment

```text
Hi Product Hunt - I built Modulo Squares because I wanted a mobile puzzle game where the math rule is simple, but mastery comes from pattern recognition and speed.

Each number has to land in the right modulo bucket. Early runs are calm; later runs become a fast test of whether the remainder pattern has clicked.

I would love feedback on the first-run tutorial, difficulty curve, and whether the core mechanic feels clear without over-explaining it.
```

## Metrics Tracker

Use this table as a spreadsheet template.

| Date | Platform | Post URL | Asset used | Views/impressions | Engagement | Link clicks | Installs | Notes | Next action |
|---|---|---|---|---:|---:|---:|---:|---|---|
| YYYY-MM-DD | X | TODO | `02-active-gameplay.png` | 0 | 0 | 0 | 0 | TODO | TODO |

Weekly review questions:

- Which post produced the most clicks?
- Which post produced the most saves, comments, or replies?
- Which audience understood the rule fastest?
- Which wording created confusion?
- Did the download page or App Store page create a drop-off?
- Are players asking for Android, daily challenges, hints, or easier onboarding?

## Definition Of Done This Week

- [ ] All priority accounts are created or reserved.
- [ ] Profiles use the same icon, bio, and download link.
- [ ] App Store approval-day copy is drafted with only `TODO_APP_STORE_URL` remaining.
- [ ] At least two vertical gameplay clips exist.
- [ ] One Reddit launch post is selected and subreddit rules are checked.
- [ ] The website share copy does not claim Android availability.
- [ ] A metrics tracker is ready before the first launch post.
