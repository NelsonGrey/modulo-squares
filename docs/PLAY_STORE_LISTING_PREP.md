# Play Store Listing Prep — Content Rating & Data Safety Draft

Drafted 2026-07-26 for the initial Google Play Console app record (Go Live Runbook Phase 2.3).
These are drafts to paste into the console — verify against the actual questionnaire wording,
which changes over time, before submitting.

## Content Rating Questionnaire (IARC)

App category: **Game**. Expected outcome: **Everyone / PEGI 3**.

| Question | Answer |
|---|---|
| Violence | None |
| Blood | None |
| Sexual content / nudity | None |
| Profanity / crude humor | None |
| Controlled substances (drugs/alcohol/tobacco) | None |
| Gambling (simulated or real money) | None |
| Fear / horror themes | None |
| User-generated text (gamertags) | Yes — see note below |
| In-app purchases | Yes (`remove_ads`, $2.99 one-time) |
| Users can interact with each other | No direct messaging/chat. There is a public leaderboard showing other players' self-chosen gamertags and scores — no free-text chat between users. |
| Shares user's location | No |
| Digital purchases | Yes |

**Note on gamertags**: players choose a free-text display name (`GamertagService`) shown
publicly on the leaderboard. It's not moderated server-side as of 2026-07-26. Flag this
to whoever fills out the questionnaire — depending on the current IARC wording this can
affect the "user-generated content" answer, and separately it's worth a product decision
on whether to add a profanity filter before launch.

## Data Safety Form

Based on what the app actually does (`packages/mobile/lib/core/services/`):

**Data collected and/or shared:**

| Category | Data type | Collected? | Shared? | Purpose |
|---|---|---|---|---|
| Personal info | Email address | Yes (if user signs in with Email/Google/Apple) | No | Account management, authentication |
| Personal info | Name | Yes (if provided via Google/Apple sign-in) | No | Account management |
| Identifiers | User ID (Firebase UID) | Yes | No | Account management, app functionality |
| App activity | App interactions (Firebase Analytics) | Yes | Yes — Google (analytics provider) | Analytics |
| App info and performance | Crash logs (Firebase Crashlytics) | Yes | Yes — Google | Analytics, app functionality |
| Device or other IDs | Advertising ID (AdMob) | Yes | Yes — Google/AdMob ad network | Advertising or marketing |

**Not collected**: financial info, health/fitness, location, contacts, photos/videos/audio,
web browsing history, messages.

**Security practices to confirm/declare:**
- [ ] Data is encrypted in transit (Firebase/Firestore — yes by default, HTTPS/TLS)
- [ ] Users can request data deletion — the app has a "Delete Account" option in Settings
      ([falling_modulo_game_screen.dart](../packages/mobile/lib/features/game/falling_modulo_game_screen.dart)),
      so answer **Yes** to "Can users request data deletion"

**Target audience / Ads:**
- Contains ads: **Yes** (AdMob interstitials, removable via IAP)
- Target age group: the puzzle-game content itself is all-ages, but given AdMob + accounts +
  a public leaderboard, treat this as **not primarily child-directed** — do not mark it as
  designed for children under 13 unless that's an intentional decision, since that triggers
  additional Play Families Policy requirements (no behavioral ads, etc.) that the current
  AdMob setup isn't configured for.

## Store Listing Assets

