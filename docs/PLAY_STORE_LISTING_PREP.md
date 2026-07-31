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

**Third correction round** — Codex re-raised the device-ID/optional dispute a second
time with a *different, correct* argument, and found several more gaps that only
surfaced by tracing what's actually wired into the live app vs. defined-but-unused
service code:

- **Device ID is REQUIRED, not optional, after all** — Codex's earlier argument (ad
  timing on first install) wasn't the real issue; the real issue is that Firebase
  Analytics assigns its own device/app-instance identifier for every session
  regardless of purchase state, with no opt-out. The `ad_service.dart` guard from the
  prior round is still correct and still worth having (a purchaser genuinely stops
  triggering *AdMob's* identifier collection), but it doesn't make the whole "Device or
  other IDs" category avoidable, since Analytics' own identifier isn't gated by it.
  Changed to REQUIRED, added the Analytics purpose.
- **Firebase UID is shared, not just collected** — same Analytics-sharing treatment
  already applied to app interactions/location; `setUserId` sends it to Google.
- **Approximate location and app interactions were missing the Advertising
  purpose** — AdMob independently uses IP-derived coarse location and measures ad
  impressions for its own purposes, separate from the app's own Analytics events.
  Added to both.
- **Diagnostics was missing Advertising and Fraud prevention purposes** — the Mobile
  Ads SDK's own diagnostic signals (load/render failures, latency) serve those
  purposes in addition to Crashlytics' app-functionality/analytics use.
- **The "Other actions" (gameplay events) declaration was wrong, not just
  incomplete.** Codex flagged (P2) that the shipped route (`main.dart` → `GameScreen`
  → `FallingModuloGameScreen`) has no `AnalyticsService` gameplay calls or
  `LeaderboardService` submissions. Checked directly: `GameProvider` — the class that
  defines all the gameplay logging (`logLevelComplete`, `logMove`, etc.) — is
  referenced nowhere outside its own file and its own integration test.
  `LeaderboardService.submitScore` / `submitDailyScore` / `submitWeeklyScore` have
  **zero call sites anywhere in the app.** Both are dead code from an earlier
  architecture, never wired into the live game. Consequence: removed the "Other
  actions" data type entirely (not just its App functionality purpose), and reverted
  the gamertag's (`PSL_NAME`) App functionality purpose added in the prior round —
  that was justified by the same false "sent with leaderboard submissions" premise.
  Gamertag purpose is Account management only, which is what's actually true.
- **Purchase history's Analytics purpose — considered, declined this round, accepted
  next round.** See below — turned out to be right after all, just not for the reason
  first argued.
- **Account deletion didn't clear the Analytics user ID** — `setUserIdFromAuth` never
  gets called with `null` (`AuthGate` returns `LoginScreen` instead of calling it), so
  the deleted user's Firebase UID stayed attached to all subsequent Analytics events.
  Added `AnalyticsService.clearUserId()`, called from both Sign Out and Delete Account.
- **Guest account deletion still had no real off-app path.** Documenting that
  "in-app is the only option" (prior round) doesn't satisfy the requirement that a
  shipped account type have *some* way to request deletion. Added a "Player ID" tile
  in Settings (guest accounts only) that shows and copies the Firebase UID, and
  updated [Support.tsx](../packages/web/src/pages/Support.tsx) to have guests send
  that ID as their deletion request.
- Also fixed: the deletion confirmation copy on the support page promised "leaderboard
  entries" would be deleted — inaccurate given leaderboard submission is dead code:
  there are none to delete. Removed that claim.

**Fifth correction round:**
- **Purchase history's Analytics purpose — reconsidered, accepted.** Declined last
  round for lack of code evidence, but `PrivacyPolicy.tsx` section 2.3 explicitly
  lists "In-app purchase events" as something Firebase Analytics collects in this
  app — a direct, already-published commitment, not speculation about SDK internals.
  The evidence was in the wrong file. Added, collected and shared.
- **Device ID was missing Firebase App Check's fraud-prevention purpose** —
  `main.dart` activates App Check (Play Integrity on Android, App Attest on iOS) on
  every production launch, sending a device/app attestation identifier independent of
  Analytics or AdMob. Added.
- **Analytics cleanup could block sign-out (P2)** — `clearUserId()` was awaited
  directly before `FirebaseAuth.signOut()`/inside the delete flow; an SDK error there
  would leave the user stuck signed in (sign-out path) or shown a false error after a
  successful deletion (delete-account path). Now wrapped in try/catch at both call
  sites — best-effort cleanup, never blocks the actual auth operation.
- **The deletion page claimed "immediate" deletion of "all associated data"** — not
  true; `PrivacyPolicy.tsx` already discloses that Analytics/crash data already sent is
  retained for 60–90 days regardless. Support.tsx now discloses that distinction and
  links to the privacy policy instead of overclaiming.
- **The guest "Player ID" deletion path (added last round) claimed more security than
  it has.** `packages/firestore-rules/firestore.rules` allows any authenticated
  user — including any other guest — to read the `gamertags` collection, which maps
  public gamertags to Firebase UIDs. A public gamertag is visible on the leaderboard,
  so anyone can look up another player's UID and submit a deletion request
  impersonating them; bare UID possession isn't proof of ownership. Support.tsx no
  longer claims we "verify" a guest account by Player ID — it now says deletion by
  Player ID is best-effort, not guaranteed, and that we may ask for corroborating
  details.
  **The Firestore rule itself is a pre-existing, real over-exposure issue independent
  of this PR — worth its own fix (the uniqueness check it supports only needs tag
  existence, not the whole document including its `uid` field), but changing it safely
  means moving gamertag-uniqueness checking server-side, which has enough blast radius
  (breaks gamertag creation for real users if done carelessly) to deserve its own PR
  with its own testing, not a rushed edit inside this one.**

**Also surfaced, not fixed here — flagged for a product decision:**
`PrivacyPolicy.tsx` (2.3 Analytics) explicitly promises "Level starts and completions"
are tracked via Firebase Analytics. That's the same `GameProvider` gameplay-logging
code confirmed dead above — the live, public privacy policy currently overstates what
the app actually collects. Either wire up real gameplay analytics logging from
`FallingModuloGameScreen`, or correct the privacy policy copy to match reality. This
also means the "compete on the leaderboard" claim in the app description and store
listing isn't backed by working code — `LeaderboardService.submitScore` is never
called, so no scores are ever actually submitted to the public leaderboard.
**Update 2026-07-31: this is now a tracked priority** — the user's next marketing
promotion depends on the leaderboard actually working. Plan: wire real score
submission into `FallingModuloGameScreen`, fix the `gamertags` Firestore
over-exposure alongside it, then correct/fulfil the Privacy Policy and Analytics
claims once they're true.

**Sixth correction round:**
- **User ID sharing was missing an App functionality purpose.**
  `GamertagService.isAvailable` fetches the *entire* `gamertags/{tag}` document
  (including its `uid` field) for every authenticated client's tag-availability
  check, even though the app only reads `.exists` — the raw UID still crosses the
  wire to another user's device. Added App functionality to `PSL_USER_ACCOUNT`'s
  sharing purposes alongside Analytics. Same root cause as the Firestore
  over-exposure flagged above — not fixed here for the same blast-radius reason.
- **The post-deletion local cleanup could still block sign-out (P2), one step
  earlier than the previous fix caught.** `SharedPreferences.getInstance()`/`.remove()`
  ran *before* the try/catch that protected the Analytics call — if either threw, it
  skipped straight to the outer catch, which reports a deletion error and leaves a
  stale authenticated session even though the backend `deleteAccount` call already
  succeeded. Restructured so only the `deleteAccount` call itself can produce an
  error message; everything after it (prefs cleanup, Analytics cleanup, sign-out) is
  unconditional best-effort cleanup that always ends in sign-out.

**Still needed:**
- Content rating questionnaire — no API found for this one, Play Console UI only.
- `remove_ads` in-app product — the API exists (`monetization.onetimeproducts`) but
  requires regional pricing/tax structure this session deliberately didn't guess at; do
  via Play Console's guided pricing UI or a carefully-constructed API call with an
  explicit base price and target regions confirmed first.
- Consider capturing 1-2 more gameplay screenshots at a higher level/later game state for
  variety (the ones here are all from an early, mostly-empty board).
