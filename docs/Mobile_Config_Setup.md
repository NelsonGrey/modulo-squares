# Mobile Configuration Setup

**Updated**: 2026-07-20

The Flutter app tracks environment-specific Firebase native configuration and copies one environment into each platform's active filename before a build.

## Files

### Android: `packages/mobile/android/app`

- `google-services.dev.json`
- `google-services.staging.json`
- `google-services.prod.json`
- `google-services.json` (active copy)

### iOS: `packages/mobile/ios/Runner`

- `GoogleService-Info.dev.plist`
- `GoogleService-Info.staging.plist`
- `GoogleService-Info.prod.plist`
- `GoogleService-Info.plist` (active copy)

## Switch environments

From the repository root:

```bash
npm run config:dev
npm run config:staging
npm run config:prod
```

or:

```bash
./scripts/switch-mobile-configs.sh dev|staging|prod
```

The active CI workflow selects staging for the staging iOS build and production for the main iOS build. Development does not run the iOS build job.

## Projects

- `dev` -> `modulo-squares-dev`
- `staging` -> `modulo-squares-staging`
- `prod` -> `modulo-squares-prod`

## Verification

- Confirm the selected JSON/plist project ID before a release build.
- Confirm bundle/application IDs match the registered Firebase apps.
- Confirm sign-in providers and URL schemes for the selected environment.
- Treat client API keys as public identifiers but apply console-side app/API/quota restrictions.
- Do not hand-edit the active copy when the environment source file should change.

After switching:

```bash
cd packages/mobile
flutter clean
flutter pub get
flutter run
```
