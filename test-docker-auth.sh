#!/bin/bash
echo "🧪 Testing Docker Authentication (Plain Text)"
echo "============================================="
echo ""
echo "Enter your Docker Hub credentials:"
read -p "👤 Username: " USERNAME
read -p "🔑 PAT Token: " -s TOKEN
echo ""
echo ""

if [ -z "$USERNAME" ] || [ -z "$TOKEN" ]; then
    echo "❌ Credentials required"
    exit 1
fi

echo "🔄 Testing authentication..."
echo "$TOKEN" | docker login --username "$USERNAME" --password-stdin

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! Docker authentication works with plain text credentials"
    echo ""
    echo "🧪 Test pull:"
    docker pull hello-world > /dev/null 2>&1 && echo "✅ Docker pull works!" || echo "❌ Docker pull failed"
    echo ""
    echo "🏗️  Ready to build containers:"
    echo "   cd packages/web && docker build -t modulo-squares-web ."
    echo "   cd packages/functions && docker build -t modulo-squares-api ."
else
    echo ""
    echo "❌ Authentication failed - check credentials"
fi
