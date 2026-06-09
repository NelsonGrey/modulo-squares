# GitHub Secrets Setup

## Required Secrets

### Environment-Specific Firebase Tokens
Each Firebase environment requires its own authentication token for security and access control.

#### FIREBASE_TOKEN_DEVELOPMENT
**Purpose**: Authenticates GitHub Actions with Firebase for DEV environment deployments

**How to get it**:
```bash
# Login to Firebase and select DEV project
firebase use modulo-squares-dev
firebase login:ci
```

#### FIREBASE_TOKEN_STAGING
**Purpose**: Authenticates GitHub Actions with Firebase for STAGING environment deployments

**How to get it**:
```bash
# Login to Firebase and select STAGING project
firebase use modulo-squares-staging
firebase login:ci
```

#### FIREBASE_TOKEN_PRODUCTION
**Purpose**: Authenticates GitHub Actions with Firebase for PROD environment deployments

**How to get it**:
```bash
# Login to Firebase and select PROD project
firebase use modulo-squares-prod
firebase login:ci
```

**Where to add them**: GitHub Repository → Settings → Secrets and variables → Actions → New repository secret

### iOS Self-Contained Distribution Secrets
These secrets are required for in-repo iOS TestFlight uploads via Fastlane (no external nelson-grey credential sharing).

#### APP_STORE_CONNECT_KEY_ID
**Purpose**: App Store Connect API key ID

#### APP_STORE_CONNECT_ISSUER_ID
**Purpose**: App Store Connect issuer ID

#### APP_STORE_CONNECT_KEY
**Purpose**: App Store Connect private key content (`.p8`) or base64 encoded key

#### FASTLANE_TEAM_ID
**Purpose**: Apple Developer Team ID used for automatic signing

**Used by workflows**:
- `.github/workflows/ios-build-self-contained.yml`
- `.github/workflows/install-ios-on-hades.yml` (manual trigger wrapper)

### Optional Secrets (for signed Android releases)

#### ANDROID_KEYSTORE
**Purpose**: Base64 encoded Android keystore file for signed releases

**How to get it**:
```bash
# Convert keystore to base64
base64 -i your-keystore.jks
```

#### ANDROID_KEYSTORE_PASSWORD
**Purpose**: Password for the Android keystore

#### ANDROID_KEY_ALIAS
**Purpose**: Alias of the key in the keystore

#### ANDROID_KEY_PASSWORD
**Purpose**: Password for the key in the keystore

## Environment Setup

The CI/CD pipeline automatically detects the environment based on the branch and uses the appropriate Firebase token:

- `develop` → DEV environment (`FIREBASE_TOKEN_DEV`)
- `staging` → STAGING environment (`FIREBASE_TOKEN_STAGING`)
- `main` → PROD environment (`FIREBASE_TOKEN_PROD`)

## Testing the Setup

1. **Add all three Firebase tokens to GitHub secrets**

2. **Push to develop branch**:
   ```bash
   git checkout develop
   git push origin develop
   ```

3. **Check GitHub Actions**: Go to Actions tab in your repository

4. **Verify deployment**: Visit https://modulo-squares-dev.web.app

Repeat for `staging` and `main` branches.