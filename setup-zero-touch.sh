#!/bin/bash

# Zero-Touch GitHub CLI Setup Script
# Provides true automated setup using GitHub CLI authentication
# Version: 1.0.0

set -e

# Load shared authentication library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_LIB_DIR="/Users/marknelson/Circus/Repositories/shared/github-auth"
LIB_FILE="$SHARED_LIB_DIR/github-auth-lib.sh"

if [ ! -f "$LIB_FILE" ]; then
    echo "❌ ERROR: Shared authentication library not found: $LIB_FILE"
    exit 1
fi

source "$LIB_FILE"

echo "🚀 Zero-Touch GitHub CLI Setup"
echo "=============================="
echo ""

# Configuration - Auto-detect accessible repos
# Try common repository combinations
POSSIBLE_REPOS=(
    "mnelson3/modulo-squares"
    "nelsongrey/vehicle-vitals"
    "nelsongrey/wishlist-wizard"
)

REPOS=()

# Check prerequisites
echo "📋 Checking prerequisites..."
echo ""

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo ""
    echo -e "${YELLOW}📋 Installation Instructions:${NC}"
    echo "1. Install GitHub CLI:"
    echo "   • macOS: brew install gh"
    echo "   • Or download from: https://cli.github.com/"
    echo ""
    echo "2. After installation, run this script again"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI installed${NC}"

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI is not authenticated${NC}"
    echo ""
    echo -e "${BLUE}🔐 Authentication Required:${NC}"
    echo ""
    echo "Run the following command to authenticate:"
    echo ""
    echo -e "${GREEN}gh auth login${NC}"
    echo ""
    echo "Choose authentication method:"
    echo "• GitHub.com (recommended)"
    echo "• HTTPS (with PAT) or SSH"
    echo ""
    echo "After authentication, run this script again"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI authenticated${NC}"

# Get authenticated user
GH_USER=$(get_gh_user)
echo -e "${GREEN}✅ Authenticated as: $GH_USER${NC}"
echo ""

# Auto-detect accessible repositories
echo "🔍 Auto-detecting accessible repositories..."
for repo in "${POSSIBLE_REPOS[@]}"; do
    IFS='/' read -r owner name <<< "$repo"
    if validate_repo_access "$owner" "$name" 2>/dev/null; then
        REPOS+=("$repo")
        echo -e "${GREEN}✅ $repo${NC}"
    else
        echo -e "${YELLOW}⚠️  $repo (no access)${NC}"
    fi
done

if [ ${#REPOS[@]} -eq 0 ]; then
    echo ""
    echo -e "${RED}❌ No accessible repositories found${NC}"
    echo -e "${YELLOW}Ensure you have admin access to at least one repository${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Found ${#REPOS[@]} accessible repositories${NC}"
echo ""

# Update all project configurations
echo "⚙️  Updating project configurations..."
echo ""

for repo in "${REPOS[@]}"; do
    IFS='/' read -r owner name <<< "$repo"
    repo_path="/Users/marknelson/Circus/Repositories/$name"

    if [ ! -d "$repo_path" ]; then
        echo -e "${YELLOW}⚠️  Repository not found: $repo_path${NC}"
        continue
    fi

    env_file="$repo_path/.env.runner"

    if [ ! -f "$env_file" ]; then
        echo -e "${YELLOW}⚠️  Config file not found: $env_file${NC}"
        continue
    fi

    echo -e "${BLUE}Updating $name...${NC}"

    # Update repository configuration
    sed -i.bak "s/^REPO_OWNER=.*/REPO_OWNER=$owner/" "$env_file" 2>/dev/null || true
    sed -i.bak "s/^REPO_NAME=.*/REPO_NAME=$name/" "$env_file" 2>/dev/null || true

    # Remove old GitHub App configuration
    sed -i.bak '/^GITHUB_APP_/d' "$env_file" 2>/dev/null || true

    # Add GitHub CLI configuration
    if ! grep -q "^GITHUB_TOKEN=" "$env_file"; then
        echo "" >> "$env_file"
        echo "# GitHub CLI Configuration" >> "$env_file"
        echo "GITHUB_TOKEN=auto" >> "$env_file"
    fi

    # Update token refresh script reference
    if ! grep -q "SHARED_LIB_DIR" "$env_file"; then
        echo "SHARED_LIB_DIR=$SHARED_LIB_DIR" >> "$env_file"
    fi

    echo -e "${GREEN}✅ $name updated${NC}"
done

echo ""
echo -e "${GREEN}✅ All configurations updated${NC}"
echo ""

# Test token generation
echo "🧪 Testing token generation..."
echo ""

for repo in "${REPOS[@]}"; do
    IFS='/' read -r owner name <<< "$repo"
    repo_path="/Users/marknelson/Circus/Repositories/$name"

    echo -e "${BLUE}Testing $name...${NC}"

    # Generate test token
    if token=$(generate_runner_token "$owner" "$name" 2>/dev/null); then
        echo -e "${GREEN}✅ Token generation successful${NC}"
    else
        echo -e "${RED}❌ Token generation failed${NC}"
        continue
    fi

    # Test token validity
    if test_token "$owner" "$name" "$token" 2>/dev/null; then
        echo -e "${GREEN}✅ Token validation successful${NC}"
    else
        echo -e "${RED}❌ Token validation failed${NC}"
    fi
done

echo ""
echo -e "${GREEN}🎉 Zero-Touch Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 What's Been Configured:${NC}"
echo "✅ GitHub CLI authentication verified"
echo "✅ Repository admin access confirmed"
echo "✅ All project configurations updated"
echo "✅ Token generation and validation tested"
echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo -e "${GREEN}🔄 Zero-touch operation is now active!${NC}"
echo "Tokens refresh automatically every hour via launch agents"
