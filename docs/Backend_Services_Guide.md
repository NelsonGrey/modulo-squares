# Backend Services Guide

**Updated**: 2026-07-20

Modulo Squares uses managed Firebase services rather than a tracked custom server in this public repository.

## Services

| Service | Use |
|---|---|
| Firebase Auth | Apple, Google, and email/password identity |
| Cloud Firestore | player records, gamertags, leaderboards, purchases, entitlements |
| Cloud Functions v2 | score sessions/submission, receipt validation, entitlement reads, account deletion |
| Firebase Analytics | mobile product events |
| Crashlytics | mobile crash reporting |
| Firebase App Check | client attestation integration; enforcement is console-controlled |
| Firebase Hosting | React site deployment |
| AdMob/UMP | native advertising and consent |

## Public/private source boundary

The Functions implementation is in private repository `NelsonGrey/modulo-squares-functions`. CI clones its matching environment branch into ignored path `packages/functions` immediately before install/deploy.

The public repository contains:

- client call sites and request/response expectations;
- Firestore security rules;
- Firebase environment descriptors;
- CI checkout/deployment wiring.

It does not prove server-side validation or cleanup details. Review the private repository for those claims.

## Client access model

- Public clients can read leaderboard collections.
- Signed-in clients own their `users`, `user_profiles`, and `game_stats` documents.
- Clients can create a normalized gamertag claim but cannot update/delete the index directly.
- Clients cannot write leaderboards, purchases, or entitlements.
- Privileged operations use authenticated callable Functions.

## Leaderboards

The client requests a short-lived `startScoreSession` token before submitting global, daily, or weekly scores. Reads use Firestore snapshots; global results are cached locally for five minutes. Weekly ranking uses project-specific seven-day buckets beginning January 1.

## Purchases

`PurchaseService` observes the platform purchase stream and sends the platform receipt/token to `validatePurchase`. The server returns `adsRemoved` and `premiumUnlocked` entitlements. Restore calls the store and then `getEntitlements`.

Local SharedPreferences flags improve startup UX but are not authoritative.

## Account deletion

Settings calls `deleteAccount` after explicit confirmation. The server is expected to remove related Firestore records and Firebase Auth identity. Treat compliance as verified only after testing the private implementation against all current collections.

## Deployment

Use CI for normal deployment. For an authorized manual deploy:

```bash
git clone --branch develop \
  https://github.com/NelsonGrey/modulo-squares-functions.git \
  packages/functions
cd packages/functions
npm install
cd ../..
firebase deploy --only functions --project modulo-squares-dev
```

Use environment-appropriate branches/projects and inspect the companion repo's own README/tests first.

See [API Documentation](Api_Documentation.md), [Database Schema](Database_Schema.md), and [Security](Security.md).
