# Modulo Squares — Social Media Strategy

> **Marketing strategy (reviewed 2026-07-20):** Channel/platform details are time-sensitive. Current product messaging should describe the falling divisor-bucket game and link to `https://modulosquares.com`.

**Version**: 1.0
**Date**: June 2026
**Owner**: Mark Nelson

---

## Overview

This document provides a complete, step-by-step social media strategy for Modulo Squares. The goal is to drive organic installs, build a community, and establish a recognizable brand — without paid advertising and without needing social media expertise.

The strategy is built around one core principle: **show the game, not the marketing.** Puzzle games that go viral do so because someone sees gameplay and thinks "I want to try that." Every platform tactic below serves that goal.

## Current Execution Plan

Use [Social Media Execution Plan](Social_Media_Execution_Plan.md) for the current launch checklist, copy bank, account setup status, asset map, and metrics tracker. The execution plan reflects the June 2026 iOS-first launch state: iPhone is the current public launch target, and Android messaging should wait until the Android release is live.

---

## 1. Platform Priority & Rationale

You do not need to be on every platform. Start with these three, in this order:

### Priority 1 — Reddit (Start immediately, Week 1)
**Why first**: Your exact target audience (25-45, educated, puzzle enthusiasts) is already on Reddit discussing puzzle games. It's free, organic, and one good post can drive thousands of installs.

**Key subreddits**:
| Subreddit | Size | Why |
|---|---|---|
| r/puzzles | 550K | Direct audience — puzzle enthusiasts |
| r/math | 1.4M | Math-curious users who'll appreciate modulo |
| r/indiegames | 250K | Indie game discovery community |
| r/iosgaming | 800K+ | Mobile game discovery for the iOS-first launch |
| r/casual | 300K | Casual gaming audience |

### Priority 2 — TikTok (Start Week 2–3)
**Why second**: TikTok's algorithm does not require followers. A first post from a brand new account can reach 100,000 views. Mobile puzzle games perform extremely well because 15-second clips of satisfying gameplay are inherently shareable. You do not need to appear on camera.

### Priority 3 — Twitter / X (Start Week 2)
**Why third**: Low effort once set up. Daily math puzzle posts build a following passively and contribute to SEO through indexed social content. Posts can be scheduled in batches.

### Priority 4 — Instagram (Start Month 2)
**Why fourth**: Repurpose TikTok content. Lower organic reach than TikTok but builds visual brand presence for players who check before downloading.

### Priority 5 — YouTube (Start Month 3)
**Why fifth**: Long-term SEO value. "How to play Modulo Squares" and "level walkthrough" videos rank in Google search and drive installs for years. Not time-sensitive — add when you have bandwidth.

---

## 2. Account Setup — Step by Step

### Step 1: Create Accounts (1 hour total)

Create accounts on all platforms using the same handle: **@modulosquares** or **@modulosquaresgame** if taken.

Use the same profile image on every platform: the app icon (1024x1024 PNG from the iOS asset set).

**Bio text (copy/paste for each platform)**:
> Math puzzle game for iPhone. Guide falling numbers to their modulo buckets. Free to play. 📲 modulo-squares.com

**Link**: `https://modulosquares.com/download`

Platforms and signup URLs:
- Reddit: Create a user account at reddit.com, then create subreddit r/ModuloSquares as a community hub
- TikTok: tiktok.com/signup — use business account type
- Twitter/X: x.com/signup
- Instagram: instagram.com — switch to Creator account in settings after signup
- YouTube: Create a channel at youtube.com/create-channel

### Step 2: Link In Your Footer (already built)

The website footer social icons component is ready at `packages/web/src/components/Footer.tsx`. Once you have account URLs, update the `SOCIAL_LINKS` array in that file with your handles. The icons and share widget are already implemented.

---

## 3. Reddit — Detailed Playbook

Reddit rewards authenticity and penalizes marketing. The rules below are critical.

