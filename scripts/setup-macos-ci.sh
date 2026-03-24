#!/bin/bash
# 🚀 Modulo Squares - macOS CI Setup (non-interactive signing)
# Configures non-interactive CI behavior without direct signing prompts

set -e

echo "🍎 Setting up macOS environment for zero-touch iOS builds (non-interactive signing)..."
echo "👤 Current user: $(whoami)"
echo "🏠 Home directory: $HOME"

# Configure git to avoid interactive prompts
echo "🔧 Configuring git..."
git config --global user.name "Modulo Squares CI"
git config --global user.email "ci@modulo-squares.com"
git config --global core.askpass ""
git config --global credential.helper ""

# Set CI-safe environment variables
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_HIDE_CHANGELOG=1
export FASTLANE_DISABLE_COLORS=0
export CI=true
export FASTLANE_CI=true

# Signing strategy: automatic signing + App Store Connect API key
export MODULO_SIGNING_MODE="automatic"
export MODULO_KEYCHAINLESS_SIGNING="true"

echo "✅ macOS environment configured for non-interactive zero-touch operations"
echo "ℹ️  Signing mode: automatic (App Store Connect API key)"
