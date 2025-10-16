#!/bin/bash

# Modulo Squares Deployment Script
# Usage: ./scripts/deploy.sh [dev|staging|prod]

set -e

ENVIRONMENT=${1:-prod}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Validate environment
case $ENVIRONMENT in
    dev|staging|prod)
        echo "🚀 Deploying to $ENVIRONMENT environment"
        ;;
    *)
        echo "❌ Invalid environment: $ENVIRONMENT"
        echo "Usage: $0 [dev|staging|prod]"
        exit 1
        ;;
esac

# Set Firebase project and config
case $ENVIRONMENT in
    dev)
        FIREBASE_PROJECT="modulo-squares-dev"
        FIREBASE_CONFIG="$PROJECT_ROOT/firebase.dev.json"
        ;;
    staging)
        FIREBASE_PROJECT="modulo-squares-staging"
        FIREBASE_CONFIG="$PROJECT_ROOT/firebase.staging.json"
        ;;
    prod)
        FIREBASE_PROJECT="modulo-squares-prod"
        FIREBASE_CONFIG="$PROJECT_ROOT/firebase.prod.json"
        ;;
esac

echo "📦 Building Flutter web app..."
cd "$PROJECT_ROOT/packages/app"

# Install dependencies
flutter pub get

# Build for web
flutter build web --release --web-renderer canvaskit

echo "🔥 Deploying to Firebase ($FIREBASE_PROJECT)..."

# Copy environment-specific config
cp "$FIREBASE_CONFIG" "$PROJECT_ROOT/firebase.json"

# Deploy to Firebase
cd "$PROJECT_ROOT"
firebase use "$FIREBASE_PROJECT"

if [ -n "$FIREBASE_TOKEN" ]; then
    firebase deploy --only hosting --token "$FIREBASE_TOKEN"
else
    firebase deploy --only hosting
fi

# Get deployment URL
DEPLOY_URL="https://$FIREBASE_PROJECT.web.app"

echo "✅ Deployment successful!"
echo "🌐 App is live at: $DEPLOY_URL"

# Restore original config
git checkout firebase.json

echo "🎉 Deployment complete!"