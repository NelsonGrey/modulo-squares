#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Local iOS environment preflight (keychainless)
# Validates required variables for automatic signing + ASC API key workflow
################################################################################

echo "🔎 Running local iOS signing preflight (keychainless mode)..."

required_vars=(
  APP_STORE_CONNECT_KEY_ID
  APP_STORE_CONNECT_ISSUER_ID
  APP_STORE_CONNECT_KEY
  FASTLANE_TEAM_ID
)

missing_vars=()
for var_name in "${required_vars[@]}"; do
  if [ -z "${!var_name:-}" ]; then
    missing_vars+=("$var_name")
  fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
  echo "❌ Missing required environment variables:"
  printf '  - %s\n' "${missing_vars[@]}"
  echo ""
  echo "Set these before running Fastlane lanes."
  exit 1
fi

echo "✅ Environment preflight passed"
echo "ℹ️  Using automatic signing + App Store Connect API key (no keychain setup)"
