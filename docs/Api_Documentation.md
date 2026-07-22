# API Documentation

**Updated**: 2026-07-20
**Transport**: Firebase callable Functions

Cloud Functions source is private and is not tracked in this repository. This document defines the contracts observed in the Flutter client. Verify validation, App Check enforcement, rate limits, deletion coverage, and receipt verification against `NelsonGrey/modulo-squares-functions` before changing server behavior.

All calls use the Firebase Functions SDK and therefore carry Firebase Auth context when a user is signed in.

## `startScoreSession`

Creates a short-lived server score session.

Request:

```json
{
  "mode": "global | daily | weekly",
  "challengeId": 20260720,
  "weekId": 202629
}
```

`challengeId` is sent only for daily mode and `weekId` only for weekly mode.

Expected response:

```json
{
  "sessionId": "opaque-id",
  "expiresAt": 1784567890000
}
```

The client caches the session by mode/challenge/week and refreshes it when fewer than five seconds remain.

## `submitScore`

Submits a global score.

```json
{
  "playerName": "Player_1",
  "score": 12345,
  "level": 1,
  "scoreSessionId": "opaque-id",
  "clientTime": 1784567890000
}
```

Client validation: name length 1-50; score 0-999999. `level` is currently sent as `1` by the service regardless of falling-mode level, so server consumers should not treat it as an accurate run-level metric.

## `submitDailyScore`

Submits a daily challenge score.

```json
{
  "challengeId": 20260720,
  "playerName": "Player_1",
  "score": 12345,
  "level": 1,
  "scoreSessionId": "opaque-id",
  "clientTime": 1784567890000
}
```

Client validation also requires a positive challenge ID.

## `submitWeeklyScore`

Submits the player's weekly best score.

```json
{
  "weekId": 202629,
  "playerName": "Player_1",
  "score": 12345,
  "level": 1,
  "scoreSessionId": "opaque-id",
  "clientTime": 1784567890000
}
```

Client validation also requires a positive week ID.

## `validatePurchase`

Validates a StoreKit or Google Play non-consumable purchase.

```json
{
  "productId": "remove_ads",
  "purchaseToken": "platform-receipt-or-token",
  "transactionId": "platform-transaction-id",
  "platform": "ios | android"
}
```

Expected response:

```json
{
  "entitlements": {
    "adsRemoved": true,
    "premiumUnlocked": false
  }
}
```

Supported product IDs in the mobile client are `remove_ads` and `premium`. Only `remove_ads` is represented as a current store offering.

## `getEntitlements`

Request: no payload.

Expected response:

```json
{
  "adsRemoved": true,
  "premiumUnlocked": false
}
```

Used after purchase restoration and initialization to reconcile local state with server authority.

## `deleteAccount`

Request: no payload.

Expected behavior: delete user-related Firestore data and then delete the authenticated Firebase Auth user. The UI signs out locally after a successful call. The operation is permanent and requires a confirmation dialog.

## Error handling

Callable failures surface as `FirebaseFunctionsException` values. The client logs them through `ErrorHandler`, shows a user-facing message, and exposes retry actions for leaderboard submission. Server code should use specific callable error codes such as `unauthenticated`, `invalid-argument`, `permission-denied`, `failed-precondition`, and `resource-exhausted`.

Never return raw provider receipts, secrets, stack traces, or privileged internal data to clients.

## Local Functions checkout

```bash
git clone --branch develop \
  https://github.com/NelsonGrey/modulo-squares-functions.git \
  packages/functions

cd packages/functions
npm install
npm test
```

Use `main` for production source and `staging` for staging. `packages/functions` is ignored by the public repository.

## Deployment

The active CI pipeline checks out the matching private branch and deploys with the environment-specific Firebase configuration. Manual deployment requires an explicit project:

```bash
firebase deploy --only functions --project modulo-squares-dev
```

Do not rely on old REST paths documented in historical files; the current clients use callable Functions.
