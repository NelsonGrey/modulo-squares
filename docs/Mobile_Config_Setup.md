# Mobile Configuration Setup

This document explains the mobile-specific Firebase configuration setup for the Modulo Squares Flutter app.

## Overview

Similar to the web Firebase configs, mobile apps now have environment-specific configuration files that are automatically switched during CI/CD builds.

## Configuration Files

### Android (`packages/app/android/app/`)

- `google-services.dev.json` - Development environment
- `google-services.staging.json` - Staging environment
- `google-services.prod.json` - Production environment
- `google-services.json` - Active config (switched automatically)

### iOS (`packages/app/ios/Runner/`)

- `GoogleService-Info.dev.plist` - Development environment
- `GoogleService-Info.staging.plist` - Staging environment
- `GoogleService-Info.prod.plist` - Production environment
- `GoogleService-Info.plist` - Active config (switched automatically)

## Usage

### Local Development

Switch configs manually using npm scripts:

```bash
# Switch to development
npm run config:dev

# Switch to staging
npm run config:staging

# Switch to production
npm run config:prod
```

### CI/CD

Configs are automatically switched in GitHub Actions based on the deployment environment:

- `develop` branch → Development configs
- `staging` branch → Staging configs
- `main` branch → Production configs

## Setup Requirements

⚠️ **Important**: The placeholder API keys in the config files need to be replaced with actual Firebase API keys from the Firebase Console.

### Getting Firebase Config Files

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select the appropriate project:
   - `modulo-squares-dev`
   - `modulo-squares-staging`
   - `modulo-squares-prod`
3. Go to Project Settings → General → Your apps
4. Download the config files for Android/iOS
5. Replace the placeholder files in this repository

### Required Replacements

In each environment's config files, replace:
- `AIzaSyDUMMY_API_KEY_*` with actual Firebase API keys
- Ensure project IDs match the Firebase projects
- Verify bundle/package names are correct

## Build Scripts

The `scripts/switch-mobile-configs.sh` script handles config switching:

```bash
./scripts/switch-mobile-configs.sh [dev|staging|prod]
```

This script:
1. Validates the environment parameter
2. Copies the appropriate Android config to `google-services.json`
3. Copies the appropriate iOS config to `GoogleService-Info.plist`
4. Reports success/failure

## Integration

The mobile configs integrate with the existing Firebase CLI setup:

- Firebase CLI uses `firebase.*.json` files for project configuration
- Flutter build process uses the active `google-services.json` and `GoogleService-Info.plist`
- CI/CD automatically switches configs before building

## Troubleshooting

### Build Fails with Wrong Environment

If builds are using the wrong Firebase environment:

1. Check which config files are currently active
2. Run the appropriate config switch command
3. Clean and rebuild: `flutter clean && flutter pub get`

### Missing API Keys

If authentication fails:

1. Verify API keys are not placeholders
2. Check Firebase Console for correct keys
3. Ensure keys match the project environment

### Config Not Switching in CI/CD

If CI/CD uses wrong configs:

1. Check the branch → environment mapping
2. Verify the config switch step runs before Flutter build
3. Check CI/CD logs for config switch output