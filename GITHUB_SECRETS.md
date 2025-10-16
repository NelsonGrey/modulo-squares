# GitHub Secrets Setup

## Required Secrets

### FIREBASE_TOKEN
**Purpose**: Authenticates GitHub Actions with Firebase for deployments

**How to get it**:
```bash
# Login to Firebase CLI
firebase login

# Generate CI token
firebase login:ci
```

**Where to add it**: GitHub Repository → Settings → Secrets and variables → Actions → New repository secret

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

The CI/CD pipeline automatically detects the environment based on the branch:

- `develop` → DEV environment (`modulo-squares-dev`)
- `staging` → STAGING environment (`modulo-squares-staging`)
- `main` → PROD environment (`modulo-squares-prod`)

## Testing the Setup

1. **Push to develop branch**:
   ```bash
   git checkout develop
   git push origin develop
   ```

2. **Check GitHub Actions**: Go to Actions tab in your repository

3. **Verify deployment**: Visit https://modulo-squares-dev.web.app

Repeat for `staging` and `main` branches.