### Rule 1: Be a member first, marketer second
Before posting about Modulo Squares, spend 1 week upvoting, commenting on posts you genuinely find interesting in r/puzzles and r/math. This builds karma and reduces the chance of posts being flagged as spam.

### Rule 2: Show, don't sell

**BAD post** (will be downvoted/removed):
> "Check out my new game Modulo Squares! Download it here: [link]"

**GOOD post** (will get upvotes):
> "I made a puzzle game based on modulo arithmetic — here's a level that's stumping people [screenshot]. Spoiler-free discussion in comments."

### Step-by-Step Reddit Launch Sequence

**Week 1 (Before posting)**:
1. Create Reddit account
2. Spend 30 minutes/day commenting on r/puzzles and r/math posts
3. Set up Reddit alerts for "modulo", "puzzle game", "math game"

**Week 2 — r/indiegames post**:
Post title: `I built a mobile puzzle game based on modulo arithmetic — a math concept that never shows up in games`

Post body template:
```
I've been building Modulo Squares for about a year, and I wanted to share it with people who appreciate math and puzzle design.

The core mechanic: numbers fall from the top, you guide them into buckets labeled with divisors. A number 15 goes into the bucket for any divisor of 15 (1, 3, 5, 15). Numbers interact via modulo operations as they stack.

What I tried to do differently:
- The "eureka moment" when modulo clicks usually happens around level 8-10
- Competitive leaderboard with weekly resets
- No pay-to-win, no energy systems — just the puzzle

It's free on iOS [App Store link]. Would love honest feedback from people who care about game design.

Screenshots in comments.
```

**Week 2 — r/math post**:
Post title: `My game accidentally teaches modulo arithmetic — players who "get it" describe it as a moment when math "clicked"`

**Week 3 — r/puzzles post**:
Post title: `Can you beat 2,400 points? Weekly leaderboard reset — top scores from this week [screenshot]`

### Ongoing Reddit Cadence (15 min/week)
- **Monday**: Post top 3 weekly leaderboard scores as an image
- **Wednesday**: Post a "challenge level" screenshot and ask the community for their high scores
- **Friday**: Respond to any comments, share any user-submitted scores

---

## 4. TikTok — Detailed Playbook

### What to Record
You do not need to be in the video. Record your iPhone screen using the iOS built-in screen recorder (Control Center → Screen Recording).

**Video type 1 — Satisfying solve (most shareable)**:
Record a level where the numbers fall perfectly into the right buckets. 15-30 seconds. No narration needed — add upbeat background music in TikTok's editor.

**Video type 2 — "Can you beat me?" challenge**:
Show your score on the leaderboard. Text overlay: "Can anyone beat [score]? Comment your score 👇". This drives comments which TikTok's algorithm rewards.

**Video type 3 — "Wait, that's math?" hook**:
Text on screen: "This game is secretly teaching you modulo arithmetic." Then show gameplay. End with the score. Caption: "Most people don't realize they're doing math."

**Video type 4 — Day in the game**:
Show the daily challenge, attempt it, show the result. 20-30 seconds. Works best with a "fail" followed by a retry and success.

### Posting Schedule (Once Weekly to Start)
- **Day**: Wednesday or Thursday (TikTok analytics show peak puzzle content engagement)
- **Time**: 7–9 PM in your local timezone
- **Hashtags**: `#puzzlegame #mathgame #indiegame #puzzles #math #mobilegaming #iosgame`

### How to Make a TikTok Video (Step by Step)
1. Open iOS Screen Recording in Control Center
2. Open Modulo Squares and play a level — aim for a clean, satisfying run
3. Stop recording (appears in Photos)
4. Open TikTok → "+" → upload the video
5. Trim to 15-30 seconds (the best part)
6. Add music: search "satisfying" in TikTok sounds library
7. Add 1–2 text overlays: "Level 15" at start, your score at end
8. Write caption: "How are people NOT talking about this game? 🤯 #puzzlegame #math"
9. Add hashtags from the list above
10. Post

### TikTok Reply Strategy
The first 30 minutes after posting are critical. Reply to every comment — even just "❤️" — to signal engagement to the algorithm.

