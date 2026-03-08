#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Local iOS signing preflight (keychainless)
# Preferred neutral-name entrypoint.
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/setup-local-keychain.sh"
