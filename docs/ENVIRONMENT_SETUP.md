# Environment Setup Guide

This guide explains how to set up environment variables for the Modulo project across all environments.

## Overview

The project uses environment-specific `.env` files to manage Firebase configuration and other environment variables.

## Environment Files

- `.env.development` - Development environment
- `.env.staging` - Staging environment  
- `.env.production` - Production environment
- `.env.example` - Template file (committed to git)

## Getting Firebase Configuration Values

### Method 1: Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select the appropriate project:
   - **Dev**: `modulo-squares-dev`
   - **Staging**: `modulo-squares-staging`
   - **Prod**: `modulo-squares-prod`
3. Go to **Project Settings** > **General** tab
4. Scroll down to **Your apps** section
5. Click on the **Web app** (</>) icon
6. Copy the configuration values from the `firebaseConfig` object

### Method 2: Using Setup Script

```bash
# For development environment
./scripts/setup-env.sh dev

# For staging environment
./scripts/setup-env.sh staging

# For production environment
./scripts/setup-env.sh prod
```

## Required Environment Variables

### Firebase Configuration
```bash
FIREBASE_API_KEY=your_api_key_here
FIREBASE_AUTH_DOMAIN=modulo-squares-[env].firebaseapp.com
FIREBASE_PROJECT_ID=modulo-squares-[env]
FIREBASE_STORAGE_BUCKET=modulo-squares-[env].appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here
FIREBASE_APP_ID=your_app_id_here
```

### Environment Settings
```bash
ENVIRONMENT=[development|staging|production]
```

## Setting Up Environment Files

1. Copy the appropriate template:
   ```bash
   cp .env.example .env.development
   cp .env.example .env.staging
   cp .env.example .env.production
   ```

2. Fill in the actual values from Firebase Console

3. For local development, create a symlink or copy:
   ```bash
   cp .env.development .env
   ```

## Security Notes

- Never commit `.env` files to version control
- Use different Firebase projects for each environment
- Keep API keys secure and rotate them regularly
- Use environment-specific service accounts for CI/CD

## Testing Environment Setup

After setting up your environment variables:

```bash
# Test Firebase connection
firebase use modulo-squares-dev
firebase projects:list

# Test functions locally
cd packages/functions
npm run serve
```

## Troubleshooting

### Common Issues

1. **"Project not found"**: Make sure you're logged in with `firebase login`
2. **"Permission denied"**: Check that you have access to the Firebase project
3. **"Invalid API key"**: Verify the API key is correct for the environment

### Getting Help

If you encounter issues:
1. Check the Firebase Console for correct project IDs
2. Verify your Firebase CLI authentication
3. Ensure environment files are in the correct location
