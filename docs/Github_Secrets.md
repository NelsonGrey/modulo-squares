# GitHub Secrets Setup

**Updated**: 2026-07-20

The active workflow references these secrets directly:

| Secret | Used by | Purpose |
|---|---|---|
| `APP_STORE_CONNECT_KEY_ID` | `build-ios`, `submit-app-store` | App Store Connect API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | `build-ios`, `submit-app-store` | App Store Connect issuer ID |
| `APP_STORE_CONNECT_KEY` | `build-ios`, `submit-app-store` | `.p8` private key content or supported base64 form |
| `FASTLANE_TEAM_ID` | `build-ios` | Apple Developer Team ID for automatic signing |
| `FIREBASE_SERVICE_ACCOUNT_KEY_DEVELOPMENT` | `deploy-web`, `deploy-functions` (development) | Firebase service account JSON key for `modulo-squares-dev` |
| `FIREBASE_SERVICE_ACCOUNT_KEY_STAGING` | `deploy-web`, `deploy-functions` (staging) | Firebase service account JSON key for `modulo-squares-staging` |
| `FIREBASE_SERVICE_ACCOUNT_KEY_PRODUCTION` | `deploy-web`, `deploy-functions` (production) | Firebase service account JSON key for `modulo-squares-prod` |
| `FUNCTIONS_REPO_PAT` | `deploy-functions` | Read access to private companion Functions repo |

Secrets may be stored per GitHub Environment (`development`, `staging`, `production`) or at repository scope as appropriate. Environment protection and least privilege are recommended for production.

## Private Functions token

Use a fine-grained token limited to read-only Contents access for `NelsonGrey/modulo-squares-functions`. Do not grant write/admin access. Rotate it when access changes or exposure is suspected.

## Firebase authentication

`deploy-web` and `deploy-functions` authenticate via `GOOGLE_APPLICATION_CREDENTIALS`, pointed at a service account JSON key written to a runner-temp file. Each of the three GitHub Environments (`development`/`staging`/`production`) must have its own `FIREBASE_SERVICE_ACCOUNT_KEY_<ENV>` secret containing that environment's key — the workflow selects between them by environment, since GitHub Actions can't construct a `secrets.*` name dynamically. All three must be populated; a missing one writes an empty/invalid credentials file and fails that environment's deploy.

Previously used `firebase deploy --token "$FIREBASE_TOKEN"` (a `firebase login:ci` OAuth refresh token) — deprecated by the Firebase CLI, and prone to expiring or being silently revoked with no advance warning (this broke both deploy jobs in production on 2026-08-07). Service account keys don't share that failure mode. `FIREBASE_TOKEN` is no longer referenced by any active job and can be removed once confirmed unused elsewhere.

## iOS key format

`packages/mobile/ios/fastlane/Fastfile` accepts PEM text or base64 key material and normalizes it into a temporary `.p8` file. Store only the private key value, never the key filename or a public download URL.

## Optional/future Android secrets

Android is not built by active CI. A future signed Android job may require a base64 keystore, store/key passwords, and alias. Define exact names in the workflow before adding them to GitHub; avoid maintaining unused privileged secrets.

## Verification

1. Review secret references in `.github/workflows/ci-cd.yml`.
2. Review environment protection and branch policies.
3. Run a staging pipeline.
4. Confirm the TestFlight, Hosting, and Functions jobs authenticate without printing secret content.
5. Run production only after staging succeeds.

Never paste values into issues, logs, screenshots, documentation, or chat.
