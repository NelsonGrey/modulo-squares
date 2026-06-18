# Modulo Squares - Product Design & Feature Specifications

**Version**: 1.0  
**Last Updated**: February 12, 2026  
**Status**: ✅ SHIPPED & OPERATIONAL  
**Owner**: Mark Nelson

---

## 🎮 Product Vision

**Vision Statement**: "Empower puzzle enthusiasts to challenge their minds with mathematical elegance while building a thriving community of players worldwide."

**Product Positioning**: Modulo Squares is a mobile-first strategic puzzle game combining modulo arithmetic mechanics with intuitive tile-based gameplay. It's targeted at players aged 13-65 who enjoy brain-training games with progression, competition, and daily engagement.

**Core Value Proposition**:
- Unique mechanic: Modulo arithmetic puzzle solving (vs. match-3, Sudoku, or traditional tile games)
- Accessible learning: Introduce mathematical concepts through gameplay, not instruction
- Deep strategy: 50+ levels with increasing difficulty and complexity
- Community features: Global leaderboards and social competition
- Monetized engagement: Ad-supported model with optional premium removal

---

## 🎨 Design Language & UX Principles

### Design Principles

1. **Clarity First**: Mathematical operations and game states must be instantly clear
2. **Minimal Friction**: One-tap level select, snap-to-grid controls, instant feedback
3. **Engaging Feedback**: Haptic feedback, satisfying animations, prominent success states
4. **Inclusive Design**: Color-blind mode, adjustable text sizes, high-contrast options
5. **Aesthetic Gamification**: Visual progression (stars, badges, unlock animations)

### Visual Language

