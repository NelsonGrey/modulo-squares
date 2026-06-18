#!/bin/bash

# iOS Code Signing Setup Script for Modulo Squares
# This script helps configure iOS code signing for production builds

set -e

echo "🔐 iOS Code Signing Setup for Modulo Squares"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "Runner.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Not in iOS project directory. Run from packages/mobile/ios/"
    exit 1
fi

echo "📋 Current Configuration:"
echo "- Bundle Identifier: com.nelsongrey.modulosquares.app.ios"
echo "- Code Sign Style: Automatic"
echo ""

echo "📝 iOS Code Signing Setup Instructions:"
echo "======================================"
echo ""
echo "1. Apple Developer Account Setup:"
echo "   - Go to https://developer.apple.com"
echo "   - Sign up for Apple Developer Program (\$99/year)"
echo "   - Verify your account"
echo ""
echo "2. App ID Registration:"
echo "   - Go to https://developer.apple.com/account/resources/identifiers/list"
echo "   - Click '+' to create new App ID"
echo "   - Select 'App IDs' > 'App'"
echo "   - Description: Modulo Squares"
echo "   - Bundle ID: com.nelsongrey.modulosquares.app.ios"
echo "   - Enable required capabilities (if any)"
echo ""
echo "3. Certificate Creation:"
echo "   - Go to https://developer.apple.com/account/resources/certificates/list"
echo "   - Click '+' to create new certificate"
echo "   - Select 'iOS Distribution (App Store and Ad Hoc)'"
echo "   - Follow instructions to create and download .cer file"
echo "   - Add certificate to your Apple Developer account/signing setup"
echo ""
echo "4. Provisioning Profile:"
echo "   - Go to https://developer.apple.com/account/resources/profiles/list"
echo "   - Click '+' to create new profile"
echo "   - Select 'App Store' distribution method"
echo "   - Select your App ID (com.nelsongrey.modulosquares.app.ios)"
echo "   - Select your iOS Distribution certificate"
echo "   - Download and double-click .mobileprovision file"
echo ""
echo "5. Xcode Configuration:"
echo "   - Open Runner.xcworkspace in Xcode"
echo "   - Select Runner target > Signing & Capabilities"
echo "   - Uncheck 'Automatically manage signing'"
echo "   - Select your Team"
echo "   - Select the provisioning profile you created"
echo ""
echo "6. CI/CD Setup (for automated builds):"
echo "   - Upload certificate (.p12) and provisioning profile to CI"
echo "   - Set environment variables:"
echo "     - IOS_CERTIFICATE: base64 encoded .p12 file"
echo "     - IOS_CERTIFICATE_PASSWORD: certificate password"
echo "     - IOS_PROVISIONING_PROFILE: base64 encoded .mobileprovision"
echo ""

echo "🔧 Xcode Project Configuration:"
echo "=============================="

# Check current code signing settings
if grep -q "iPhone Developer" Runner.xcodeproj/project.pbxproj; then
    echo "⚠️  Current code signing identity: iPhone Developer (Development)"
    echo "   For production builds, this should be: iPhone Distribution"
    echo ""
    echo "   To update manually:"
    echo "   1. Open Runner.xcworkspace in Xcode"
    echo "   2. Go to Build Settings > Code Signing"
    echo "   3. Change 'Code Signing Identity' to 'iPhone Distribution'"
    echo "      for Release configuration"
fi

echo ""
echo "✅ Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Follow the instructions above to set up certificates and profiles"
echo "2. Configure Xcode with proper signing"
echo "3. Test build with: flutter build ios --release"
echo "4. Submit to TestFlight/App Store using Xcode or fastlane"