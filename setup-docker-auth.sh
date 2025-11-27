#!/bin/bash

# Docker Hub Authentication Setup Script
# Helps configure Docker Hub PAT authentication for CI/CD

set -e

echo "🐳 Docker Hub Authentication Setup"
echo "=================================="
echo ""

# Check if GitHub CLI is available
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI found"

    # Check if user is authenticated with GitHub
    if gh auth status &> /dev/null; then
        echo "✅ GitHub CLI authenticated"
    else
        echo "❌ GitHub CLI not authenticated. Run: gh auth login"
        exit 1
    fi
else
    echo "⚠️  GitHub CLI not found. Install from: https://cli.github.com/"
    echo "   Manual setup instructions in docs/DOCKER_AUTH_SETUP.md"
    exit 1
fi

echo ""
echo "📝 Step 1: Create Docker Hub Personal Access Token"
echo "   1. Go to: https://hub.docker.com/settings/security"
echo "   2. Click 'New Access Token'"
echo "   3. Name: modulo-squares-ci"
echo "   4. Permissions: Read, Write, Delete"
echo "   5. Copy the token"
echo ""

read -p "🔑 Paste your Docker Hub Personal Access Token: " -s DOCKER_PAT
echo ""
echo ""

if [ -z "$DOCKER_PAT" ]; then
    echo "❌ No token provided"
    exit 1
fi

echo "🔐 Step 2: Configure GitHub Secrets"
echo ""

# Get repository info
REPO_INFO=$(gh repo view --json owner,name)
REPO_OWNER=$(echo "$REPO_INFO" | jq -r '.owner.login')
REPO_NAME=$(echo "$REPO_INFO" | jq -r '.name')

echo "📦 Repository: $REPO_OWNER/$REPO_NAME"
echo ""

# Set Docker Hub username secret
read -p "👤 Enter your Docker Hub username: " DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    echo "❌ No username provided"
    exit 1
fi

echo "🔄 Setting up secrets..."

# Set the secrets
gh secret set DOCKERHUB_USERNAME --body "$DOCKER_USERNAME"
gh secret set DOCKERHUB_TOKEN --body "$DOCKER_PAT"

echo ""
echo "✅ Setup Complete!"
echo ""
echo "🔍 Verify secrets were set:"
echo "   gh secret list"
echo ""
echo "🚀 Next: Push to trigger the CI/CD pipeline"
echo "   git add . && git commit -m 'Add Docker authentication' && git push"
echo ""
echo "📖 More info: docs/DOCKER_AUTH_SETUP.md"