# CI/CD Setup

**Updated**: 2026-07-20
**Active workflow**: `.github/workflows/ci-cd.yml`

## Triggers

- Push to `develop`, `staging`, or `main`.
- Pull request targeting those branches.
- Manual dispatch with environment selection and optional App Store submission.

Pull requests run validation/build work but do not deploy. Push/manual runs on mapped branches can deploy.

## Toolchain

- Flutter `3.44.2`
- Node.js `20`
- `ubuntu-latest` for quality, web, Hosting, and Functions jobs
- `macos-latest` for iOS/TestFlight/App Store jobs

## Jobs

| Job | Runs when | Behavior |
|---|---|---|
| `determine-environment` | every run | Maps branch/input to development, staging, or production and decides whether deployment is allowed |
| `quality-check` | every run | Flutter setup, `flutter analyze`, `flutter test --coverage`, coverage artifact |
| `build-web` | after quality | `npm ci` and React production build, uploads `web-build` |
| `build-ios` | deployable `staging`/`main` runs | Switches native config, installs Fastlane, uploads TestFlight build |
| `submit-app-store` | manual production submission only | Runs Fastlane `submit_to_app_store` against an already uploaded build; it is not dependent on `build-ios` |
| `deploy-web` | deployable runs | Downloads web artifact and deploys Firebase Hosting |
| `deploy-functions` | deployable runs | Checks out private Functions repo and deploys Functions |
| `deployment-summary` | deployable runs, always | Summarizes job results and environment URLs |

Firestore rules are configured in Firebase descriptors but the current `deploy-web` command deploys Hosting only. Functions deployment deploys Functions only. Run `npm run deploy:rules` or an explicit rules deploy when rules change; do not assume every pipeline run updates rules.

## Branch mapping

| Branch | Environment | Functions branch |
|---|---|---|
| `develop` | development | `develop` |
| `staging` | staging | `staging` |
| `main` | production | `main` |

## Required secrets

Core iOS/Fastlane:

- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY`
- `FASTLANE_TEAM_ID`

Firebase/private Functions:

- `FIREBASE_TOKEN`
- `FUNCTIONS_REPO_PAT`

These are the secret names referenced directly by the active workflow. Audit the workflow itself before rotating or removing any value.

## App Store submission

Automatic branch deployments upload to TestFlight. Submission to review is deliberately separate:

1. Confirm the intended corrected build has already been uploaded and processed in App Store Connect.
2. Dispatch `ci-cd.yml`.
3. Select `production`.
4. Set `submit_to_app_store` to true.
5. Verify the desired build/IAP/version state in App Store Connect.

Fastlane's submission lane skips binary upload and metadata/screenshots and uses the already uploaded build. It excludes IAP from `precheck`; IAP review state must be handled in App Store Connect.

## Android

The Android platform project and signing helpers are tracked, but the active pipeline has no Android build or Google Play deployment job. Treat Android release docs as Phase 2/reference until that job is added and verified.

## Other workflows

- `codeql.yml`: CodeQL scanning.
- `dependabot-auto-merge.yml`: patch/minor Dependabot approval and auto-merge logic.
- `install-ios-on-hades.yml`: manual build/install on a connected device via self-hosted Mac.
- `.github/workflows/archive/*`: inactive historical workflows.

## Local approximation

```bash
npm ci
npm run lint
npm run check
npm run build:web

cd packages/mobile
flutter pub get
flutter analyze
flutter test --coverage
flutter build ios --release --no-codesign
```

Local commands do not validate GitHub environment protection, secret availability, TestFlight/App Store Connect, or Firebase deploy permissions.

## Change checklist

When changing CI:

- keep action versions and documented tool versions aligned;
- preserve pull-request non-deployment guards;
- verify all `needs` relationships and `if: always()` behavior;
- update `GO_LIVE_RUNBOOK.md` and this document;
- test with a non-production branch before production;
- keep Functions source checkout scoped to the private repository and correct branch.
