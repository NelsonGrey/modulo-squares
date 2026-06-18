#!/usr/bin/env bash

set -euo pipefail

SHOW_VERSIONS=false
if [[ "${1:-}" == "--show-versions" ]]; then
  SHOW_VERSIONS=true
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: This script must run on macOS." >&2
  exit 1
fi

failures=0
warnings=0

declare -a remediation

check_required_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    echo "PASS: command '$name' found at $(command -v "$name")"
  else
    echo "FAIL: command '$name' not found"
    failures=$((failures + 1))
  fi
}

check_optional_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    echo "PASS: optional command '$name' found at $(command -v "$name")"
  else
    echo "WARN: optional command '$name' not found"
    warnings=$((warnings + 1))
  fi
}

echo "iOS runner readiness check"
echo "Host: $(hostname)"
echo "macOS: $(sw_vers -productVersion)"
echo

check_required_command xcodebuild
check_required_command xcode-select
check_required_command ruby
check_optional_command pod
check_optional_command flutter

echo

if command -v xcode-select >/dev/null 2>&1; then
  dev_dir="$(xcode-select -p 2>/dev/null || true)"
  if [[ -n "$dev_dir" ]]; then
    echo "PASS: active developer directory: $dev_dir"
  else
    echo "FAIL: no active developer directory configured"
    failures=$((failures + 1))
    remediation+=("sudo xcode-select -s /Applications/Xcode.app/Contents/Developer")
  fi
fi

if command -v xcodebuild >/dev/null 2>&1; then
  if /usr/bin/xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
    echo "PASS: Xcode first-launch status is ready"
  else
    echo "FAIL: Xcode first-launch/license status is not ready"
    failures=$((failures + 1))
    remediation+=("sudo xcodebuild -license accept")
    remediation+=("sudo xcodebuild -runFirstLaunch")
  fi
fi

if [[ "$SHOW_VERSIONS" == "true" ]]; then
  echo
  echo "Detected versions"
  if command -v xcodebuild >/dev/null 2>&1; then
    xcodebuild -version || true
  fi
  if command -v ruby >/dev/null 2>&1; then
    ruby --version || true
  fi
  if command -v pod >/dev/null 2>&1; then
    pod --version || true
  fi
  if command -v flutter >/dev/null 2>&1; then
    flutter --version | head -n 1 || true
  fi
fi

echo
echo "Summary: failures=$failures warnings=$warnings"

if (( failures > 0 )); then
  echo "Readiness check failed."
  if (( ${#remediation[@]} > 0 )); then
    echo "Suggested remediation steps:"
    for step in "${remediation[@]}"; do
      echo "  - $step"
    done
  fi
  exit 1
fi

echo "Readiness check passed."
