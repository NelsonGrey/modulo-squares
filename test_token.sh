#!/bin/bash

# Test script for GitHub PAT authentication
# Usage: ./test_token.sh <token> <repo_url>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <github_token> <repo_url>"
    echo "Example: $0 ghp_xxx https://github.com/user/repo.git"
    exit 1
fi

TOKEN=$1
REPO_URL=$2

# Extract repo name for temp dir
REPO_NAME=$(basename "$REPO_URL" .git)
TEMP_DIR="/tmp/test_${REPO_NAME}_$(date +%s)"

echo "Testing token authentication for $REPO_URL"
echo "Cloning to $TEMP_DIR"

# Try clone with oauth2 format
OAUTH_URL=$(echo "$REPO_URL" | sed "s|https://|https://oauth2:$TOKEN@|")
echo "Using URL: ${OAUTH_URL//oauth2:$TOKEN@/***masked***@}"

if git clone "$OAUTH_URL" "$TEMP_DIR" 2>&1; then
    echo "✅ SUCCESS: Token has access to the repository"
    rm -rf "$TEMP_DIR"
    exit 0
else
    echo "❌ FAILED: Token authentication failed"
    echo "Possible issues:"
    echo "  - Token is invalid or expired"
    echo "  - Token lacks 'repo' scope"
    echo "  - Repository is private and token has no access"
    echo "  - Repository does not exist or URL is wrong"
    exit 1
fi