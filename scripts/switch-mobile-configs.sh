#!/bin/bash

# Mobile Config Switcher for Modulo Squares
# Switches Android and iOS Firebase config files based on environment

set -e

ENVIRONMENT=${1:-dev}

echo "🔄 Switching mobile configs to $ENVIRONMENT environment..."

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Error: Environment must be 'dev', 'staging', or 'prod'"
    exit 1
fi

# Android config switching
ANDROID_SRC="packages/mobile/android/app/google-services.$ENVIRONMENT.json"
ANDROID_DEST="packages/mobile/android/app/google-services.json"

if [ -f "$ANDROID_SRC" ]; then
    cp "$ANDROID_SRC" "$ANDROID_DEST"
    echo "✅ Android config switched to $ENVIRONMENT"
else
    echo "❌ Error: Android config file not found: $ANDROID_SRC"
    exit 1
fi

# iOS config switching
IOS_SRC="packages/mobile/ios/Runner/GoogleService-Info.$ENVIRONMENT.plist"
IOS_DEST="packages/mobile/ios/Runner/GoogleService-Info.plist"
IOS_INFO_PLIST="packages/mobile/ios/Runner/Info.plist"

if [ -f "$IOS_SRC" ]; then
    cp "$IOS_SRC" "$IOS_DEST"
    echo "✅ iOS config switched to $ENVIRONMENT"

    # Keep URL scheme aligned with selected Firebase iOS client id.
    IOS_REVERSED_CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" "$IOS_SRC" 2>/dev/null || true)
    if [ -n "$IOS_REVERSED_CLIENT_ID" ] && [ -f "$IOS_INFO_PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleURLTypes:0:CFBundleURLSchemes:0 $IOS_REVERSED_CLIENT_ID" "$IOS_INFO_PLIST"
        echo "✅ iOS URL scheme synced to selected environment"
    else
        echo "⚠️ Warning: Could not sync iOS URL scheme from $IOS_SRC"
    fi
else
    echo "❌ Error: iOS config file not found: $IOS_SRC"
    exit 1
fi

echo "🎉 Mobile configs successfully switched to $ENVIRONMENT environment!"