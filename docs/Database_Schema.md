# Database Schema

**Updated**: 2026-07-20
**Database**: Cloud Firestore

This document describes collections referenced by the public clients and public Firestore rules. Server-only fields and cleanup logic must be verified in the private Functions repository.

## Collections

### `users/{uid}`

Primary player record. Known client fields include:

```text
gamertag: string
displayName: string?      # profile path
email: string?
photoUrl: string?
createdAt/updatedAt: timestamp? or serialized date fields, depending on writer
```

Access: signed-in users can read and write only their own document.

### `gamertags/{normalizedTag}`

Case-insensitive uniqueness index.

```text
uid: string
tag: string
```

The document ID is the lowercase gamertag. Any authenticated user can read availability. Creation requires `resource.data.uid == request.auth.uid`. Public updates and deletes are denied.

### `user_profiles/{uid}`

Owner-scoped profile document retained for compatibility with profile features.

Access: signed-in owner read/write.

### `game_stats/{uid}`

Owner-scoped game statistics/progress document.

Access: signed-in owner read/write.

### `modulo_leaderboard/{uid-or-entry-id}`

Global best-score rows. Client readers expect:

```text
playerName: string
score: number
level: number?
updatedAt: timestamp?
```

Access: public read; client write denied. Callable Functions are authoritative.

### `modulo_daily_leaderboard/{challengeId}/scores/{uid-or-entry-id}`

Daily challenge scores.

```text
playerName: string
score: number
level: number?
```

Access: public read; client write denied.

### `modulo_weekly_leaderboard/{weekId}/scores/{uid-or-entry-id}`

Weekly scores. `weekId` is generated as `year * 100 + oneBasedSevenDayBucket`, where bucket 1 starts January 1; it is not ISO week numbering.

```text
playerName: string
score: number
level: number?
```

Access: public read; client write denied. The website queries the current bucket, orders by `score desc`, and limits to 50 rows.

### `purchases/{uid}`

Server-authoritative purchase summary.

Access: signed-in owner read; client write denied.

### `purchases/{uid}/transactions/{transactionId}`

Server-authoritative purchase transaction records.

Access: signed-in owner read; client write denied.

### `entitlements/{uid}`

Server-authoritative entitlement state. Known client fields:

```text
adsRemoved: boolean
premiumUnlocked: boolean
```

Access: signed-in owner read; client write denied.

## Client-local state

SharedPreferences stores non-authoritative device state:

- `fallingMode.visualCuesEnabled`
- `fallingMode.highScore`
- cached purchase flags
- cached leaderboard rows and timestamps

Purchase flags are refreshed from server entitlements when Firebase is available; local values are not proof of ownership.

## Write paths

| Data | Writer |
|---|---|
| Gamertag and own profile/stat data | Authenticated client under rules |
| Leaderboards | Callable Functions only |
| Purchases and entitlements | Purchase validation Functions only |
| Account cleanup | `deleteAccount` callable Function |

## Index expectations

Current queries order only by `score` within a single collection/subcollection and apply a limit. Firestore normally creates the required single-field index automatically. Any compound query added later must include its index definition and documentation.

## Data deletion

The client exposes permanent account deletion through Settings and calls `deleteAccount`. Expected behavior is deletion of the user's related records and Firebase Auth identity. Exact collections and batching behavior are private-server concerns and must be verified against the companion repository before a compliance claim.

## Security verification

The deployed rules source is `packages/firestore-rules/firestore.rules`, referenced by every `firebase*.json` environment file. Validate changes with the emulator/rules tests in the Functions companion repository when available and deploy with an explicit project.
