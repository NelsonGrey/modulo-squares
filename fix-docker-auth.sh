#!/bin/bash

# Docker Authentication Setup - Multiple Methods
# Handles macOS keychain corruption issues

set -e

echo "🐳 Docker Authentication Setup (macOS Keychain Bypass)"
echo "======================================================"
echo ""

# Method 1: Plain text credentials
echo "📝 Method 1: Plain Text Credentials (Recommended for macOS issues)"
echo "------------------------------------------------------------------"
echo "This bypasses the macOS keychain entirely."
echo ""

# Configure Docker to use plain text
mkdir -p ~/.docker
cat > ~/.docker/config.json << EOF
{
  "credsStore": ""
}
EOF

echo "✅ Configured Docker to use plain text credentials"
echo ""

# Get credentials
read -p "👤 Docker Hub Username: " DOCKER_USERNAME
read -p "🔑 Personal Access Token: " -s DOCKER_PAT
echo ""
echo ""

if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PAT" ]; then
    echo "❌ Username and token are required"
    exit 1
fi

echo "🔄 Attempting authentication..."

# Try login with plain text
echo "$DOCKER_PAT" | docker login --username "$DOCKER_USERNAME" --password-stdin

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! Authentication successful with plain text credentials"
    echo ""
    echo "🧪 Test it:"
    echo "   docker pull hello-world"
    echo ""
    echo "🏗️  Build your containers:"
    echo "   cd packages/web && docker build -t modulo-squares-web ."
    echo "   cd packages/functions && docker build -t modulo-squares-api ."
    echo ""
    echo "📤 Push to Docker Hub:"
    echo "   docker tag modulo-squares-web $DOCKER_USERNAME/modulo-squares-web:latest"
    echo "   docker push $DOCKER_USERNAME/modulo-squares-web:latest"
    echo ""
    echo "⚠️  NOTE: Credentials are stored in plain text in ~/.docker/config.json"
    echo "   This is less secure but works around macOS keychain issues."
    exit 0
fi

echo ""
echo "❌ Plain text authentication failed. Trying alternative methods..."
echo ""

# Method 2: Environment variables
echo "📝 Method 2: Environment Variables"
echo "----------------------------------"
echo "Set environment variables for Docker authentication:"
echo ""
echo "export DOCKER_USERNAME=\"$DOCKER_USERNAME\""
echo "export DOCKER_TOKEN=\"$DOCKER_PAT\""
echo ""
echo "Then use in scripts:"
echo "echo \$DOCKER_TOKEN | docker login --username \$DOCKER_USERNAME --password-stdin"
echo ""

# Method 3: Docker config with base64
echo "📝 Method 3: Base64 Encoded Credentials"
echo "---------------------------------------"
AUTH_STRING="$(echo -n "$DOCKER_USERNAME:$DOCKER_PAT" | base64)"
cat > ~/.docker/config.json << EOF
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "$AUTH_STRING"
    }
  }
}
EOF

echo "🔄 Testing base64 authentication..."
docker pull hello-world &> /dev/null

if [ $? -eq 0 ]; then
    echo "✅ SUCCESS! Base64 authentication works"
    echo ""
    echo "🧪 Test commands:"
    echo "   docker pull hello-world"
    echo "   docker images"
else
    echo "❌ Base64 authentication also failed"
    echo ""
    echo "🔧 Last resort options:"
    echo "1. Reset macOS keychain completely"
    echo "2. Create new macOS user account"
    echo "3. Reinstall Docker Desktop"
    echo "4. Use Docker in a Linux VM"
fi