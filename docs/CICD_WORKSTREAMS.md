# CI/CD Workstreams (modulo-squares)

## Requirements
- iOS distribution is zero-touch:
  - App Store Connect auth via API key secrets.
  - Match repo access over HTTPS token (`MATCH_GIT_URL_TOKEN`) to `mnelson3/nelson-grey`.
  - Ephemeral keychain wrapper used for Fastlane.
- Branch/environment mapping is consistent with repo environments.
- Self-hosted runners are resilient (auto-restart + watchdog).

## Current state
- iOS distribution workflow: [modulo-squares/.github/workflows/ios-cicd-release.yml](../.github/workflows/ios-cicd-release.yml)
- Token refresh health check LaunchAgent: [modulo-squares/com.modulo-squares.runner-token-refresh.plist](../com.modulo-squares.runner-token-refresh.plist)

## Workstreams

### WS1 — iOS distribution (DONE)
Deliverables:
- Workflow uses ASC API key auth + Match HTTPS token.
- Workflow uses ephemeral keychain wrapper.
- Secrets cleanup always runs.

Acceptance:
- `workflow_dispatch` → `testflight` lane completes unattended on macOS runner.

### WS2 — Runner reliability (IN PROGRESS)
Why:
- GitHub shows `modulo-squares-macos-runner` is currently `offline`.

Deliverables:
- Fix `modulo-squares-actions-runner` so it can bootstrap/install a working runner service.
- Install a watchdog that re-registers/restarts the runner when it becomes `offline`.

Acceptance:
- Runner stays online across reboot and process crash.

### WS3 — Docker runner reliability (IN PROGRESS)
Deliverables:
- Ensure the periodic token/health check is installed on the docker runner host.
- Health check restarts the runner container if missing.

Acceptance:
- `modulo-squares-docker-runner` returns to `online` after container crash.

## Dependencies / Secrets
Required secrets (per repo environment):
- Apple: `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY`, `FASTLANE_APPLE_ID`, `FASTLANE_TEAM_ID`, `FASTLANE_ITC_TEAM_ID`
- Apple: `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY`, `FASTLANE_APPLE_ID`, `FASTLANE_TEAM_ID`, `FASTLANE_ITC_TEAM_ID`
- Match: `MATCH_GIT_URL_TOKEN`, `MATCH_PASSWORD`
- Firebase: `FIREBASE_SERVICE_ACCOUNT_KEY_DEVELOPMENT`, `FIREBASE_SERVICE_ACCOUNT_KEY_STAGING`, `FIREBASE_SERVICE_ACCOUNT_KEY_PRODUCTION`
