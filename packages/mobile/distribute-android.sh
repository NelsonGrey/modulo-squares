#!/bin/bash

# Android App Distribution Script
# Usage: ./distribute-android.sh <build_type> <release_notes>

set -e

BUILD_TYPE=${1:-debug}
RELEASE_NOTES=${2:-"Automated build"}

echo "🚀 Starting Android app distribution..."
echo "Build Type: $BUILD_TYPE"
echo "Release Notes: $RELEASE_NOTES"

# Check if we're in the right directory
if [[ ! -f "pubspec.yaml" ]]; then
    echo "❌ Error: pubspec.yaml not found. Please run from the mobile package root."
    exit 1
fi

# Build the app
echo "📱 Building Android app..."
if [[ "$BUILD_TYPE" == "release" ]]; then
    flutter build apk --release
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
else
    flutter build apk --debug
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
fi

if [[ ! -f "$APK_PATH" ]]; then
    echo "❌ Error: APK not found at $APK_PATH"
    exit 1
fi

echo "✅ APK built successfully: $APK_PATH"

# Distribute to Firebase App Distribution
echo "📤 Distributing to Firebase App Distribution..."
if [[ -f "android/app/service-account-key.json" ]]; then
    # Authenticate with service account
    export GOOGLE_APPLICATION_CREDENTIALS="android/app/service-account-key.json"

    # Get Firebase project and app ID based on environment
    if [[ "$ENVIRONMENT" == "PRODUCTION" ]]; then
        FIREBASE_PROJECT="modulo-squares-prod"
        FIREBASE_APP_ID="1:253948321735:android:f947b74aee2ce4a79ec3e2"
    elif [[ "$ENVIRONMENT" == "STAGING" ]]; then
        FIREBASE_PROJECT="modulo-squares-staging"
        FIREBASE_APP_ID="1:838061114925:android:9a9206d7065e2e3e229aa4"
    else
        FIREBASE_PROJECT="modulo-squares-dev"
        FIREBASE_APP_ID="1:784677197785:android:d17a73b27367990061abc8"
    fi

    firebase appdistribution:distribute "$APK_PATH" \
        --project "$FIREBASE_PROJECT" \
        --app "$FIREBASE_APP_ID" \
        --groups "testers" \
        --release-notes "$RELEASE_NOTES"
    echo "✅ Successfully distributed to Firebase App Distribution"
else
    echo "⚠️ Warning: Service account key not found, skipping Firebase distribution"
fi

echo "🎉 Android distribution completed!"