---

## 5. Twitter / X — Detailed Playbook

Twitter requires low time investment but consistent posting. Set up a 2-hour session once per week to schedule all 7 posts.

### Daily Post Templates (Copy, Adapt, Schedule)

**Monday — Weekly leaderboard**:
> 🏆 Weekly leaderboard just reset. Who's going for #1?
>
> Current top score: [X]
> Your move. 👇
>
> [App Store link] #puzzlegame #math

**Tuesday — Math fact**:
> Quick math: what is 17 mod 5?
>
> (Hint: it's a core mechanic in Modulo Squares 🎮)
>
> Answer in replies.

**Wednesday — Gameplay screenshot**:
> Level 12 is the one that separates the mathematicians from everyone else.
>
> What's your highest level? [screenshot]

**Thursday — Tip**:
> Modulo Squares tip: if a number is prime, the only valid buckets are 1 and itself.
>
> This single insight will improve your score by ~30%.

**Friday — Community**:
> Someone just submitted the first score over [X] points. 👀
>
> Leaderboard: modulosquares.com/leaderboard

**Saturday — Weekend challenge**:
> Weekend challenge: 30-minute session. What's your best score?
>
> Screenshot your leaderboard rank 👇

**Sunday — Behind the scenes (optional)**:
> Built this game to make modulo arithmetic make sense without a textbook.
>
> Three years later: it's finally on the App Store.
>
> [link]

### Scheduling Tool
Use Buffer (free plan, buffer.com) or TweetDeck to schedule all 7 posts in one sitting per week.

---

## 6. Product Hunt Launch

Product Hunt is a one-time event that can drive 500–2,000 installs in 24 hours from an audience of tech-savvy early adopters who leave reviews and share products.

### Step-by-Step Product Hunt Launch

**2 weeks before launch**:
1. Create a Product Hunt account at producthunt.com
2. Comment on 5–10 other products (builds credibility and reduces "hunter" restrictions)
3. Find a "Hunter" — a Product Hunt user with 1,000+ followers who can post your product on your behalf. Search producthunt.com/hunters. Reach out via Twitter DM: "Hi [name], I'm launching a math puzzle game on iOS on [date] — would you be willing to hunt it on Product Hunt? Happy to return the favor."

**1 week before launch**:
1. Prepare your Product Hunt listing:
   - **Name**: Modulo Squares
   - **Tagline**: "The puzzle game that accidentally teaches you modulo arithmetic" (max 60 chars: "Guide falling numbers to their modulo buckets")
   - **Description**: 3-4 sentences. Open with the problem: "Most math games feel like homework. Modulo Squares feels like a puzzle." End with the hook: "The 'click' moment usually happens around level 8."
   - **Gallery**: 5 screenshots + 1 short GIF of gameplay (use Gifski app to convert a screen recording)
   - **Links**: App Store URL + modulosquares.com

2. Line up 10–20 upvoters in advance. Ask friends, family, colleagues to upvote when it goes live. Post in r/indiegames and your social channels the day before: "We're launching on Product Hunt tomorrow — support would mean a lot."

**Launch day**:
1. Post at 12:01 AM Pacific Time (Product Hunt resets at midnight PT — early posts get the full 24-hour cycle)
2. Respond to every comment within 1 hour
3. Share the Product Hunt link on all social channels simultaneously
4. Post in r/indiegames: "We launched on Product Hunt today [link] — any PH upvotes very appreciated"

---

## 7. Content Calendar — First 30 Days

| Day | Platform | Content | Time Required |
|---|---|---|---|
| Launch Day | All | Product Hunt launch, social announcements | 3 hours |
| Day 1 | Reddit | r/indiegames post with screenshots | 30 min |
| Day 3 | Reddit | r/math post | 20 min |
| Day 5 | TikTok | First gameplay video | 45 min |
| Day 7 | Twitter | First weekly leaderboard post | 10 min |
| Day 7 | Reddit | r/puzzles weekly leaderboard screenshot | 15 min |
| Day 10 | TikTok | "Can you beat me?" challenge video | 30 min |
| Day 14 | Twitter | 7-post weekly schedule (batch) | 1 hour |
| Day 14 | Reddit | Weekly leaderboard thread | 15 min |
| Day 17 | TikTok | "Wait, that's math?" video | 45 min |
| Day 21 | Twitter | Batch schedule | 1 hour |
| Day 21 | Reddit | Community challenge post | 20 min |
| Day 28 | Instagram | Set up account, post 3 TikTok reposts | 1 hour |
| **Total Month 1** | | | **~10 hours** |

---

## 8. Viral Mechanics to Build Into the App

These features increase organic social sharing without any ongoing effort. They are ordered by impact and implementation complexity.

### Feature 1 — Share Score Button (High Impact, Easy)
After completing a level, a share button generates a pre-filled message:
> "I just scored [X] on Modulo Squares Level [N]! Can you beat me? 🎮 modulo-squares.com/download"

The website's leaderboard page already has a social share widget. The mobile app needs a native share sheet call after each level.

**Implementation**: `Share.share(text)` from the `share_plus` Flutter package.

### Feature 2 — Leaderboard Rank Share (High Impact, Easy)
When a player enters the top 10 weekly leaderboard, prompt:
> "You're #3 this week! Share your rank?"

Same implementation as above.

### Feature 3 — Weekly Achievement Summary
Every Monday, send a push notification:
> "Your week: 47 levels, #12 on the leaderboard. Keep the streak going!"

Users share these natively (screenshot) because they show accomplishment.

### Feature 4 — "Challenge a Friend" Deep Link
Generate a shareable link that opens the app at a specific level with the friend's score as a target. Requires Firebase Dynamic Links.

---

## 9. Metrics to Track

### Weekly Checklist (10 minutes every Monday)
- [ ] App Store impressions (App Store Connect → Analytics)
- [ ] Downloads this week vs. last week
- [ ] Top referral source (App Store Connect → Source)
- [ ] Reddit post upvote count on any active posts
- [ ] TikTok video views (TikTok Analytics)
- [ ] Leaderboard participation (Firebase Console → Firestore)

### 30-Day Success Indicators
| Metric | Minimum | Target |
|---|---|---|
| Product Hunt upvotes | 50+ | 200+ |
| Reddit post upvotes (best post) | 50+ | 500+ |
| TikTok views (best video) | 5,000+ | 50,000+ |
| Twitter followers | 100+ | 500+ |
| App installs from social | 100+ | 1,000+ |

---

## 10. What NOT to Do

These are the most common mistakes indie developers make on social media:

1. **Don't ask for downloads directly** — Say "would love feedback" not "please download"
2. **Don't post the same content on every platform** — Reddit users hate cross-posts; TikTok content doesn't translate to Twitter
3. **Don't disappear after launch** — One post and nothing for 2 weeks signals abandonment to algorithms
4. **Don't use engagement pods or bot followers** — Platforms detect these and suppress your reach
5. **Don't keyword-stuff captions** — Use 5–7 relevant hashtags, not 30
6. **Don't argue with negative comments** — Reply once politely, then disengage
7. **Don't spend money on paid social ads** — Until you have D7 retention data, paid ads are money-burning. Organic first.

---

## 11. Email / Community Newsletter (Month 3+)

Once you have 500+ installs, start a simple email newsletter via Beehiiv (free up to 2,500 subscribers). One email per month:
- Weekly leaderboard highlights
- New levels added
- Upcoming features
- "Player of the month" spotlight

Collect emails via: `modulosquares.com` footer signup + in-app prompt after level 10.

---

## References
- Business requirements social targets: [Business_Requirements.md](./Business_Requirements.md) §3.2
- Website SEO / OG tags: `packages/web/index.html`, `packages/web/src/components/SEOHead.tsx`
- App download page: `packages/web/src/components/Download.tsx`
- Social share widget: `packages/web/src/components/SocialShare.tsx`