**Color Palette**:
- Primary: Deep purple (#6C2D8D) used for UI elements, negative space
- Accent: Bright teal (#00D4FF) for interactive elements, highlights, CTAs
- Game Board: Neutral grays and whites for tile backgrounds
- Score/Info: Dark gray (#2D3436) for readability

**Typography**:
- Headers: Geometric Sans (Inter, Montserrat) - modern, clean
- Body: System fonts (iOS: San Francisco, Android: Roboto) - fast, accessible
- Game Numbers: Monospace (Courier, Courier New) - clear number rendering

**UI Components**:
- Buttons: Rounded corners (8px), 2-point stroke outlines, clear affordance
- Modals: Full-screen or 70% viewport width, slide-in from bottom (mobile)
- Feedback: Toast notifications (bottom-safe area), confetti animations on victory

---

## 👥 User Personas & Use Cases

### Primary User: "Puzzle Enthusiast"

**Scenario**: Evening downtime, 15-30 minute gaming session

1. Opens app after work
2. Reviews daily challenges (earns bonus rewards)
3. Attempts 3-5 levels of current progression
4. Watches optional ad for daily streak bonus
5. Closes app, returns next day

**Pain Points Addressed**:
- Ad fatigue: Optional (skip anytime), integrated rewards (not intrusive)
- Progression plateau: Increasing difficulty, mastery/expert variants maintain engagement
- Session length: Levels designed for 2-5 minute solves, pauseable mid-game

---

### Secondary User: "Competitive Player"

**Scenario**: Daily engagement, chasing leaderboard ranks

1. Opens app, checks global leaderboard position
2. Reviews personal best scores (tracks improvement)
3. Replays favorite levels to optimize score
4. Shares achievement with friends (screenshot, link)
5. Competes in daily challenges for bonus points

**Pain Points Addressed**:
- Stale gameplay: Daily rotating challenges, limited-time events
- Social proof: Leaderboard, friend competition, public profiles
- Replay value: Scoring system (speed, efficiency) encourages replays

---

### Tertiary User: "Math-Curious Student"

**Scenario**: School break, learning math playfully

1. Opens app, sees explanatory tutorial for new modulo concept
2. Plays 2-3 beginner levels to understand mechanic
3. Leaves when homework time arrives (no pressure to continue)
4. Returns next week, sees progression saved

**Pain Points Addressed**:
- Learning anxiety: Tutorial explains concepts, sandbox levels practice before "real" levels
- Abandonment guilt: No monetization pressure, no streaks that punish breaks
- Mastery tracking: Visualized progress (10 of 50 levels complete)

---

## 🎮 Core Game Mechanics

### The Modulo Squares Gameplay Loop

**Board Layout**: 4×4 grid of tiles (16 total)

**Tile States**:
- Empty: Can be filled with a number (0-9)
- Occupied: Contains number 0-9, shows modulo result in corner
- Locked: Immovable tiles placed randomly, must work around them (difficulty scaling)
- Goal Zone: Highlighted region where specific result must be achieved

**Turn Mechanic**:
1. Tap tile to select
2. Choose operation: +1, +2, +3 (or -1, -2, -3 at higher levels)
3. Choose target tile to apply operation
4. Tile updates with new value % 10 (modulo 10 operation)
5. Check completion: All goal zones match target values?

**Example Level (Tutorial)**: 
- Goal: Achieve value 5 in goal zone (2 tiles highlighted)
- Starting board: Random values 0-9
- Allowed operations: +1, +2 only
- Constraints: 8 moves maximum
- Solution: Strategic application of +1 and +2 to each tile until both reach 5

**Difficulty Progression**:
- Levels 1-10 (Easy): Larger boards, fewer constraints, obvious solutions
- Levels 11-30 (Medium): Smaller boards, locked tiles, multiple goal zones, 4-6 moves max
- Levels 31-50 (Expert): Complex boards, negative operations, advanced modulo patterns

---

## 📊 Core User Flows

### Flow 1: New User Onboarding

```
Start App
  ↓
[Create Account / Guest] → Skip Login (Anonymous)
  ↓
[Tutorial Screens]
  ├→ Screen 1: "Welcome to Modulo Squares - Master numbers, outsmart puzzles"
  ├→ Screen 2: "Modulo basics - Numbers wrap around at 10"
  ├→ Screen 3: "Your first puzzle - Apply +1 to reach target"
  └→ Screen 4: "You're ready! Start playing" → Home Screen
  ↓
[Home Screen]
  ├→ Your Progress (5 of 50 levels complete)
  ├→ Daily Challenge (+ 50 bonus points)
  ├→ Leaderboard
  └→ Play Level 1
```

**Time Investment**: 3-5 minutes (can skip tutorials)

---

### Flow 2: Daily Engagement Loop

```
Open App
  ↓
[Home Notifications]
  ├→ "2-day streak! Play today to keep it going"
  ├→ "New daily challenge available"
  └→ "Friend Alex beat your high score on Level 5"
  ↓
[User Actions]
  ├→ Play Daily Challenge → Earn 50 bonus points → Share Result (optional)
  ├→ Continue Level Progression (Play Level X)
  ├→ Check Leaderboard (see rankings)
  └→ Social (View friend profiles, accept challenges)
```

**Expected Session Duration**: 10-20 minutes

---

### Flow 3: Achievement & Sharing

```
Level Complete Screen
  ↓
[Victory State]
  ├→ Level completed in 4 moves, target 6 → ⭐⭐⭐ (3 stars)
  ├→ Personal Best: 5 moves (you improved!)
  ├→ Leaderboard Position: Rank #2,456 globally
  └→ Actions:
      ├→ [Share Achievement] → Social sheet (WhatsApp, Facebook, etc.)
      ├→ [Replay Level] → Back to gameplay
      ├→ [Next Level] → Level X+1
      └→ [Home] → Hub
```

**Share Template**: "I solved Modulo Squares Level 5 in 4 moves! 🧩 Can you beat my score? [App Link]"

---

### Flow 4: Monetization - Ad Viewing

```
User triggers optional reward (e.g., Daily Streak Bonus)
  ↓
[Ad Offer Modal]
  ├→ "Watch 30s video to earn 50 bonus points"
  ├→ [Watch Ad] → Play video → Reward awarded → Home
  └→ [Skip] → Return to game (no penalty)
```

**Key**: Ads are optional, skippable, rewarded (not intrusive)

---

## 🏗️ Feature Specifications

### Feature 1: Game Board & Gameplay

**Status**: ✅ Complete

| Requirement | Implementation |
|-------------|-----------------|
| 4×4 tile grid | Fixed layout, responsive scaling |
| Tile interactions | Tap-select, slide-gesture (alternative) |
| Operation buttons | +1, +2, +3 (easy levels), -1, -2 (harder) |
| Modulo calculation | Automatic % 10 on tile update |
| Move counter | Displayed, decrements with each action |
| Undo functionality | Tap to undo last move (costs 0 moves) |
| Tile highlighting | Goal zones pulse, selected tiles glow |

**UI Specification**:
- Tile size: 70×70 points (iOS), 80×80 dp (Android)
- Padding between tiles: 8 points
- Total board: 308×308 points (iOS)
- Responsiveness: Board scales fit-to-width on smaller devices

---

### Feature 2: Level Progression

**Status**: ✅ Complete (50 levels)

| Level Range | Difficulty | Mechanics | Avg. Solve Time |
|-------------|-----------|-----------|-----------------|
| 1-10 | Tutorial (Easy) | +1, +2 only; 1 goal zone; 8+ moves | 2 min |
| 11-20 | Easy | +1, +2, +3; 1 goal zone; 6-8 moves | 3 min |
| 21-30 | Medium | +1 to +3, -1; 2 goal zones; 4-6 moves | 4 min |
| 31-40 | Hard | Full range; locked tiles; 3+ zones; 3-4 moves | 5 min |
| 41-50 | Expert | Complex patterns; advanced modulo; mastery required | 6+ min |

**Content Creation Process**:
- Designed in spreadsheet (verify solution exists)
- Difficulty curve calibrated for retention
- Each level has 3-star threshold (normal, hard, expert solves)

---

### Feature 3: Leaderboards

**Status**: ✅ Complete

**Global Leaderboard**:
- Ranked by total points (all levels combined)
- Updated real-time (↓ frequently)
- Top 100 visible, searchable by username
- Personal rank displayed ("You are #2,456")

**Personal Best**:
- Per-level personal best score (fewest moves)
- Compare to global best move count
- Visual indicator if you're top 100 on level

**Daily Challenges**:
- 1 rotating level daily
- Bonus points if completed (50 pts)
- Resets at 9 AM UTC

**Implementation**: Firebase Realtime Database (optimized queries)

---

### Feature 4: User Accounts & Authentication

**Status**: ✅ Complete

| Auth Method | Implementation | Use Case |
|-------------|-----------------|----------|
| Anonymous | No signup, instant play | Casual users, new players |
| Email/Password | Firebase Auth, optional | Serious players, leaderboard access |
| Social (Google, Apple) | OAuth, single-sign-on | Convenience |

**Profile Page**:
- Username (customizable, unique)
- Avatar (default or upload)
- Play statistics (total levels, personal best average)
- Friends list (add by username or invite)
- Achievements (badges earned)

---

### Feature 5: Notifications

**Status**: ✅ Complete

| Trigger | Message | Action |
|---------|---------|--------|
| New daily challenge | "Daily Challenge Available - First complete within 24h for 50 bonus" | → Play |
| Streak maintenance | "2-day streak! Play today to keep it going" | → Play or Dismiss |
| Ad reward available | "Earn 50 points or unlock next level - watch 30s video?" | → Watch or Skip |
| Friend achievement | "Alex beat Level 5 in 3 moves (your best: 4)" | → View Leaderboard |
| Milestone reached | "You've completed 25 levels! Unlock Expert Mode" | → Unlock |

**Notification Settings**:
- Toggle on/off per type
- Daily Digest option (combine into one notification)
- Quiet hours (no notifications 10 PM - 8 AM)

---

### Feature 6: Monetization

**Status**: ✅ Complete

**Ad Placements**:
1. Daily Reward Offer (optional)
   - Earn 50 bonus points (equivalent to 1 level)
   - 30-second video
   - Frequency: Once per day

2. Level Completion Offer (optional)
   - Earn 10 bonus points
   - OR: Unlock next level without solving current
   - 15-30 second video
   - Frequency: After 5 levels completed

3. Out-of-Moves Offer (optional)
   - Earn 2 extra moves
   - 15-second video
   - Frequency: When move counter hits 0

**AdMob Integration**:
- Banner ads: Bottom of home screen (optional)
- Interstitial: Between level select (skippable after 2 sec)
- Rewarded: All above (required for bonus)

**In-App Purchases (IAP)**:
1. Ad-Free Lifetime: $4.99
   - Removes all ad placements
   - Unlocks Expert Mode immediately
   - One-time purchase

2. Premium Pass: $9.99/month
   - Ad removal
   - 50 bonus points daily
   - Exclusive challenges
   - Early access to new levels

**Revenue Target**: 85% ads, 12% IAP ad removal, 3% premium (see BUSINESS_REQUIREMENTS.md)

---

### Feature 7: Analytics & Tracking

**Status**: ✅ Complete

**Events Tracked** (Firebase Analytics):
- `level_started` (level_id, difficulty)
- `level_completed` (level_id, moves_used, stars_earned, time)
- `level_failed` (level_id, moves_remaining, replay_count)
- `ad_watched` (ad_type, rewarded_bool)
- `iap_purchase` (product_id, price)
- `leaderboard_viewed` (leaderboard_type)
- `friend_added` (source: search, invite, etc.)
- `daily_challenge_completed` (rank_improvement)

**Dashboards**:
- Firebase Dashboard: DAU, DAU cohort retention, revenue
- Custom Dashboard: Funnel (signup → level 1 → level 25 → level 50)

**Privacy**: No PII tracked, GDPR-compliant (user can request data deletion)

---

## 📱 Platform-Specific Considerations

### iOS (Target: iOS 15.0+)

**Technical**:
- SwiftUI for UI (modern, native feel)
- GameKit for leaderboards (native integration)
- Haptic feedback (Taptic Engine)
- Push notifications (iOS 10+)

**App Store**:
- Bundle ID: `com.nelsongrey.modulosquares.ios`
- Category: Games → Puzzle
- Age Rating: 4+ (PEGI 3)
- Screenshots: Gameplay, leaderboard, settings
- Requires: iOS 15.0 or later

**Specific Features**:
- Safe area handling (notch-aware)
- Dark mode support (UI adapts)
- Dynamic type support (accessibility)
- iCloud sync (leaderboard auth via GameKit)

---

### Android (Target: Android 8.0+)

**Technical**:
- Jetpack Compose for UI (modern, declarative)
- Google Play Services for leaderboards
- Vibration feedback
- Firebase Cloud Messaging for notifications

**Play Store**:
- Package Name: `com.nelsongrey.modulosquares.android`
- Category: Games → Puzzle
- Age Rating: Everyone (ESRB: 3+)
- Requires: Android 8.0 (API 26)+

**Specific Features**:
- Gesture navigation support
- Dark mode (Material You colors)
- Adaptive icons (Android 8.0+)
- Material 3 design language

---

### Web (Modern Browsers)

**Technical**:
- React + Vite (fast, modern)
- Canvas/WebGL for game rendering
- Service Worker for offline support
- PWA (installable, works offline)

**Features**:
- Responsive design (mobile-first)
- Keyboard controls (arrow keys + Enter)
- Touch support (tap/swipe on mobile browsers)
- Cloud sync with Firebase (same account across platforms)

---

## 🗺️ Information Architecture

```
Home Screen
├── Your Progress
│   ├── Level X-Y Complete
│   ├── Personal Best: Level X (Y stars)
│   └── Total Points: [Score]
├── Daily Challenge
│   └── Level [Special] - +50 bonus points
├── Leaderboards
│   ├── Global (Top 100)
│   ├── Friends
│   └── Daily Challenge
├── Navigation
│   ├── Play (Level Select)
│   ├── Profile
│   ├── Settings
│   └── More (Help, About, Feedback)
└── Monetization
    ├── Watch Ad (Daily Reward)
    ├── Remove Ads ($4.99)
    └── Premium Pass ($9.99/mo)

Level Select Screen
├── Levels 1-50 (Scrollable Grid)
│   ├── Locked / Completed / Current
│   ├── Personal Best (stars, moves)
│   └── Global Best (compare)
└── Back to Home

Gameplay Screen
├── Game Board (4×4 Grid)
├── Move Counter
├── Operation Buttons (+1, +2, +3, -1, -2)
├── Undo Button
├── Pause Button
└── Timer (optional)

Leaderboard Screen
├── Filter: Global / Friends / Daily
├── Top 100 List
│   ├── Rank #, Username, Points
│   └── [Tap for Profile]
├── Your Rank & Position
└── Back to Home

Profile Screen
├── Username / Avatar
├── Statistics
│   ├── Levels Completed: 50
│   ├── Personal Best Avg: 4.2 moves
│   └── Days Played: 87
├── Achievements (Badges)
├── Friends (List)
└── Settings

Settings Screen
├── Account
│   ├── Email / Password
│   └── Delete Account
├── Notifications
│   ├── Daily Challenges
│   ├── Friend Activity
│   └── Quiet Hours
├── Gameplay
│   ├── Sound (On/Off)
│   ├── Haptic Feedback (On/Off)
│   └── Tutorial Mode (Reset)
├── Privacy
│   ├── Privacy Policy
│   ├── Terms of Service
│   └── Export Data
└── About / Version
```

---

## 🎯 Feature Prioritization Matrix

| Feature | Impact | Effort | Priority | Status |
|---------|--------|--------|----------|--------|
| Game mechanics (tile manipulation) | Critical | High | P0 | ✅ Complete |
| Level progression (50 levels) | Critical | High | P0 | ✅ Complete |
| Leaderboards | High | Medium | P1 | ✅ Complete |
| Notifications | High | Low | P1 | ✅ Complete |
| Ads & Monetization | Critical | High | P0 | ✅ Complete |
| Analytics | High | Medium | P1 | ✅ Complete |
| Multi-platform (iOS, Android, Web) | Critical | High | P0 | ✅ Complete |
| Dark mode / Accessibility | Medium | Low | P2 | ✅ Complete |
| Daily challenges | Medium | Medium | P2 | ✅ Complete |
| Social features (friends, sharing) | Medium | Medium | P2 | ✅ Complete |
| In-app purchases (premium tier) | Medium | Medium | P2 | ✅ Complete |

---

## 🚀 Launch & Rollout

### Pre-Launch (Weeks 1-2)

- ✅ Beta testing (internal + closed beta on TestFlight/Play)
- ✅ App Store listings (screenshots, description, keywords)
- ✅ ASO (App Store Optimization) keywords finalized
- ✅ PR outreach (tech blogs, puzzle game publications)

### Launch Day

- ✅ App Store + Google Play submission
- ✅ Web launch (Firebase Hosting)
- ✅ Social media announcement
- ✅ Monitoring for bugs/crashes

### Post-Launch (Weeks 3+)

- ✅ Monitor crash rates, performance metrics
- ✅ Respond to user reviews (address bugs, feedback)
- ✅ Marketing push (paid ads, influencers, Reddit)
- ✅ Iterate based on retention data (Level balance, difficulty curve)

---

## 📊 Phased Roadmap

### Phase 1: MVP Launch (Shipped ✅)
- ✅ Core gameplay (tile, operations, modulo)
- ✅ 50 levels with progression
- ✅ Leaderboards (global, personal)
- ✅ Multi-platform (iOS, Android, Web)
- ✅ Ads + IAP monetization
- ✅ Analytics & monitoring

**Target Metrics**: 10K DAU (M2), 25% D7 retention (M6)

---

### Phase 2: Engagement & Community (Q2 2026)
- 🟡 Daily challenges (themed weekly)
- 🟡 Tournament mode (limited-time, competitive)
- 🟡 Friend challenges ("Can you beat my score?")
- 🟡 Seasonal events (holiday-themed levels)
- 🟡 Progression streak/badges

**Target Metrics**: 50K DAU, 35% D7 retention, 10% premium conversion

---

### Phase 3: Creator Economy (Q3 2026)
- ⏸️ Custom level editor (advanced players create & share)
- ⏸️ User-generated content moderation
- ⏸️ Creator rewards (revenue share on plays)
- ⏸️ Level leaderboards (per creator)

**Target Metrics**: 500+ custom levels, top creators earning income

---

### Phase 4: AI & Personalization (Q4 2026)
- ⏸️ Difficulty adaptation (AI learns player skill)
- ⏸️ Personalized recommendations (next level suggestions)
- ⏸️ Hint system (show move if stuck 3+ attempts)
- ⏸️ Practice modes (specific mechanic mastery)

**Target Metrics**: Improved retention, higher premium conversion

---

## 🔒 Accessibility & Compliance

### WCAG 2.1 AA Compliance

| Guideline | Implementation | Status |
|-----------|-----------------|--------|
| Text contrast (4.5:1) | All text > 4.5:1 contrast ratio | ✅ |
| Font sizing (16px min) | Adjustable from 14-24px | ✅ |
| Color-blind friendly | Mode with colorblind palette | ✅ |
| Haptics optional | Toggle vibration in settings | ✅ |
| VoiceOver/TalkBack | Game state narrated | ✅ |
| Keyboard navigation | Full game playable with keyboard | ✅ |

### COPPA Compliance (Children <13)

- ✅ No direct personal data collection
- ✅ No third-party trackers (except privacy-focused analytics)
- ✅ Parental consent mechanism (if under 13)
- ✅ No ads targeting minors
- ✅ Data deletion on account deletion

### GDPR/CCPA Compliance

- ✅ Privacy policy (clear, transparent)
- ✅ User data export (GDPR Article 20)
- ✅ Right to be forgotten (account deletion)
- ✅ Cookie consent (if applicable in region)

---

## ✅ Success Metrics & KPIs

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Daily Active Users (DAU)** | 50K | Firebase Analytics |
| **Monthly Active Users (MAU)** | 250K | Firebase Analytics |
| **D7 Retention** | 45% | Cohort analysis |
| **D30 Retention** | 35% | Cohort analysis |
| **Launch Rating** | 4.5+ stars | App Store / Play Store |
| **Crash Rate** | <0.2% | Crashlytics |
| **Page Load (Web)** | <2.5s P95 | Web Analytics |
| **Monthly Recurring Revenue (MRR)** | $156K | Stripe |
| **Churn (Paid)** | <2% | Stripe |
| **Feature Adoption (Leaderboards)** | 70% | Analytics |
| **Feature Adoption (Daily Challenges)** | 75% | Analytics |

---

**Product Design Owner**: Mark Nelson  
**Last Updated**: February 12, 2026  
**Design Status**: ✅ Complete & Shipped
