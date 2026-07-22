# Implementation Summary

**Updated**: 2026-07-20
**Status**: current repository snapshot; earlier remediation narrative retired

## Implemented

- Falling-number gameplay is the native app's only routed game mode.
- Authentication, gamertag onboarding, profile infrastructure, sign-out/linking, and account deletion UI are present.
- Firebase Auth, Firestore, Functions, Analytics, Crashlytics, App Check, AdMob/UMP, and IAP are integrated in the mobile package.
- Global/daily/weekly leaderboard client contracts and Firestore reads are implemented, but they are not wired into the current falling gameplay screen.
- React marketing site has complete marketing, pricing, leaderboard, policy, cookie, and support routes.
- Website GTM/GA4 and AdSense disclosures match the source integration.
- Firebase projects are separated by development, staging, and production descriptors.
- Active CI validates Flutter, builds React, uploads iOS to TestFlight, and deploys Hosting/Functions.
- Cloud Functions source is separated into a private companion repo.
- CodeQL and Dependabot automation are active.

## Retained but not live

- The board-clearing `GameBoard`/`GameProvider` mode and its tests.
- Flutter `WebsiteScreen`, which is not the hosted React site.
- archived workflows and broad zero-touch/self-hosted-runner automation documents.
- Android delivery assets without an active Android CI job.

## Externally pending or unverifiable from source

- Current App Store review/public availability.
- Android Play Console setup.
- App Check enforcement and API-key restrictions.
- current secrets/certificate validity.
- GTM/GA4/AdSense dashboard-side configuration.
- DNS/Firebase custom-domain console state, although `modulosquares.com` is publicly reachable.
- private Functions implementation/test state in a normal public checkout.

## Primary risks

1. Legacy and live gameplay coexist and can cause documentation or implementation confusion.
2. Functions root scripts fail without the private checkout.
3. Firestore rules require a separate explicit deploy when changed.
4. Android is not covered by the active pipeline.
5. Web has no dedicated automated browser/accessibility tests.
6. External release/compliance controls require regular dated verification.

See [Current State](Current_State.md) and [Code Quality Analysis](Code_Quality_Analysis.md).
