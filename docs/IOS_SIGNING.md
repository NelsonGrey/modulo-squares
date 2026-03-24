# iOS Release Signing Configuration

> **Updated**: This project now uses automatic signing with App Store Connect API authentication (non-interactive workflow).

## Overview

This project uses automatic signing and App Store Connect API key authentication for iOS release builds.

## Quick Setup

1. **Follow the setup guide**: [iOS Certificate Setup Guide](./IOS_CERTIFICATE_SETUP.md)
2. **Run the setup script**: `./scripts/ios-local-dev.sh sync`
3. **Configure GitHub secrets** as documented in the setup guide
4. **Test the build** using GitHub Actions

## Key Configuration

- **Bundle ID**: `com.modulo.squares`
- **Team ID**: Configured in Fastlane Appfile
- **Signing Mode**: Automatic signing
- **Auth Mode**: App Store Connect API key

## Local Development Setup

For local development and testing, use the provided scripts in non-interactive signing mode:

### Quick Local Setup

1. **Set environment variables**:
   ```bash
   export FASTLANE_APPLE_ID="your-apple-id@example.com"
   export FASTLANE_PASSWORD="your-app-specific-password"
   export FASTLANE_TEAM_ID="your-team-id"
   export APP_STORE_CONNECT_KEY_ID="your-key-id"
   export APP_STORE_CONNECT_ISSUER_ID="your-issuer-id"
   export APP_STORE_CONNECT_KEY="your-base64-or-pem-key"
   export BETA_FEEDBACK_EMAIL="your-email@example.com"
   ```

2. **Run the local development script**:
   ```bash
   # Sync certificates (first time setup)
   ./scripts/ios-local-dev.sh sync

   # Build for testing
   ./scripts/ios-local-dev.sh build

   # Run tests
   ./scripts/ios-local-dev.sh test

   # Upload to TestFlight
   ./scripts/ios-local-dev.sh beta
   ```

### What the Local Script Does

- Validates required environment variables
- Configures Fastlane for automatic signing
- Runs build/upload lanes without interactive credential prompts

### Available Commands

```bash
./scripts/ios-local-dev.sh help    # Show all available commands
./scripts/ios-local-dev.sh sync    # Validate signing configuration
./scripts/ios-local-dev.sh build   # Build debug version
./scripts/ios-local-dev.sh test    # Run tests and build
./scripts/ios-local-dev.sh beta    # Build and upload to TestFlight
./scripts/ios-local-dev.sh clean   # Clean build artifacts
```

### Troubleshooting Local Builds

If signing fails:

1. **Verify API key variables** (`APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY`)
2. **Verify team ID** (`FASTLANE_TEAM_ID`)
3. **Run setup again**:
   ```bash
   ./scripts/ios-local-dev.sh sync
   ```

## Build Process

### Automated (Recommended)
```bash
# From packages/mobile/ios
bundle exec fastlane beta    # TestFlight build
bundle exec fastlane release # App Store build
```

### Manual Override
If you need to build manually:
```bash
flutter build ipa --release
```

## Legacy Manual Setup (Deprecated)

The information below is kept for reference but is no longer the recommended approach. Use Fastlane Match instead.

### Apple Developer Program Setup

1. **Enroll in Apple Developer Program**: Visit [developer.apple.com/programs](https://developer.apple.com/programs)
2. **Create App ID**: In Certificates, Identifiers & Profiles → Identifiers
   - Type: App IDs
   - Bundle ID: `com.nelsongrey.modulosquares.app.ios` (matches Info.plist)
   - Enable required capabilities (if any)

3. **Create Provisioning Profile**:
   - Type: App Store
   - Select your App ID
   - Select your certificate

### Xcode Configuration

#### Automatic Signing (Recommended)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner project
3. Go to Signing & Capabilities tab
4. Check "Automatically manage signing"
5. Select your development team
6. Xcode will create and manage certificates/profiles automatically

#### Manual Signing (Advanced)
If you prefer manual control:
1. Create distribution certificate in Apple Developer portal
2. Download and install certificate
3. Create App Store provisioning profile
4. Update Xcode project settings

### Build Configuration

#### Runner.xcworkspace Settings
- **Bundle Identifier**: `com.nelsongrey.modulosquares.app.ios`
- **Version**: Match pubspec.yaml version
- **Build**: Increment for each release

#### Info.plist Updates
The Info.plist already contains:
- App Tracking Transparency description
- AdMob App ID (needs updating)
- SKAdNetwork items

### Building for Release

#### Using Flutter CLI
```bash
# Build for iOS
flutter build ios --release

# Open Xcode for additional configuration
open ios/Runner.xcworkspace
```

#### Using Xcode
1. Open `ios/Runner.xcworkspace`
2. Select "Runner" → "Generic iOS Device"
3. Product → Archive
4. Validate and distribute through Xcode

### App Store Connect Setup

1. **Create App Record**:
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Add new app
   - Fill in name, bundle ID, SKU

2. **Prepare Assets**:
   - App icon (1024x1024)
   - Screenshots (various device sizes)
   - Description and keywords

3. **Upload Build**:
   - Use Xcode to upload or `flutter build ipa --release`
   - Wait for processing
   - Submit for review

### TestFlight (Optional)

For beta testing:
1. Create TestFlight build
2. Invite testers
3. Collect feedback before App Store submission

### Common Issues

- **Bundle ID mismatch**: Ensure Info.plist matches App Store Connect
- **Missing entitlements**: Check capabilities in Xcode
- **Code signing errors**: Clean build folder (Product → Clean Build Folder)
- **App Store rejection**: Review guidelines and fix issues

### Environment Variables (CI/CD)

For automated builds, set:
```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
FLUTTER_ROOT=/path/to/flutter
```

### Security Best Practices

- Store Apple ID credentials securely
- Use different certificates for development/production
- Regularly rotate distribution certificates
- Keep backup copies of certificates