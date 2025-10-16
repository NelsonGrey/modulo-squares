# CI/CD Setup Guide

This guide explains how to set up continuous integration and deployment for the Modulo Squares project with Firebase environments.

## 🚀 Overview

The project uses GitHub Actions for CI/CD with three Firebase environments:
- **DEV**: `modulo-squares-dev` (develop branch)
- **STAGING**: `modulo-squares-staging` (staging branch)
- **PROD**: `modulo-squares-prod` (main branch)

## 📋 Prerequisites

1. **Firebase Projects**: Ensure you have created three Firebase projects:
   - `modulo-squares-dev`
   - `modulo-squares-staging`
   - `modulo-squares-prod`

2. **Firebase CLI**: Install Firebase CLI globally
   ```bash
   npm install -g firebase-tools
   ```

3. **GitHub Repository**: Ensure you have a GitHub repository set up

## 🔧 GitHub Secrets Setup

Add the following secrets to your GitHub repository:

### Required Secrets
- `FIREBASE_TOKEN`: Firebase CI token for deployments

### Optional Secrets (for releases)
- `ANDROID_KEYSTORE`: Base64 encoded Android keystore (for signed releases)
- `ANDROID_KEYSTORE_PASSWORD`: Android keystore password
- `ANDROID_KEY_ALIAS`: Android key alias
- `ANDROID_KEY_PASSWORD`: Android key password

## 🏗️ Branch Strategy

```
main (PROD)     ← Production releases
├── staging     ← Staging environment
└── develop     ← Development environment
```

### Branch Protection Rules

Set up branch protection for:
- `main`: Require PR reviews, status checks
- `staging`: Require status checks
- `develop`: Allow direct pushes for development

## 🚀 Deployment Workflow

### Automatic Deployments
- **Push to `develop`**: Deploys to DEV environment
- **Push to `staging`**: Deploys to STAGING environment
- **Push to `main`**: Deploys to PROD + creates release

### Manual Deployments
Use the deployment scripts for manual deployments:

```bash
# Deploy to development
./scripts/deploy.sh dev

# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh prod
```

On Windows:
```powershell
.\scripts\deploy.ps1 dev
.\scripts\deploy.ps1 staging
.\scripts\deploy.ps1 prod
```

## 🔍 Environment URLs

After deployment, your app will be available at:
- **DEV**: https://modulo-squares-dev.web.app
- **STAGING**: https://modulo-squares-staging.web.app
- **PROD**: https://modulo-squares-prod.web.app

## 🧪 Testing

### Local Testing
```bash
# Test DEV environment locally
firebase use modulo-squares-dev
firebase serve

# Test STAGING environment locally
firebase use modulo-squares-staging
firebase serve

# Test PROD environment locally
firebase use modulo-squares-prod
firebase serve
```

### CI Testing
The CI pipeline runs:
- Flutter analyze
- Unit tests with coverage
- Integration tests (if configured)

## 📱 Mobile App Releases

When pushing to `main`, the CI pipeline automatically:
1. Builds Android APK and AAB
2. Builds iOS (without codesigning)
3. Creates a GitHub release with download links

## 🔧 Firebase Configuration

### Project Setup
Each Firebase project needs:
- Hosting enabled
- Authentication configured (Google, Apple, Anonymous)
- Firestore database
- Analytics enabled

### Hosting Targets
The `.firebaserc` file defines hosting targets for each environment.

## 🐛 Troubleshooting

### Common Issues

1. **Firebase Token Expired**
   ```bash
   firebase logout
   firebase login:ci
   # Update FIREBASE_TOKEN secret
   ```

2. **Build Failures**
   - Check Flutter version compatibility
   - Ensure all dependencies are properly specified
   - Verify Firebase configuration

3. **Deployment Failures**
   - Verify Firebase project permissions
   - Check hosting target configuration
   - Ensure build artifacts exist

### Logs
Check GitHub Actions logs for detailed error information.

## 📚 Additional Resources

- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter Deployment Guide](https://flutter.dev/docs/deployment/web)