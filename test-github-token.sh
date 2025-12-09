#!/bin/bash

# Test script to verify GitHub token access to nelson-grey repository

echo "🔍 Testing GitHub token access to nelson-grey repository..."
echo ""

# Check if token is provided
if [ -z "$1" ]; then
    echo "❌ Usage: $0 <github_token>"
    echo "Example: $0 REDACTED_GITHUB_TOKEN"
    exit 1
fi

TOKEN="$1"
REPO_URL="https://oauth2:$TOKEN@github.com/mnelson3/nelson-grey.git"
TEST_DIR="/tmp/test-certificates-$(date +%s)"

echo "📁 Testing repository access..."
echo "Repository: https://github.com/mnelson3/nelson-grey"
echo "Test directory: $TEST_DIR"
echo ""

# Try to clone the repository
if git clone "$REPO_URL" "$TEST_DIR" 2>/dev/null; then
    echo "✅ SUCCESS: Token has access to the repository!"
    echo "Repository contents:"
    ls -la "$TEST_DIR"
    rm -rf "$TEST_DIR"
else
    echo "❌ FAILED: Token does not have access or repository doesn't exist"
    echo ""
    echo "Possible issues:"
    echo "1. Repository doesn't exist"
    echo "2. Repository is not private"
    echo "3. Token doesn't have 'repo' scope"
    echo "4. Token is expired or invalid"
    echo "5. Repository is not accessible to the token owner"
fi