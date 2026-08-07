# Apple and Google promotional specifications

Verified against the linked official documentation on 2026-08-03. Store-console rules can change; recheck before a later submission.

## Production scope for this app

- iOS is currently iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), so an iPad screenshot or preview set is not required.
- Android is a phone-first layout. Tablet, Chromebook, TV, Wear, Automotive, and XR media are conditional and should be added only after those layouts are tested and intentionally distributed.
- Apple has no standard feature-graphic upload. Do not create Apple editorial PSDs unless Apple sends a Promotional Asset Request.
- Google’s retired 180 × 120 “promo graphic” is not a current listing field; the current banner-like asset is the 1024 × 500 feature graphic.

## Apple App Store

| Asset or field | Requirement | Current specification | Kit deliverable |
|---|---|---|---|
| App icon | Required in the build | 1024 × 1024, square/unmasked; do not pre-round corners | `apple/icon/app-icon-1024x1024.png` |
| iPhone screenshots | Required | 1–10 JPG/JPEG/PNG, no alpha; one accepted 6.9-inch size can scale down | 6 × 1320 × 2868 PNG |
| iPad screenshots | Conditional | 1–10 at 2064 × 2752 or 2048 × 2732 when the app runs on iPad | Not produced; current target is iPhone-only |
| iPhone app preview | Optional | 0–3; 15–30 sec; 886 × 1920 portrait or 1920 × 886 landscape; ≤500 MB; ≤30 fps | 886 × 1920 H.264 MP4 |
| App name | Required | 2–30 characters | 14 characters |
| Subtitle | Optional | ≤30 characters | 25 characters |
| Promotional text | Optional | ≤170 characters | 132 characters |
| Description | Required | ≤4,000 characters, plain text | 1,301 characters |
| Keywords | Required | ≤100 bytes | 86 bytes |
| Support URL | Required | Full URL and real contact information | Included |
| Privacy policy URL | Required | Public URL | Included |
| Marketing URL | Optional | Full URL | Included |
| IAP promotional image | Conditional | 1024 × 1024 JPG/PNG, 72 dpi, RGB, flattened, no rounded corners | Included for `remove_ads` |

Accepted 6.9-inch portrait screenshot sizes are 1260 × 2736, 1290 × 2796, and 1320 × 2868. This kit uses 1320 × 2868.

App preview H.264 guidance: progressive, up to High Profile Level 4.0, roughly 10–12 Mbps; stereo AAC at 256 kbps and 44.1 or 48 kHz when audio is present. App previews must primarily show captured app use and may use narration or explanatory overlays.

Official sources:

- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications
- https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- https://developer.apple.com/design/human-interface-guidelines/app-icons
- https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information/
- https://developer.apple.com/app-store/review/guidelines/

## Google Play

| Asset or field | Requirement | Current specification | Kit deliverable |
|---|---|---|---|
| Play Store icon | Required | Exactly 512 × 512; 32-bit sRGB PNG; ≤1,024 KB; full square, no pre-rounded outer corners or baked outer shadow | 512 × 512 PNG |
| Feature graphic | Required | Exactly 1024 × 500; JPEG or 24-bit PNG without alpha | 1024 × 500 RGB PNG |
| Phone screenshots | Required | 2–8; JPEG or 24-bit PNG without alpha; 320–3840 px; long side ≤2× short side | 6 × 1080 × 1920 RGB PNG |
| Game recommendation quality | Recommended | At least 3 actual-gameplay shots, consistently 9:16 at ≥1080 × 1920 or 16:9 at ≥1920 × 1080 | Met by the phone set |
| 7-inch tablet screenshots | Conditional | 4–8; 9:16 or 16:9; dimensions 1080–7680 px | Deferred until native tablet QA |
| 10-inch tablet screenshots | Conditional | Same as 7-inch tablet | Deferred until native tablet QA |
| Preview video | Optional, recommended for games | One direct public/unlisted, embeddable YouTube watch URL per localization; ads off; no URL parameters | 1920 × 1080 upload master + metadata |
| App name | Required | ≤30 characters | 14 characters |
| Short description | Required | ≤80 characters | 67 characters |
| Full description | Required | ≤4,000 characters and limited to currently available features | 1,304 characters |
| Graphic alt text | Recommended | ≤140 characters | Included per screenshot |

Google recommends showing actual gameplay within the first 10 seconds and keeping at least 80% of a game preview representative of the real experience. Only the first 30 seconds may autoplay muted. The 1024 × 500 feature graphic normally acts as the Play preview’s cover image.

Conditional assets intentionally omitted:

- Android TV listing banner (1280 × 720): app is not distributed as an Android TV app.
- Wear OS, Automotive, Chromebook-specific, and Android XR graphics: no corresponding product target is configured.
- Play Promotional Content primary image/Lottie/video: this requires a genuine scheduled event, offer, major update, or new-content campaign rather than evergreen launch marketing.

Official sources:

- https://support.google.com/googleplay/android-developer/answer/9866151?hl=en
- https://support.google.com/googleplay/android-developer/answer/9859152?hl=en
- https://developer.android.com/distribute/google-play/resources/icon-design-specifications
- https://support.google.com/googleplay/android-developer/answer/13393723?hl=en
- https://support.google.com/googleplay/android-developer/answer/12929944?hl=en
- https://developers.google.com/android-publisher/api-ref/rest/v3/AppImageType
