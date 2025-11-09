#!/bin/bash
# setup-macos-runner.sh
# Script to set up a self-hosted macOS runner for GitHub Actions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🍎 Setting up macOS Self-Hosted Runner${NC}"
echo -e "${BLUE}=====================================${NC}"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script is designed for macOS only${NC}"
    exit 1
fi

# Check for required tools
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Check Xcode
if ! xcode-select -p &> /dev/null; then
    echo -e "${RED}❌ Xcode command line tools not found${NC}"
    echo -e "${YELLOW}💡 Install with: xcode-select --install${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Xcode command line tools found${NC}"

# Check Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
echo -e "${GREEN}✅ Homebrew found${NC}"

# Install required packages
echo -e "${YELLOW}📦 Installing required packages...${NC}"
brew update
brew install git curl wget jq

# Install Flutter if not present
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}🦋 Installing Flutter...${NC}"
    git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
    export PATH="$PATH:$HOME/flutter/bin"
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
    flutter doctor --android-licenses
fi
echo -e "${GREEN}✅ Flutter ready${NC}"

# Install Node.js if not present
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}🟢 Installing Node.js...${NC}"
    brew install node
fi
echo -e "${GREEN}✅ Node.js ready${NC}"

# Install Ruby and Fastlane
echo -e "${YELLOW}💎 Installing Ruby and Fastlane...${NC}"
brew install ruby
gem install fastlane

echo -e "${GREEN}✅ macOS runner prerequisites installed!${NC}"
echo ""
echo -e "${BLUE}🎯 Next steps:${NC}"
echo "1. Run: ./scripts/manage-macos-runner.sh configure"
echo "2. Run: ./scripts/manage-macos-runner.sh install"
echo "3. Run: ./scripts/manage-macos-runner.sh start"
echo ""
echo -e "${YELLOW}📋 This runner will save ~98% on iOS build costs!${NC}"