# iOS Release Signing Configuration

> **Updated**: This project now uses Fastlane Match for automated certificate management. See the [iOS Certificate Setup Guide](./IOS_CERTIFICATE_SETUP.md) for the current setup process.

## Overview

This project uses Fastlane Match to manage iOS certificates and provisioning profiles. Certificates are stored in a separate private GitHub repository (`modulo-squares-certificates`) for security and team collaboration.

## Quick Setup

1. **Follow the setup guide**: [iOS Certificate Setup Guide](./IOS_CERTIFICATE_SETUP.md)
2. **Run the setup script**: `./scripts/setup-ios-certificates.sh`
3. **Configure GitHub secrets** as documented in the setup guide
4. **Test the build** using GitHub Actions

## Key Configuration

- **Bundle ID**: `com.modulo.squares`
- **Team ID**: Configured in Fastlane Appfile
- **Certificates Repository**: `https://github.com/mnelson3/modulo-squares-certificates`
- **Match Type**: `appstore` for distribution builds

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