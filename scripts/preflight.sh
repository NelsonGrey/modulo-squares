#!/usr/bin/env bash
# scripts/preflight.sh
# Run before every TestFlight upload.
# Exits non-zero as soon as any gate fails.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE_DIR="$REPO_ROOT/packages/mobile"

step() { echo ""; echo "==> $*"; }
ok()   { echo "    ✓ $*"; }
fail() { echo "    ✗ $*"; exit 1; }

step "Flutter analyze"
cd "$MOBILE_DIR"
if flutter analyze --no-pub; then
  ok "No analysis issues"
else
  fail "flutter analyze found issues — fix before uploading"
fi

step "Flutter test"
if flutter test --no-pub; then
  ok "All tests passed"
else
  fail "Tests failed — fix before uploading"
fi

step "iOS simulator build (smoke)"
if flutter build ios --simulator --no-pub; then
  ok "Simulator build succeeded"
else
  fail "iOS simulator build failed"
fi

step "Version check"
VERSION=$(grep '^version:' "$MOBILE_DIR/pubspec.yaml" | awk '{print $2}')
echo "    Current version: $VERSION"
echo "    Reminder: bump the build number (+N) before each upload to App Store Connect."

step "Preflight complete"
echo ""
echo "All local gates passed. Before uploading to TestFlight:"
echo "  1. Verify signing certificate and provisioning profile are valid."
echo "  2. Confirm production Firebase project is configured."
echo "  3. Confirm production AdMob ad unit IDs are set."
echo "  4. Run a release build on a real device."
echo "  5. See docs/TESTFLIGHT_READINESS_CHECKLIST.md for full checklist."
echo ""
