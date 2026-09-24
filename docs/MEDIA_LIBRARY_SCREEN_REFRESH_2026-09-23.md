# Media-library screen refresh — September 23, 2026

## Completed static-image scope

The seven screen states that feed the promotion kit were recaptured from the
current production Flutter widgets: active gameplay, pre-game rules, scored
combo, pause, How to Play, Gameplay settings, and Purchases. The capture build
uses deterministic values, Normal difficulty, Deep Ocean, no authentication,
and no network writes.

The refreshed sources rebuilt:

- six 1320×2868 App Store screenshots and the Fastlane screenshot mirror;
- six 1080×1920 Google Play screenshots;
- the square and portrait evergreen screen-image sets;
- platform-ready Facebook, Instagram, Reddit, Threads, and X copies derived
  from those evergreen images;
- six landscape video title plates and three cross-platform social images.

Legacy native sources remain under
`output/media-library-screen-refresh-2026-09-23/legacy-promo-captures/`.

## Android source limitation

The current Android build is blocked before launch by the generated Firebase
App Check registration under the repository's current AGP/Kotlin toolchain.
The class named in `GeneratedPluginRegistrant.java` is not present on the Java
compile classpath even though the plugin source exists. Java 21 does not resolve
that plugin mismatch.

For this static refresh, the Android source images use the current shared
Flutter application surfaces captured on iOS, fitted between preserved native
Android status and navigation chrome. They do not add platform-specific UI or
claims. Replace them with direct Android captures after the plugin registration
problem is repaired. `capture-current-screen-library.sh` performs this
composition by default and retains an explicit opt-in native Android path.

## Validation boundary

The rebuilt media library passes both validators: 252 upload-facing files and
159 managed assets across seven platforms. The promotion-kit validator passes
all 31 current non-video deliverables. Its five failures are older video
masters whose renderer or title-plate inputs have changed; they are a separate
video refresh and are not evidence against the static image set.
