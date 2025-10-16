#!/bin/bash

# Firebase Setup Script for Modulo Squares
# This script helps set up Firebase projects for DEV, STAGING, and PROD environments

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔥 Modulo Squares Firebase Setup"
echo "================================="

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please login to Firebase first:"
    firebase login
fi

echo "📋 Available Firebase projects:"
firebase projects:list

echo ""
echo "⚠️  IMPORTANT: Ensure you have created the following Firebase projects:"
echo "   - modulo-squares-dev"
echo "   - modulo-squares-staging"
echo "   - modulo-squares-prod"
echo ""

read -p "Have you created these Firebase projects? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "🛑 Please create the Firebase projects first, then run this script again."
    echo "Visit: https://console.firebase.google.com"
    exit 1
fi

# Setup each environment
environments=("dev" "staging" "prod")
project_ids=("modulo-squares-dev" "modulo-squares-staging" "modulo-squares-prod")

for i in "${!environments[@]}"; do
    env="${environments[$i]}"
    project_id="${project_ids[$i]}"

    echo ""
    echo "🔧 Setting up $env environment ($project_id)..."

    # Check if project exists
    if ! firebase projects:list --json | grep -q "$project_id"; then
        echo "❌ Project $project_id not found. Please create it first."
        continue
    fi

    # Initialize Firebase in project directory
    cd "$PROJECT_ROOT"

    # Use the appropriate config file
    config_file="firebase.$env.json"
    if [ ! -f "$config_file" ]; then
        echo "❌ Config file $config_file not found!"
        continue
    fi

    # Copy config to firebase.json temporarily
    cp "$config_file" firebase.json

    # Initialize hosting for this project
    echo "🏗️  Initializing Firebase hosting for $project_id..."
    firebase use "$project_id"

    # Deploy initial hosting setup (this will create the hosting site)
    echo "🚀 Deploying initial hosting setup..."
    firebase deploy --only hosting

    echo "✅ $env environment setup complete!"
    echo "🌐 Hosting URL: https://$project_id.web.app"

    # Restore original config
    git checkout firebase.json
done

echo ""
echo "🎉 Firebase setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Add FIREBASE_TOKEN secret to GitHub repository"
echo "2. Push to develop/staging/main branches to trigger deployments"
echo "3. Check CI_CD_SETUP.md for detailed configuration instructions"
echo ""
echo "🔑 To get your Firebase token:"
echo "firebase login:ci"