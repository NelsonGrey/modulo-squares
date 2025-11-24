#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Local development keychain setup for iOS builds
# Creates a dedicated development keychain that doesn't require password prompts
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
DEV_KEYCHAIN_NAME="modulo-squares-dev.keychain-db"
DEV_KEYCHAIN_PATH="$HOME/Library/Keychains/$DEV_KEYCHAIN_NAME"
DEV_KEYCHAIN_PASSWORD="dev-password-123"

echo "🔐 Setting up local development keychain..."

# Check if development keychain already exists
if [ -f "$DEV_KEYCHAIN_PATH" ]; then
    echo "✅ Development keychain already exists at $DEV_KEYCHAIN_PATH"
else
    echo "📝 Creating development keychain: $DEV_KEYCHAIN_NAME"
    security create-keychain -p "$DEV_KEYCHAIN_PASSWORD" "$DEV_KEYCHAIN_PATH"
fi

# Add development keychain to search list if not already there
echo "🔍 Checking keychain search list..."
KEYCHAIN_LIST=$(security list-keychains -d user | tr -d '"' | tr -d ' ')
if [[ "$KEYCHAIN_LIST" != *"$DEV_KEYCHAIN_NAME"* ]]; then
    echo "➕ Adding development keychain to search list"
    security list-keychains -d user -s "$DEV_KEYCHAIN_PATH" $KEYCHAIN_LIST
else
    echo "✅ Development keychain already in search list"
fi

# Unlock the keychain
echo "🔓 Unlocking development keychain"
security unlock-keychain -p "$DEV_KEYCHAIN_PASSWORD" "$DEV_KEYCHAIN_PATH"

# Set keychain settings to not require password
echo "⚙️ Configuring keychain settings (no password prompts)"
security set-keychain-settings -u "$DEV_KEYCHAIN_PATH"

# Export environment variables for Fastlane
export MATCH_KEYCHAIN_NAME="$DEV_KEYCHAIN_NAME"
export MATCH_KEYCHAIN_PASSWORD="$DEV_KEYCHAIN_PASSWORD"

echo "✅ Development keychain setup complete!"
echo "📋 Environment variables set:"
echo "   MATCH_KEYCHAIN_NAME=$MATCH_KEYCHAIN_NAME"
echo "   MATCH_KEYCHAIN_PASSWORD=$MATCH_KEYCHAIN_PASSWORD"
echo ""
echo "🚀 You can now run Fastlane commands that will use this keychain"
echo "💡 To clean up later, run: security delete-keychain \"$DEV_KEYCHAIN_PATH\""