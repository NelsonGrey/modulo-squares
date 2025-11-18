# iOS Certificate Setup Guide

This guide explains how to set up iOS certificates and provisioning profiles for the modulo-squares Flutter app using Fastlane Match.

## Overview

We use Fastlane Match to manage iOS certificates and provisioning profiles. This approach stores certificates in a separate private GitHub repository for better security and team collaboration.

## Prerequisites

1. **App Store Connect Access**: You need access to the modulo-squares app in App Store Connect
2. **Apple Developer Account**: Admin or Account Holder role
3. **GitHub Repository**: Create a private repository called `modulo-squares-certificates`
4. **SSH Key or Personal Access Token**: For accessing the certificates repository

## Step 1: Create Certificates Repository

1. Go to GitHub and create a new **private** repository named `modulo-squares-certificates`
2. Make sure it's completely empty (no README, .gitignore, or license)

## Step 2: Set Environment Variables

Set the required environment variables:

```bash
export MATCH_PASSWORD="your_secure_password_here"
export MATCH_GIT_URL="https://github.com/mnelson3/modulo-squares-certificates.git"
```

Choose a strong password for `MATCH_PASSWORD` - this will encrypt your certificates.

## Step 3: Run Certificate Setup

From the root of the modulo-squares repository:

```bash
./scripts/setup-ios-certificates.sh
```

This script will:
- Generate development and distribution certificates
- Create provisioning profiles
- Upload everything to the certificates repository

## Step 4: Configure GitHub Secrets

Add the following secrets to your modulo-squares repository:

| Secret Name | Value |
|-------------|-------|
| `MATCH_PASSWORD` | The password you used in Step 2 |
| `MATCH_GIT_URL` | `https://oauth2:gho_YOUR_TOKEN@github.com/mnelson3/modulo-squares-certificates.git` |
| `ASC_PRIVATE_KEY` | Your App Store Connect API private key (base64 encoded) |
| `ASC_KEY_ID` | Your App Store Connect API key ID |
| `ASC_ISSUER_ID` | Your App Store Connect API issuer ID |
| `FASTLANE_APPLE_ID` | Your Apple ID email address |
| `FASTLANE_TEAM_ID` | Your Apple Developer team ID |
| `FASTLANE_ITC_TEAM_ID` | Your App Store Connect team ID |
| `BETA_FEEDBACK_EMAIL` | Email address for TestFlight feedback |

## Step 5: Get App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to Users and Access → Keys
3. Generate a new API key with "App Manager" access
4. Download the private key (.p8 file)
5. Copy the Key ID and Issuer ID
6. Base64 encode the .p8 file content and add to `ASC_PRIVATE_KEY`
7. Add the Key ID to `ASC_KEY_ID`
8. Add the Issuer ID to `ASC_ISSUER_ID`

## Step 6: Test the Setup

Trigger the iOS distribution workflow in GitHub Actions to verify everything works.

## Troubleshooting

### "Repository not found" error
- Make sure the `modulo-squares-certificates` repository exists and is private
- Verify your SSH keys or personal access token has access to the repository

### "Invalid credentials" error
- Check your App Store Connect API key is correct
- Verify the Key ID and Issuer ID match

### Certificate generation fails
- Ensure you have the correct permissions in App Store Connect
- Check that the app identifier `com.modulo.squares` is registered

## Security Notes

- The certificates repository should remain private
- Never commit certificates or private keys to the main repository
- Rotate the `MATCH_PASSWORD` periodically
- Use SSH keys instead of personal access tokens when possible

## Manual Commands

If you need to run commands manually:

```bash
cd packages/mobile/ios

# Generate certificates
bundle exec fastlane init_certificates

# Sync existing certificates
bundle exec fastlane sync_certificates

# Build for TestFlight
bundle exec fastlane beta

# Build for App Store
bundle exec fastlane release
```