#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Local iOS development script
# Sets up environment and runs Fastlane commands in non-interactive signing mode
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Modulo Squares iOS Local Development${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "packages/mobile/ios/fastlane/Fastfile" ]; then
    echo -e "${RED}❌ Error: Not in modulo-squares repository root${NC}"
    echo "Please run this script from the repository root directory"
    exit 1
fi

# Run local iOS preflight
echo -e "${YELLOW}🔐 Validating local iOS signing environment...${NC}"
"$SCRIPT_DIR/setup-local-signing.sh"

# Change to iOS directory
cd packages/mobile/ios

# Set Ruby version for compatibility
if command -v rbenv >/dev/null 2>&1; then
    echo -e "${YELLOW}🔧 Switching to Ruby 3.2.2 for Fastlane compatibility...${NC}"
    rbenv local 3.2.2 2>/dev/null || echo -e "${YELLOW}⚠️  Could not set local Ruby version, using system Ruby${NC}"
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}📝 Creating .env file for Fastlane...${NC}"
    cat > .env << EOF
# Apple Developer Account
FASTLANE_APPLE_ID=${FASTLANE_APPLE_ID:-""}
FASTLANE_PASSWORD=${FASTLANE_PASSWORD:-""}
FASTLANE_TEAM_ID=${FASTLANE_TEAM_ID:-""}
FASTLANE_ITC_TEAM_ID=${FASTLANE_ITC_TEAM_ID:-""}

# App Store Connect API Key
APP_STORE_CONNECT_KEY_ID=${APP_STORE_CONNECT_KEY_ID:-""}
APP_STORE_CONNECT_ISSUER_ID=${APP_STORE_CONNECT_ISSUER_ID:-""}
APP_STORE_CONNECT_KEY=${APP_STORE_CONNECT_KEY:-""}

# Match Configuration
MATCH_GIT_URL=https://oauth2:${MATCH_GIT_URL_TOKEN:-""}@github.com/mnelson3/nelson-grey.git
MATCH_PASSWORD=${MATCH_PASSWORD:-""}

# TestFlight Configuration
BETA_FEEDBACK_EMAIL=${BETA_FEEDBACK_EMAIL:-""}
EOF
    echo -e "${GREEN}✅ Created .env file${NC}"
    echo -e "${YELLOW}⚠️  Please edit packages/mobile/ios/.env with your credentials${NC}"
fi

# Check if required environment variables are set
MISSING_VARS=()
[ -z "${FASTLANE_APPLE_ID:-}" ] && MISSING_VARS+=("FASTLANE_APPLE_ID")
[ -z "${FASTLANE_PASSWORD:-}" ] && MISSING_VARS+=("FASTLANE_PASSWORD")
[ -z "${FASTLANE_TEAM_ID:-}" ] && MISSING_VARS+=("FASTLANE_TEAM_ID")
[ -z "${MATCH_GIT_URL_TOKEN:-}" ] && MISSING_VARS+=("MATCH_GIT_URL_TOKEN")
[ -z "${MATCH_PASSWORD:-}" ] && MISSING_VARS+=("MATCH_PASSWORD")

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing required environment variables:${NC}"
    printf '  - %s\n' "${MISSING_VARS[@]}"
    echo ""
    echo -e "${YELLOW}💡 Set them in your shell or add them to packages/mobile/ios/.env${NC}"
    echo -e "${YELLOW}💡 Example: export FASTLANE_APPLE_ID=\"your-apple-id@example.com\"${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Environment setup complete!${NC}"
echo ""

# Parse command line arguments
COMMAND=${1:-"help"}

case $COMMAND in
    "sync")
        echo -e "${BLUE}🔄 Validating signing configuration...${NC}"
        bundle exec fastlane sync_signing
        ;;
    "build")
        echo -e "${BLUE}🏗️ Building iOS app...${NC}"
        bundle exec fastlane build_development
        ;;
    "test")
        echo -e "${BLUE}🧪 Running tests...${NC}"
        bundle exec fastlane test_and_build
        ;;
    "beta")
        echo -e "${BLUE}📤 Building and uploading to TestFlight...${NC}"
        bundle exec fastlane beta
        ;;
    "release")
        echo -e "${BLUE}🚀 Building and uploading to App Store...${NC}"
        bundle exec fastlane full_release_pipeline submit_to_app_store:true
        ;;
    "clean")
        echo -e "${BLUE}🧹 Cleaning build artifacts...${NC}"
        rm -rf ../build ../Pods ../Podfile.lock ~/Library/Developer/Xcode/DerivedData/*
        ;;
    "help"|*)
        echo -e "${BLUE}📋 Available commands:${NC}"
        echo "  sync     - Sync certificates and provisioning profiles"
        echo "  build    - Build iOS app in debug mode"
        echo "  test     - Run tests and build debug version"
        echo "  beta     - Build and upload to TestFlight"
        echo "  release  - Build and upload to App Store"
        echo "  clean    - Clean build artifacts"
        echo ""
        echo -e "${YELLOW}💡 Usage: $0 <command>${NC}"
        echo -e "${YELLOW}💡 Example: $0 sync${NC}"
        ;;
esac