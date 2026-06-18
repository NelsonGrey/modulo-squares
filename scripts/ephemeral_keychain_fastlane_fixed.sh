#!/usr/bin/env bash
set -euo pipefail

################################################################################
# CI Fastlane wrapper (keychainless)
# Backward-compatible wrapper name retained to avoid breaking older workflows.
################################################################################

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 \"fastlane command\""
  exit 2
fi

FASTLANE_CMD="$1"

echo "[ci-fastlane] Executing in keychainless signing mode"
export MODULO_KEYCHAINLESS_SIGNING="true"
export MODULO_SIGNING_MODE="automatic"

set -x
eval "$FASTLANE_CMD"
set +x
