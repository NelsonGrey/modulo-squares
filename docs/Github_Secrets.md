# GitHub Secrets Setup

**Updated**: 2026-07-20

The active workflow references these secrets directly:

| Secret | Used by | Purpose |
|---|---|---|
| `APP_STORE_CONNECT_KEY_ID` | `build-ios`, `submit-app-store` | App Store Connect API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | `build-ios`, `submit-app-store` | App Store Connect issuer ID |
| `APP_STORE_CONNECT_KEY` | `build-ios`, `submit-app-store` | `.p8` private key content or supported base64 form |
| `FASTLANE_TEAM_ID` | `build-ios` | Apple Developer Team ID for automatic signing |
| `FIREBASE_TOKEN` | `deploy-web`, `deploy-functions` | Firebase CLI authentication |
| `FUNCTIONS_REPO_PAT` | `deploy-functions` | Read access to private companion Functions repo |

Secrets may be stored per GitHub Environment (`development`, `staging`, `production`) or at repository scope as appropriate. Environment protection and least privilege are recommended for production.

## Private Functions token

Use a fine-grained token limited to read-only Contents access for `NelsonGrey/modulo-squares-functions`. Do not grant write/admin access. Rotate it when access changes or exposure is suspected.

## Firebase authentication

The current workflow uses one secret name, `FIREBASE_TOKEN`, and selects the project from branch/environment logic. It does not reference older environment-specific token names.

Firebase CLI login tokens are legacy-style credentials; migrate to workload identity/service-account federation when the delivery design supports it.

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
