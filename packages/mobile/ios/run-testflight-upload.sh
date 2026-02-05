#!/bin/bash

# TestFlight Upload Script for Modulo Squares iOS
# This script sets up the environment and runs fastlane beta lane

set -e

echo "🚀 Starting TestFlight Upload for Modulo Squares iOS"
echo "=================================================="

# Get the repository root based on this script's directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
ENV_FILE="$REPO_ROOT/.env.development"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env.development not found at $ENV_FILE"
    exit 1
fi

# Load environment variables from .env.development
export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)

# Convert MATCH_GIT_URL from SSH to HTTPS with PAT for authentication
# Original format: git@github.com:mnelson3/nelson-grey.git
# Target format: https://oauth2:TOKEN@github.com/mnelson3/nelson-grey.git
if [[ "$MATCH_GIT_URL" =~ ^git@github\.com: ]]; then
    REPO_PATH=$(echo "$MATCH_GIT_URL" | sed 's/^git@github\.com://; s/\.git$//')
    MATCH_GIT_URL="https://oauth2:${MATCH_GIT_URL_TOKEN}@github.com/${REPO_PATH}.git"
    export MATCH_GIT_URL
    echo "✅ Converted MATCH_GIT_URL to HTTPS with PAT for authentication"
fi

# Map APP_STORE_CONNECT_* variables to ASC_* (App Store Connect API key naming)
export ASC_KEY_ID="$APP_STORE_CONNECT_KEY_ID"
export ASC_ISSUER_ID="$APP_STORE_CONNECT_ISSUER_ID"
export ASC_PRIVATE_KEY="$APP_STORE_CONNECT_KEY"

# Set Fastlane skip update check
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_HIDE_CHANGELOG=1
export FASTLANE_DISABLE_COLORS=0

# Set keychain password if not already set
if [ -z "$MATCH_KEYCHAIN_PASSWORD" ]; then
    export MATCH_KEYCHAIN_PASSWORD="$KEYCHAIN_PASSWORD"
fi

# Set NELSON_GREY_PAT for Match repo write operations if not already set
if [ -z "$NELSON_GREY_PAT" ]; then
    export NELSON_GREY_PAT="$MATCH_GIT_URL_TOKEN"
fi

# Ensure the keychain is properly configured
echo "🔐 Preparing keychain for code signing..."
KEYCHAIN_PATH=~/Library/Keychains/fastlane_tmp_keychain-db
if [ -f "$KEYCHAIN_PATH" ]; then
    # Unlock the keychain to prevent prompts during certificate import
    security unlock-keychain -p "$MATCH_KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" 2>/dev/null || true
    # Set key partition list to allow fastlane to use certificates without prompts
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$MATCH_KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" 2>/dev/null || true
    echo "✅ Keychain prepared"
fi

echo "✅ Environment variables loaded:"
echo "   App ID: $FASTLANE_APPLE_ID"
echo "   Team ID: $FASTLANE_TEAM_ID"
echo "   Bundle ID: com.nelsongrey.modulosquares.app.ios"
echo "   Match Repo: $MATCH_GIT_URL"
echo "   Feedback Email: $BETA_FEEDBACK_EMAIL"
echo ""

# Verify Flutter dependencies
echo "📦 Verifying Flutter dependencies..."
cd "$REPO_ROOT/packages/mobile"
flutter pub get
cd "$REPO_ROOT/packages/mobile/ios"

echo ""
echo "🔨 Running Fastlane beta lane..."
echo "   This will:"
echo "   1. Sync code signing certificates"
echo "   2. Build the iOS app for release"
echo "   3. Sign the IPA"
echo "   4. Upload to TestFlight"
echo ""

# Run fastlane beta lane
APP_VERSION=$(grep "version:" "$REPO_ROOT/packages/mobile/pubspec.yaml" | head -1 | awk '{print $2}')
fastlane beta release_notes:"Build $APP_VERSION from TestFlight upload script"

echo ""
echo "✅ TestFlight upload completed!"
echo "📱 Check App Store Connect to verify the build is processing"
echo "🔍 Build status: https://appstoreconnect.apple.com"
