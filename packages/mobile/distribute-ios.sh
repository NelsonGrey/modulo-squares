#!/bin/bash

# iOS App Distribution Script
# Usage: ./distribute-ios.sh <build_type> <release_notes>

set -e

BUILD_TYPE=${1:-debug}
RELEASE_NOTES=${2:-"Automated build"}

echo "🚀 Starting iOS app distribution..."
echo "Build Type: $BUILD_TYPE"
echo "Release Notes: $RELEASE_NOTES"

# Check if we're in the right directory
if [[ ! -f "pubspec.yaml" ]]; then
    echo "❌ Error: pubspec.yaml not found. Please run from the mobile package root."
    exit 1
fi

# Check if running on macOS (required for iOS builds)
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️ Warning: Not running on macOS. iOS builds require macOS environment."
    echo "This script will simulate the build process for testing purposes."
    SIMULATION_MODE=true
fi

# Build the app
echo "📱 Building iOS app..."
if [[ "$BUILD_TYPE" == "release" ]]; then
    if [[ "$SIMULATION_MODE" == "true" ]]; then
        echo "🔧 Simulating iOS release build..."
        # Create a dummy IPA file for testing
        mkdir -p build/ios/ipa
        echo "Dummy IPA content" > build/ios/ipa/app.ipa
    else
        echo "🔧 Building iOS release app..."
        # For production builds, proper code signing is required
        # This would need certificates, provisioning profiles, and Fastlane
        flutter build ios --release --no-codesign
        echo "⚠️ Warning: Built without code signing. For distribution, you need:"
        echo "  - Apple Developer Program membership"
        echo "  - iOS Distribution Certificate"
        echo "  - App Store Distribution Provisioning Profile"
        echo "  - Fastlane setup for automated signing and upload"
    fi
    IPA_PATH="build/ios/ipa/app.ipa"
else
    if [[ "$SIMULATION_MODE" == "true" ]]; then
        echo "🔧 Simulating iOS debug build..."
        mkdir -p build/ios/ipa
        echo "Dummy debug IPA content" > build/ios/ipa/app-debug.ipa
    else
        flutter build ios --debug -d "23DCF2C4-2576-418F-9A82-08ED6D6F0B02" --no-codesign
    fi
    IPA_PATH="build/ios/iphonesimulator/Runner.app"
fi

if [[ ! -e "$IPA_PATH" ]]; then
    echo "❌ Error: Build output not found at $IPA_PATH"
    exit 1
fi

echo "✅ Build completed successfully: $IPA_PATH"

# Distribute to Firebase App Distribution (works on both macOS and Linux)
echo "📤 Distributing to Firebase App Distribution..."
if [[ -f "ios/service-account-key.json" ]]; then
    # Authenticate with service account
    export GOOGLE_APPLICATION_CREDENTIALS="ios/service-account-key.json"

    # Get Firebase project and app ID based on environment
    if [[ "$ENVIRONMENT" == "PRODUCTION" ]]; then
        FIREBASE_PROJECT="modulo-squares-prod"
        FIREBASE_APP_ID="1:253948321735:ios:527c4e69b233a2199ec3e2"
    elif [[ "$ENVIRONMENT" == "STAGING" ]]; then
        FIREBASE_PROJECT="modulo-squares-staging"
        FIREBASE_APP_ID="1:838061114925:ios:f607167ffa35e7bb229aa4"
    else
        FIREBASE_PROJECT="modulo-squares-dev"
        FIREBASE_APP_ID="1:784677197785:ios:51104e6b575616cc61abc8"
    fi

    # For debug builds (simulator), use .app bundle; for release, use IPA
    DISTRIBUTION_FILE="$IPA_PATH"

    firebase appdistribution:distribute "$DISTRIBUTION_FILE" \
        --project "$FIREBASE_PROJECT" \
        --app "$FIREBASE_APP_ID" \
        --groups "testers" \
        --release-notes "$RELEASE_NOTES"
    echo "✅ Successfully distributed to Firebase App Distribution"
else
    echo "⚠️ Warning: Service account key not found, skipping Firebase distribution"
fi

# For production builds, you would typically use Fastlane or Xcode Cloud
if [[ "$BUILD_TYPE" == "release" && "$SIMULATION_MODE" != "true" ]]; then
    echo "📤 Production iOS build completed"
    echo "Next steps for distribution:"
    echo "  1. Set up Fastlane in ios/fastlane/"
    echo "  2. Configure match for code signing"
    echo "  3. Add certificates and provisioning profiles to CI secrets"
    echo "  4. Use Fastlane to upload to TestFlight or App Store"
    echo ""
    echo "Example Fastlane setup:"
    echo "  fastlane beta  # Upload to TestFlight"
    echo "  fastlane release  # Upload to App Store"
elif [[ "$BUILD_TYPE" == "release" ]]; then
    echo "📤 Simulated production iOS build completed"
    echo "In a real macOS environment, this would be uploaded to TestFlight"
else
    echo "📤 Debug iOS build completed"
    echo "The app can be installed on iOS simulators"
fi

echo "🎉 iOS distribution completed!"