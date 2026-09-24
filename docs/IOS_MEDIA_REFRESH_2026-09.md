# iOS media refresh — September 2026

## Status

September 23: five native 1320×2868 iPhone screenshots were captured, visually
reviewed, and exported as opaque sRGB PNGs. Four 23-second palette gameplay
sources and a 66-second Settings/Appearance tour were also captured. The
36-second Cedar-narrated pilot was rendered in landscape and vertical layouts
with captions. It remains review evidence until the owner approves the voice,
script, and pacing. Existing media remains intact.

## App Store capture set

Capture the current production gameplay widget in all four selectable palettes:
Deep Ocean, Arcade Neon, Warm Sunset, and Candy Pop. Slate Mono exists in code
but is excluded from the picker and must not be advertised as selectable.
Add a screenshot of the actual appearance picker and one clear gameplay/rules
screen after visual review. Target a native supported large iPhone size; do not
stretch smaller captures. Export RGB PNGs without alpha.

Apple specifications checked September 23, 2026:
https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
Accepted 6.9-inch portrait sizes include 1260×2736, 1290×2796, and 1320×2868.
Apple permits one to ten screenshots. Check supported iPad requirements if the
submitted binary supports iPad.

After accepting the Xcode license and booting the selected simulator:

```bash
PROMO_IOS_SIMULATOR_UDID=<udid> bash scripts/store-promo/capture-ios-palettes.sh
```

The script saves four native screenshots and four short gameplay sources under
`media-library/_source/ios-refresh-YYYY-MM-DD/captures/`. These are review sources, not
upload-ready exports. The capture uses local deterministic gameplay and does
not prove live account, purchase, or leaderboard behavior.

The reviewed App Store exports are in
`media-library/05-store-listings/apple/screenshots/iphone-6.9/refresh-2026-09-23/`.
They preserve the simulator's native 1320×2868 dimensions and contain no alpha.

## Feature video sequence

| Video | Footage needed | Suggested length |
|---|---|---|
| Choose your appearance (pilot) | Settings picker, selection, moving gameplay in each of the four palettes | 35–50 seconds |
| Your first clean landing | Real lane movement, divisor choice, successful landing | 45–60 seconds |
| Build a combo | Consecutive successful landings, visible combo and progress changes | 35–50 seconds |
| Avoid costly landings | Dead bucket and remainder behavior, recovery | 35–50 seconds |
| Make the game your own | Actual difficulty controls, pause and resume | 35–50 seconds |
| Account and gamertag | iOS sign-in choices, account creation and gamertag screens using fictional details | 45–60 seconds |

Capture account tutorials with `YOUTUBE_CAPTURE_PLATFORM=ios`; the historical
tutorial target defaults to Android for earlier Google Play work. Its injected
authentication callbacks simulate completion; do not describe them as evidence
of a successful live authentication transaction. Leaderboard footage needs a
working separately verified session; the local store capture has a placeholder
that must never appear in final media.

## Appearance pilot narration

The generation script and exact text are in
`scripts/store-promo/appearance-pilot.json`. Six WAV segments and per-segment
provenance are under
`media-library/_source/ios-refresh-2026-09-23/narration/`. The voice is OpenAI
Cedar, generated with `gpt-4o-mini-tts`; it is not a human recording.
The generated speech was transcribed for text verification; subjective voice
quality and final picture pacing remain part of the pilot review.

The review masters are in
`media-library/_hold/review-evidence/appearance-pilot-2026-09-23/`. Both are
H.264/yuv420p at 30 fps with 48 kHz stereo AAC, measured at -16.3 LUFS. No
freeze events longer than 1.5 seconds were detected. They are deliberately not
in an upload-facing directory until pilot approval.

See [the feature scripts](IOS_FEATURE_VIDEO_SCRIPTS.md) for the seven-episode
series, including the current highest-divisor bonus.

Sync each palette name to its visible picker selection and moving gameplay.
Confirm the exact visible settings labels before recording the final script.
Use a relaxed conversational delivery. AI narration, if selected, must be
identified as AI-generated; it must not be described as a real human recording.
Review a short voice sample and the complete pilot before batch rendering.

## Delivery and verification

Prepare a 1920×1080 YouTube master and 1080×1920 social version for each approved
video, plus captions, a thumbnail, title, description, and short linking copy.
Keep the complete board legible in both layouts. Use real app motion rather than
static screenshots held under narration. Avoid private account information,
debug overlays, placeholder screens, unverified purchase claims, and OS prompts.

Verify dimensions, video/audio streams, frame rate, motion, speech timing,
caption accuracy, and beginning/end frames. Keep narration provenance with the
files. Refresh media-library inventories/checksums after final exports. Upload
and public posting are separate actions and have not been performed.
