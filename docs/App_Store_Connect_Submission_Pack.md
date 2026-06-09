# App Store Connect Submission Pack

**App**: Modulo Squares  
**Prepared**: June 2, 2026  
**Version Target**: 0.0.2+3

This document is a copy/paste pack for App Store Connect submission.

Use this in order:
1. Metadata fields
2. What's New
3. App Review Information
4. Compliance forms
5. Screenshot/asset checklist

---

## 1. App Information (Copy/Paste)

### App Name
```text
Modulo Squares
```

### Subtitle
```text
Falling modulo puzzle challenge
```

### Promotional Text
```text
Master modulo arithmetic in a fast, strategic falling-tiles puzzle. Fill the 10x10 progress grid, climb levels, and compete on leaderboards.
```

### Description
```text
Modulo Squares is a strategy puzzle game built around modulo arithmetic and quick decision-making.

How it works:
• Numbered tiles fall into your lanes
• Position each tile and resolve modulo outcomes
• Success fills your 10x10 progress grid
• Misses remove progress based on the remainder value
• Complete the full grid to clear the level

Core features:
• Falling-tiles gameplay with Start/Pause control
• Gradual speed progression across levels
• 10x10 level-completion progress system
• Account-based play with synchronized progress
• Leaderboard competition
• In-app purchase option to remove ads

Designed for players who enjoy logical puzzles, numbers, and high-skill replayability.
```

### Keywords (comma-separated, under 100 chars)
```text
modulo,puzzle,math,logic,numbers,brain,strategy,arcade,falling,leaderboard
```

### Support URL
```text
REPLACE_WITH_SUPPORT_URL
```

### Marketing URL
```text
REPLACE_WITH_MARKETING_URL
```

### Privacy Policy URL
```text
REPLACE_WITH_PRIVACY_POLICY_URL
```

### Copyright
```text
2026 Mark Nelson
```

### Primary Category
```text
Games
```

### Secondary Category
```text
Puzzle
```

---

## 2. What's New (Version 0.0.2)

```text
Finalized the core falling-tiles gameplay experience.

• Added explicit Start/Pause controls (no auto-start)
• Introduced 10x10 progress-grid level completion
• Tuned pacing with a slower start and gradual speed increase by level
• Updated modulo outcome behavior: success fills progress, misses reduce by remainder
• Refined ad behavior to show between levels for free users
• Improved stability and release readiness for iOS
```

---

## 3. App Review Information (Copy/Paste)

### Contact First Name
```text
REPLACE_FIRST_NAME
```

### Contact Last Name
```text
REPLACE_LAST_NAME
```

### Contact Phone
```text
REPLACE_PHONE
```

### Contact Email
```text
REPLACE_EMAIL
```

### Demo Account Required?
```text
No
```

If App Review requests credentials, paste this note:
```text
This app supports account sign-in using platform authentication providers shown on launch (Apple, Google, Email). No pre-provisioned test account is required for basic gameplay verification.
If your review flow requires a fixed account, contact us at REPLACE_EMAIL and we will provide one immediately.
```

### Notes for App Review
```text
Review focus for this version:
1) Falling-tiles gameplay with explicit Start/Pause control.
2) Level completion via full 10x10 progress grid fill.
3) Modulo result behavior: successful placements add progress, failed placements remove progress by remainder.
4) Ad behavior: interstitials are shown between levels for free users; users with the remove-ads purchase do not see interstitials.
5) Account sign-in is required before gameplay.

In-App Purchase SKU used:
- remove_ads (non-consumable)

If additional test guidance is needed, contact REPLACE_EMAIL.
```

---

## 4. Compliance Form Deliverables

## 4.1 Export Compliance

Use these default answers unless legal/security review says otherwise:

### Uses encryption?
```text
Yes
```

### Is the app using only standard encryption within Apple's operating system and SDKs (for example HTTPS/TLS) and not proprietary crypto?
```text
Yes
```

### Is exemption documentation required?
```text
No
```

---

## 4.2 App Privacy Nutrition Label Prep

Populate App Store Connect according to your actual implementation and policy.

Suggested starter mapping to validate with engineering/legal:

### Contact Info
```text
Not collected unless user provides support email directly outside app flow.
```

### Identifiers
```text
Account identifiers may be processed for authentication and account functionality.
```

### Purchases
```text
Purchase status is processed for remove-ads entitlement.
```

### Usage Data
```text
Analytics events may be collected to improve gameplay quality and stability.
```

### Data linked to user
```text
Authentication-linked leaderboard/account functionality.
```

### Data used for tracking
```text
REPLACE_WITH_YES_OR_NO_BASED_ON_AD_IMPLEMENTATION_AND_POLICY
```

Important: Ensure this section exactly matches your privacy policy and SDK behavior.

---

