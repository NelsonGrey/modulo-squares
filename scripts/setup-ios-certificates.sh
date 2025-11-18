#!/bin/bash

# iOS Certificate Setup Script for modulo-squares
# This script initializes the certificates repository and generates iOS certificates using Fastlane Match

set -e

echo "🚀 Setting up iOS certificates for modulo-squares..."

# Check if we're in the right directory
if [ ! -f "packages/mobile/ios/fastlane/Fastfile" ]; then
    echo "❌ Error: Please run this script from the root of the modulo-squares repository"
    exit 1
fi

# Navigate to iOS directory
cd packages/mobile/ios

echo "📁 Working directory: $(pwd)"

# Check if MATCH_PASSWORD is set
if [ -z "$MATCH_PASSWORD" ]; then
    echo "❌ Error: MATCH_PASSWORD environment variable is not set"
    echo "Please set it with: export MATCH_PASSWORD='your_password_here'"
    exit 1
fi

# Check if MATCH_GIT_URL is set
if [ -z "$MATCH_GIT_URL" ]; then
    echo "❌ Error: MATCH_GIT_URL environment variable is not set"
    echo "Please set it with: export MATCH_GIT_URL='https://github.com/mnelson3/modulo-squares-certificates.git'"
    exit 1
fi

echo "🔐 Initializing certificates repository..."
echo "This will create a new private repository for storing certificates."
echo "Make sure you have:"
echo "1. Created the modulo-squares-certificates repository on GitHub"
echo "2. Set up SSH keys or personal access token for authentication"
echo "3. Configured the repository as private"
echo ""

read -p "Have you created the modulo-squares-certificates repository? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Please create the repository first, then run this script again."
    exit 1
fi

echo "🔑 Generating iOS certificates and provisioning profiles..."
echo "This will:"
echo "1. Create a development certificate"
echo "2. Create a distribution certificate"
echo "3. Create provisioning profiles"
echo "4. Store everything in the certificates repository"
echo ""

# Generate development certificate
echo "📝 Generating development certificate..."
bundle exec fastlane match development --force

# Generate distribution certificate and provisioning profiles
echo "📦 Generating distribution certificate and provisioning profiles..."
bundle exec fastlane match appstore --force

echo "✅ Certificate setup complete!"
echo ""
echo "Next steps:"
echo "1. Verify the certificates were uploaded to the modulo-squares-certificates repository"
echo "2. Set up the following secrets in your GitHub repository:"
echo "   - MATCH_PASSWORD: The password you used for the certificates"
echo "   - MATCH_GIT_URL: https://oauth2:gho_YOUR_TOKEN@github.com/mnelson3/modulo-squares-certificates.git"
echo "   - ASC_PRIVATE_KEY: Your App Store Connect API private key (base64 encoded)"
echo "   - ASC_KEY_ID: Your App Store Connect key ID"
echo "   - ASC_ISSUER_ID: Your App Store Connect issuer ID"
echo "   - FASTLANE_APPLE_ID: Your Apple ID email"
echo "   - FASTLANE_TEAM_ID: Your Apple Developer team ID"
echo "   - FASTLANE_ITC_TEAM_ID: Your App Store Connect team ID"
echo "   - BETA_FEEDBACK_EMAIL: Email for TestFlight feedback"
echo "3. Test the iOS build in GitHub Actions"