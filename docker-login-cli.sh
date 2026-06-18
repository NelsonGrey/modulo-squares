#!/bin/bash

# Docker CLI Authentication Script
# Bypasses Docker Desktop GUI authentication issues

set -e

echo "🐳 Docker CLI Authentication (Bypasses Desktop GUI)"
echo "=================================================="
echo ""

# Check if Docker CLI is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker CLI not found. Please install Docker Desktop first."
    exit 1
fi

echo "✅ Docker CLI found"
echo ""

# Check if already logged in
if docker info &> /dev/null; then
    echo "✅ Docker daemon is running"
else
    echo "⚠️  Docker daemon not accessible. Make sure Docker Desktop is running."
    exit 1
fi

echo "🔐 Docker Hub Authentication"
echo "---------------------------"
echo "If you don't have a Personal Access Token:"
echo "1. Go to: https://hub.docker.com/settings/security"
echo "2. Click 'New Access Token'"
echo "3. Name: modulo-squares-local"
echo "4. Permissions: Read, Write, Delete"
echo "5. Copy the token"
echo ""

read -p "👤 Docker Hub Username: " DOCKER_USERNAME
read -p "🔑 Personal Access Token: " -s DOCKER_PAT
echo ""
echo ""

if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PAT" ]; then
    echo "❌ Username and token are required"
    exit 1
fi

echo "🔄 Authenticating with Docker Hub..."

# Use echo to pipe the token to docker login
echo "$DOCKER_PAT" | docker login --username "$DOCKER_USERNAME" --password-stdin

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Authentication successful!"
    echo ""
    echo "🧪 Test the authentication:"
    echo "   docker pull hello-world"
    echo ""
    echo "🏗️  Build your containers:"
    echo "   cd packages/web && docker build -t modulo-squares-web ."
    echo "   cd packages/functions && docker build -t modulo-squares-api ."
    echo ""
    echo "📤 Push to Docker Hub:"
    echo "   docker tag modulo-squares-web $DOCKER_USERNAME/modulo-squares-web:latest"
    echo "   docker push $DOCKER_USERNAME/modulo-squares-web:latest"
else
    echo ""
    echo "❌ Authentication failed. Please check your credentials."
    exit 1
fi