Generated 2026-07-26 from a real device (Samsung Galaxy S24, RFGL53EM3RN), release build,
cropped to 1080×2120 (under Play's 2:1 max screenshot aspect ratio):
`output/imagegen/play_store/`
- `modulo-squares-phone-01-login.png` — sign-in screen
- `modulo-squares-phone-02-howtoplay.png` — pre-game "how to play" / start screen
- `modulo-squares-phone-03-gameplay.png` — live gameplay with a combo bonus
- `modulo-squares-phone-04-settings.png` — settings dialog showing the $2.99 IAP price
- `modulo-squares-icon-512.png` — 512×512 app icon (reused from the web favicon asset)

- `modulo-squares-feature-graphic-1024x500.png` — feature graphic (1024×500, required),
  generated 2026-07-31 via an HTML/CSS layout rendered through Playwright at exact
  dimensions (24-bit RGB, no alpha, confirmed). Uses the actual brand palette
  (`primary`/`secondary` blue-indigo gradient from the web site, `#1A1A2E`/`#4CAF50`
  navy/green from the mobile app icon) and depicts the real game mechanic — an "18" tile
  falling toward a highlighted "6" bucket (18 mod 6 = 0) — rather than a generic banner.

**Update (2026-07-31): title, both descriptions, icon, feature graphic, and all 4
screenshots are now live in Play Console** — pushed via the Android Publisher API
using `google-play-console-service@modulo-squares-prod.iam.gserviceaccount.com`, not
manually. See [GO_LIVE_RUNBOOK.md](GO_LIVE_RUNBOOK.md) §2.3c for how and what to watch
out for if doing this again.

**Update (2026-07-31): Data Safety declaration submitted, live.** Correction to the
"no API" note below — there is an API:
`androidpublisher.applications.dataSafety` (POST, body `{"safetyLabels": "<csv>"}`,
takes the raw CSV in [Play's Data Safety export/import
format](https://support.google.com/googleplay/android-developer/answer/10787469)).
First submission attempt 400'd with `Response missing for PSL_DATA_DELETION_URL` —
Google requires this in addition to `PSL_ACCOUNT_DELETION_URL`; both point at
`https://modulosquares.com/support`, which now has an explicit account/data-deletion
section (see below) rather than just a generic contact form. Full CSV committed at
[play-store-data-safety-declaration.csv](play-store-data-safety-declaration.csv).

**Correction round (same day, via `@codex review`):** the first submitted version
undercounted what the app actually collects. Codex found 10 real gaps by reading the
code directly — all verified and fixed before resubmitting (final submission also
confirmed HTTP 204):
- **Purchase history** wasn't declared — `PurchaseService._completePurchase` sends
  product ID, receipt, and transaction ID to the `validatePurchase` Cloud Function on
  every `remove_ads` purchase/restore.
- **Email was marked required** — wrong, since `Continue as Guest`
  (`signInAnonymously()`) never collects it. Now OPTIONAL, and anonymous guest
  accounts are declared under account creation methods (`PSL_ACM_OTHER`).
- **Gamertag (Name) was marked optional** — wrong, `GamertagScreen` is mandatory for
  every account including guests before the game is reachable. Now REQUIRED.
- **Advertising ID was declared OPTIONAL but wasn't actually avoidable** —
  `AdService.loadInterstitial()` requested ads regardless of purchase state; only
  `showInterstitial()` checked `adsRemoved`. Fixed in code
  ([ad_service.dart](../packages/mobile/lib/core/services/ad_service.dart)) so
  purchasers stop triggering ad requests entirely, which is what makes OPTIONAL true.
- **User ID's Analytics purpose was missing** — `AuthGate` → `setUserIdFromAuth` feeds
  the Firebase UID straight into `FirebaseAnalytics.setUserId`.
- **Approximate location (country) wasn't declared** — Firebase Analytics derives it
  for every session with no opt-out; already disclosed in `PrivacyPolicy.tsx` but
  missing from the CSV.
- **Diagnostics wasn't declared separately from crash logs** — Crashlytics attaches
  device/OS technical context to every report, also already disclosed in the privacy
  policy.
- **Gameplay events weren't declared as "Other actions"** — `AnalyticsService` sends
  level results, scores, ranks, and badges beyond generic app interactions;
  `LeaderboardService` submits scores.
- **The deletion URL pointed at a generic contact form** with no deletion-specific
  option or instructions — [Support.tsx](../packages/web/src/pages/Support.tsx) now has
  an explicit "Delete your account or data" section and a dedicated topic.

Remaining answers reflect actual app behavior verified against code, not assumed from
the earlier draft table above (now fully superseded by the CSV): Name/Email/User ID
collected only, not shared; Crash logs and Diagnostics collected only, not shared
(Crashlytics treated as a data processor, not shared with Google for Google's own
purposes); App interactions, Other actions, Approximate location, and Advertising ID
all collected AND shared with Google.

**Second correction round** (same `@codex review`, against the fix commit itself) found
4 more gaps, 3 fixed:
- Gamertag (Name) purpose was missing App functionality — it's sent as `playerName`
  with every leaderboard submission, not just used for account management. Fixed in
  the CSV.
- Guest account deletion instructions were incomplete — anonymous accounts have no
  email, so the "email us to verify" path doesn't work for them.
  [Support.tsx](../packages/web/src/pages/Support.tsx) now says explicitly that in-app
  deletion is the only option for guests, and doesn't promise something (email
  verification, automatic inactive-account cleanup) that isn't actually true or
  verifiable from this repo.
- Account deletion didn't clear local progress — `_deleteAccount` in
  [falling_modulo_game_screen.dart](../packages/mobile/lib/features/game/falling_modulo_game_screen.dart)
  called the backend `deleteAccount` function and signed out, but never cleared the
  `fallingMode.highScore` SharedPreferences key, so the confirmation dialog's promise
  to delete "saved progress" wasn't fully true. Now cleared as part of deletion.

**Not changed, considered:** Codex's device-ID finding argued Advertising ID can't be
OPTIONAL because a brand-new user's very first ad load happens before they've had any
chance to purchase `remove_ads`. That's true but not a bug — `PurchaseService.initialize()`
is awaited before the first `loadInterstitial()` call in `main.dart`, so a *returning*
purchaser's cached entitlement is loaded first and the guard correctly stops ad
requests from that point on. OPTIONAL describes "the user has a way to stop this,"
matching how Play's Data Safety schema is used across the ad-supported app ecosystem —
it doesn't mean collection can never happen for even a moment before a user's first-ever
purchase decision. Left as OPTIONAL.

**Still needed:**
- Content rating questionnaire — no API found for this one, Play Console UI only.
- `remove_ads` in-app product — the API exists (`monetization.onetimeproducts`) but
  requires regional pricing/tax structure this session deliberately didn't guess at; do
  via Play Console's guided pricing UI or a carefully-constructed API call with an
  explicit base price and target regions confirmed first.
- Consider capturing 1-2 more gameplay screenshots at a higher level/later game state for
  variety (the ones here are all from an early, mostly-empty board).
