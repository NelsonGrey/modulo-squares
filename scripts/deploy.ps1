# Modulo Squares Deployment Script for Windows
# Usage: .\scripts\deploy.ps1 [dev|staging|prod]

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "prod"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$AppDir = Join-Path $ProjectRoot "packages\app"

Write-Host "🚀 Deploying to $Environment environment" -ForegroundColor Green

# Set Firebase project and config
switch ($Environment) {
    "dev" {
        $FirebaseProject = "modulo-squares-dev"
        $FirebaseConfig = Join-Path $ProjectRoot "firebase.dev.json"
        $FirebaseTokenVar = "FIREBASE_TOKEN_DEVELOPMENT"
    }
    "staging" {
        $FirebaseProject = "modulo-squares-staging"
        $FirebaseConfig = Join-Path $ProjectRoot "firebase.staging.json"
        $FirebaseTokenVar = "FIREBASE_TOKEN_STAGING"
    }
    "prod" {
        $FirebaseProject = "modulo-squares-prod"
        $FirebaseConfig = Join-Path $ProjectRoot "firebase.prod.json"
        $FirebaseTokenVar = "FIREBASE_TOKEN_PRODUCTION"
    }
}

Write-Host "📦 Building Flutter web app..." -ForegroundColor Blue
Set-Location $AppDir

# Install dependencies
flutter pub get

# Build for web
flutter build web --release --web-renderer canvaskit

Write-Host "🔥 Deploying to Firebase ($FirebaseProject)..." -ForegroundColor Yellow

# Copy environment-specific config
Copy-Item $FirebaseConfig (Join-Path $ProjectRoot "firebase.json") -Force

# Deploy to Firebase
Set-Location $ProjectRoot
firebase use $FirebaseProject

$token = [Environment]::GetEnvironmentVariable($FirebaseTokenVar)
if ($token) {
    firebase deploy --only hosting --token $token
} else {
    firebase deploy --only hosting
}

# Get deployment URL
$DeployUrl = "https://$FirebaseProject.web.app"

Write-Host "✅ Deployment successful!" -ForegroundColor Green
Write-Host "🌐 App is live at: $DeployUrl" -ForegroundColor Cyan

# Restore original config
git checkout firebase.json

Write-Host "🎉 Deployment complete!" -ForegroundColor Green