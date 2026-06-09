# Player Access Tiers

**Last Updated**: June 2, 2026
**Status**: Implemented behavior (current state)

---

## Purpose

This document defines what each player type can do in the current app, and clarifies monetization behavior.

It should be treated as the source of truth for:
- authentication gating,
- guest access expectations,
- ad display policy,
- paid entitlement behavior.

---

## Tier Definitions

### 1) Guest Player (Not Authenticated)

**Current status**: Not supported as a gameplay path.

Capabilities:
- Cannot enter gameplay from the default app flow.
- Cannot submit scores to leaderboard services.

Experience notes:
- Unauthenticated users are routed to the sign-in screen.
- Login copy currently states an account is required to play and sync progress.

---

### 2) Logged-In Player (Free)

**Current status**: Fully supported.

Capabilities:
- Can access and play the falling-tiles gameplay mode.
- Can progress levels normally.
- Can submit leaderboard entries through authenticated flows.
- Can purchase ad removal and restore purchases.

Monetization behavior:
- Interstitial ads are shown between levels.
- Ads are not intended to interrupt active play within a level.

---

### 3) Paid Logged-In Player (Ads Removed / Premium)

**Current status**: Fully supported for ad removal behavior.

Capabilities:
- Includes all logged-in free-player capabilities.
- Ad display is suppressed when ad removal entitlement is active.
- Restore purchases is available in settings.

Entitlement notes:
- `remove_ads` removes interstitial ads.
- `premium_version` implies ad removal.
- No additional premium gameplay abilities are currently enforced beyond ad removal.

---

## Policy Summary

Current policy in active gameplay:
- Ads should be displayed between levels for logged-in free players.
- Ads should not display for paid players with ad-removal entitlement.
- The app currently requires account sign-in to play; guest gameplay is not part of the active user flow.

---

## Product/Engineering Implications

1. If guest mode is desired later, explicit scope is required for:
   - local-only progress behavior,
   - leaderboard restrictions,
   - conversion prompts to account creation,
   - ad policy differences for guests.

2. If premium is expanded beyond ad removal, document each premium feature and enforce it consistently in UI, services, and tests.

3. Keep this document synchronized with:
   - authentication copy and routing,
   - ad trigger points,
   - purchase entitlement handling.
