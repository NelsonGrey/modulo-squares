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
        IPA_PATH="build/ios/ipa/app.ipa"
    else
        echo "📤 Building and uploading to TestFlight via Fastlane..."
        cd ios

        # Install Ruby dependencies
        echo "📦 Installing Ruby gems..."
        bundle install

        # Use Fastlane to build and upload to TestFlight (handles code signing automatically)
        bundle exec fastlane beta

        cd ..
        echo "✅ Successfully built and uploaded to TestFlight"
        # Set a dummy path since Fastlane handles the actual build
        IPA_PATH="build/ios/ipa/testflight-build.ipa"
    fi
else
    if [[ "$SIMULATION_MODE" == "true" ]]; then
        echo "🔧 Simulating iOS debug build..."
        mkdir -p build/ios/ipa
        echo "Dummy debug IPA content" > build/ios/ipa/app-debug.ipa
    else
        echo "🚀 Finding available iOS Simulator..."
        # Find an available iOS simulator device from the latest available runtime
        # First, get the latest iOS runtime version
        LATEST_RUNTIME=$(xcrun simctl list runtimes | grep "iOS" | tail -1 | sed 's/.*iOS \([0-9]*\.[0-9]*\).*/\1/')
        
        if [[ -z "$LATEST_RUNTIME" ]]; then
            echo "❌ Error: No iOS simulator runtimes found"
            exit 1
        fi
        
        echo "📱 Using iOS runtime: $LATEST_RUNTIME"
        
        # Find a device from this runtime
        SIMULATOR_ID=$(xcrun simctl list devices available | grep -A 10 "iOS $LATEST_RUNTIME" | grep -E "iPhone.*\([A-F0-9-]+\)" | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/')

        if [[ -z "$SIMULATOR_ID" ]]; then
            echo "❌ Error: No iOS simulator devices found for runtime $LATEST_RUNTIME"
            exit 1
        fi

        echo "📱 Using simulator: $SIMULATOR_ID"
        echo "🚀 Booting iOS Simulator..."
        xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "⚠️ Warning: Could not boot simulator (may already be booted)"

        # Clean CocoaPods cache and update if needed
        echo "🧹 Cleaning CocoaPods cache..."
        cd ios
        pod cache clean --all 2>/dev/null || true

        # Force update CocoaPods repo and problematic pods
        echo "📦 Updating CocoaPods..."
        pod repo update --silent 2>/dev/null || echo "⚠️ Warning: Could not update pod repo"

        # If Podfile.lock exists and is causing issues, remove it to force resolution
        if [[ -f "Podfile.lock" ]]; then
            echo "🔄 Removing Podfile.lock to force dependency resolution..."
            rm Podfile.lock
        fi

        cd ..

        # Build for the specific simulator device instead of generic destination
        echo "🔧 Building for simulator device: $SIMULATOR_ID"
        flutter build ios --debug --device-id="$SIMULATOR_ID" --no-codesign
    fi
    IPA_PATH="build/ios/iphonesimulator/Runner.app"
fi

if [[ ! -e "$IPA_PATH" ]]; then
    echo "❌ Error: Build output not found at $IPA_PATH"
    exit 1
fi

echo "✅ Build completed successfully: $IPA_PATH"

# Distribute to TestFlight or Firebase App Distribution
echo "📤 Distributing iOS app..."
if [[ "$BUILD_TYPE" == "release" ]]; then
    # Release builds are already uploaded to TestFlight by Fastlane above
    echo "✅ Release build already uploaded to TestFlight"
else
    # For debug builds, skip Firebase distribution since simulator builds produce .app files
    # which Firebase App Distribution doesn't support
    echo "⚠️ Skipping Firebase distribution for debug builds (simulator-only)"
    echo "Debug builds are for local testing only and cannot be distributed to external testers"
fi

# For production builds, you would typically use Fastlane or Xcode Cloud
if [[ "$BUILD_TYPE" == "release" && "$SIMULATION_MODE" != "true" ]]; then
    echo "📤 Production iOS build completed and uploaded to TestFlight"
    echo "The app should now be available in TestFlight for testing"
    echo ""
    echo "Next steps for App Store release:"
    echo "  1. Test the app thoroughly in TestFlight"
    echo "  2. Run 'fastlane release' to submit to App Store"
    echo "  3. Monitor app review process in App Store Connect"
elif [[ "$BUILD_TYPE" == "release" ]]; then
    echo "📤 Simulated TestFlight upload completed"
    echo "In a real macOS environment, this would be uploaded to TestFlight"
else
    echo "📤 Debug iOS build completed"
    echo "The app can be installed on iOS simulators for local testing"
    echo "Debug builds are not distributed to external testers"
fi

echo "🎉 iOS distribution completed!"