## 4.3 Age Rating Answers (Starter)

Use these defaults unless content changed:

```text
Cartoon/Fantasy Violence: None
Realistic Violence: None
Profanity or Crude Humor: None
Mature/Suggestive Themes: None
Alcohol/Tobacco/Drugs: None
Gambling: None
Unrestricted Web Access: No
User-Generated Content: No
```

---

## 5. Screenshots and Supporting Artifacts

You cannot submit without screenshots. Use this capture script and naming plan.

## 5.1 Required iPhone Screenshot Sets

At minimum, prepare these sets in App Store Connect:
- 6.7-inch display
- 6.5-inch display (if requested by your ASC configuration)
- 5.5-inch display (if requested by your ASC configuration)

Use at least 5 screenshots per required iPhone size.

## 5.2 Screenshot Shot List (Game-Accurate)

Capture these scenes in this order:

1. Login Screen (account-required entry)
   - Message that sign-in is required
   - Apple/Google/Email options visible

2. Falling Gameplay Start State
   - Grid visible
   - Start button visible
   - Game paused/not auto-started

3. Active Falling Gameplay
   - Tile in motion
   - lane controls visible
   - score and level visible

4. Modulo Success State
   - clear successful placement
   - progress grid increases

5. Modulo Failure/Deficit State
   - failed remainder behavior visible
   - deficit indication visible

6. Near-Complete Progress Grid
   - 10x10 grid mostly filled
   - high tension state before completion

7. Level Completion Screen/Transition
   - completed level result
   - transition state between levels

8. Leaderboard Screen
   - ranking context visible

9. Settings with Remove Ads Option
   - remove ads purchase CTA visible for free user

10. Post-Purchase No-Ads Confirmation (if available)
   - ads removed/purchase restored state

## 5.3 Screenshot Overlay Captions (Optional)

Use one line per screenshot in order:

```text
Think fast. Place with precision.
Start when ready. Master the fall.
Solve modulo in real time.
Success builds your 10x10 grid.
Mistakes cost progress.
Fill every square to clear the level.
Advance and accelerate.
Compete on the leaderboard.
Upgrade to remove ads.
Pure puzzle flow, no interruptions.
```

## 5.4 Screenshot File Naming (Recommended)

```text
ios_67_01_login.png
ios_67_02_start_state.png
ios_67_03_active_gameplay.png
ios_67_04_success.png
ios_67_05_failure_deficit.png
ios_67_06_near_complete_grid.png
ios_67_07_level_complete.png
ios_67_08_leaderboard.png
ios_67_09_remove_ads_settings.png
ios_67_10_no_ads_state.png
```

Repeat same sequence for other required device sizes.

## 5.5 Additional Required Artifacts

- App icon: 1024x1024 (no alpha)
- Optional app preview video (recommended)
- Support URL reachable and live
- Privacy Policy URL reachable and live

---

## 6. Submission Day Final Checklist

- [ ] Build number in App Store Connect matches uploaded build (`0.0.2+3`)
- [ ] Metadata pasted from this pack and proofread
- [ ] All required screenshot slots filled for required device classes
- [ ] Privacy answers reviewed by legal/product owner
- [ ] Export compliance completed
- [ ] Age rating completed
- [ ] App Review notes included
- [ ] In-app purchase `remove_ads` attached (if required by review flow)
- [ ] TestFlight internal smoke pass complete

---

## 7. Quick Copy Bundle

If you only need the highest-value fields quickly:

### Bundle A: Core Listing
```text
Name: Modulo Squares
Subtitle: Falling modulo puzzle challenge
Keywords: modulo,puzzle,math,logic,numbers,brain,strategy,arcade,falling,leaderboard
```

### Bundle B: Promo + What's New
```text
Promotional Text:
Master modulo arithmetic in a fast, strategic falling-tiles puzzle. Fill the 10x10 progress grid, climb levels, and compete on leaderboards.

What's New:
Finalized the core falling-tiles gameplay experience.
• Added explicit Start/Pause controls (no auto-start)
• Introduced 10x10 progress-grid level completion
• Tuned pacing with a slower start and gradual speed increase by level
• Updated modulo outcome behavior: success fills progress, misses reduce by remainder
• Refined ad behavior to show between levels for free users
• Improved stability and release readiness for iOS
```

### Bundle C: Review Notes
```text
Review focus for this version:
1) Falling-tiles gameplay with explicit Start/Pause control.
2) Level completion via full 10x10 progress grid fill.
3) Modulo result behavior: successful placements add progress, failed placements remove progress by remainder.
4) Ad behavior: interstitials are shown between levels for free users; users with the remove-ads purchase do not see interstitials.
5) Account sign-in is required before gameplay.

In-App Purchase SKU:
- remove_ads (non-consumable)
```
