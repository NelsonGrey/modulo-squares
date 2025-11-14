#!/bin/bash

# Branch Protection Setup Script
# This script provides commands to set up branch protection rules via GitHub CLI

set -e

echo "🛡️  Modulo Squares Branch Protection Setup"
echo "=========================================="
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI is not installed."
    echo "Install it from: https://cli.github.com/"
    echo ""
    echo "Manual setup instructions:"
    echo "Go to: https://github.com/mnelson3/modulo-squares/settings/branches"
    echo "Follow the rules in BRANCH_PROTECTION.md"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "Run: gh auth login"
    exit 1
fi

echo "📋 Setting up branch protection rules..."
echo ""

# Main branch protection
echo "🔒 Setting up main branch protection..."
gh api repos/mnelson3/modulo-squares/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test","build-and-deploy"]}' \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false \
  --field block_creations=false \
  --field enforce_admins=true

echo "✅ Main branch protection set up"
echo ""

# Staging branch protection
echo "🔒 Setting up staging branch protection..."
gh api repos/mnelson3/modulo-squares/branches/staging/protection \
  --method PUT \
  --field required_status_checks='{"strict":false,"contexts":["test","build-and-deploy"]}' \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false \
  --field block_creations=false \
  --field enforce_admins=true

echo "✅ Staging branch protection set up"
echo ""

# Develop branch protection
echo "🔒 Setting up develop branch protection..."
gh api repos/mnelson3/modulo-squares/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{"strict":false,"contexts":["test"]}' \
  --field required_pull_request_reviews=null \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false \
  --field block_creations=false \
  --field enforce_admins=true

echo "✅ Develop branch protection set up"
echo ""

echo "🎉 Branch protection rules configured successfully!"
echo ""
echo "📋 Summary:"
echo "- main: Requires PR reviews + status checks (test, build-and-deploy)"
echo "- staging: Requires PR reviews + status checks (test, build-and-deploy)"
echo "- develop: Requires status checks (test) only"
echo ""
echo "🔗 View rules: https://github.com/mnelson3/modulo-squares/settings/branches"