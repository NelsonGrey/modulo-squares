# Security

**Updated**: 2026-07-20

## Security model

- Firebase Auth establishes identity.
- Firestore rules enforce owner access and deny client writes to server-authoritative collections.
- Callable Functions handle score submissions, purchase validation, entitlement reads, and deletion.
- App Check is integrated in the client; production enforcement is an external setting.
- Secrets and signing material are stored in GitHub environments/secrets or ignored local files.
- Functions business logic is kept in a private companion repository.

## Firestore controls

Current public rules:

- allow public read/no client write for global, daily, and weekly leaderboards;
- allow owner read/no client write for purchases and entitlements;
- allow owner read/write for profiles, stats, and user documents;
- allow authenticated gamertag reads and one-time claims tied to the caller UID;
- deny everything else by omission.

Deploy rules explicitly when they change; the active Hosting and Functions jobs do not currently deploy rules.

## Client configuration

Firebase and AdMob identifiers are client-visible by design, but they must be restricted by bundle/package IDs, API allowlists, quotas, App Check, and backend/rules authorization. Presence in source does not make unrestricted use safe.

Never track:

- service-account JSON;
- Apple `.p8`, signing certificates, provisioning profiles, keystores, or passwords;
- GitHub/Firebase tokens;
- private Functions credentials or provider secrets;
- raw purchase receipts in logs or docs.

## Authentication

Apple Sign-In uses a cryptographic nonce. Google/Apple/email flows should be tested against account collision/linking cases. Error messages should remain useful without exposing provider internals.

Gamertags are validated client-side for format and blocked terms, but server-side uniqueness/moderation must remain authoritative.

## Scores and purchases

- Do not permit direct client leaderboard writes.
- Validate session, identity, score bounds, timing, and replay protection on the server.
- Verify platform receipts/tokens with Apple/Google; never trust local entitlement flags.
- Keep purchase transaction IDs idempotent.
- Avoid returning sensitive verification details to clients.

## Account deletion

The in-app Settings flow calls `deleteAccount`. Compliance validation must confirm every user-owned/current server collection is deleted or legally retained with a disclosed basis, then confirm the Firebase Auth identity is removed.

## Web security

- Firebase Hosting/Nginx must preserve SPA routing while setting appropriate security headers.
- GTM/AdSense scripts expand the third-party trust surface and must remain consent-controlled.
- Keep dependencies patched through Dependabot and CodeQL.
- Never inject user-controlled HTML into policy, support, leaderboard, or metadata surfaces.

## Operational checklist

- Review GitHub secrets and environment protections quarterly.
- Enforce least privilege for `FUNCTIONS_REPO_PAT` and Firebase deployment credentials.
- Rotate tokens/certificates after exposure or staff/device changes.
- Test Firestore rules and Functions with emulators/private tests.
- Verify App Check and API-key restrictions in Firebase/Google Cloud consoles.
- Review CodeQL, Dependabot, npm audit, Flutter/Dart advisories, and App Store privacy disclosures.
- Keep [PUBLIC_REPO_HARDENING.md](PUBLIC_REPO_HARDENING.md) and [SOLUTION_HARDENING_MATRIX.md](SOLUTION_HARDENING_MATRIX.md) current.
