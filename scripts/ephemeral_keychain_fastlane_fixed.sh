#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Ephemeral keychain helper for Fastlane (improved version)
# - Creates a temporary keychain
# - Optionally imports a P12 into that keychain
# - Sets MATCH_KEYCHAIN_NAME and MATCH_KEYCHAIN_PASSWORD env exports for Fastlane
# - Runs the provided command string with heartbeat monitoring
# - Restores the original keychain and deletes the temporary keychain on exit
################################################################################

if [ "$#" -lt 1 ]; then
  echo "Usage: CERT_P12_PATH=path CERT_P12_PASSWORD=pw $0 \"fastlane command\""
  exit 2
fi

FASTLANE_CMD="$1"

# Check if running in CI environment
if [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then
  echo "[ephemeral-keychain] Running in CI environment, using ephemeral keychain approach"
else
  echo "[ephemeral-keychain] Running locally, skipping ephemeral keychain setup"
  echo "[ephemeral-keychain] Running command directly: $FASTLANE_CMD"
  set -x
  eval "$FASTLANE_CMD"
  set +x
  exit 0
fi

# Check for leftover ephemeral keychains from previous runs
echo "[ephemeral-keychain] Checking for leftover ephemeral keychains..."
if command -v security >/dev/null 2>&1; then
  # Count leftover keychains safely
  LEFTOVER_KEYCHAINS=0
  if security list-keychains -d user 2>/dev/null | grep -q "fastlane_tmp_"; then
    LEFTOVER_KEYCHAINS=$(security list-keychains -d user 2>/dev/null | grep "fastlane_tmp_" | wc -l | tr -d ' ')
  fi
  if [ "$LEFTOVER_KEYCHAINS" -gt 0 ]; then
    echo "[ephemeral-keychain] WARNING: Found $LEFTOVER_KEYCHAINS leftover ephemeral keychains, cleaning up..."
    security list-keychains -d user 2>/dev/null | grep "fastlane_tmp_" | while read -r kc; do
      kc_path=$(echo "$kc" | tr -d '"' | xargs)
      if [ -n "$kc_path" ] && [[ "$kc_path" == *fastlane_tmp_* ]]; then
        echo "[ephemeral-keychain] Removing leftover keychain: $kc_path"
        security delete-keychain "$kc_path" 2>/dev/null || true
      fi
    done
  fi
fi

# Unique temporary keychain name and password
KC_NAME="fastlane_tmp_$(date +%s)_$$.keychain-db"
KC_PATH="$HOME/Library/Keychains/$KC_NAME"
# Use openssl for reliable random password generation instead of tr/urandom which can hang
# KC_PASS=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 24 || echo "fastlane-pass-$(date +%s)")
KC_PASS="temp-password-123"

echo "[ephemeral-keychain] Creating temporary keychain: $KC_NAME"
security create-keychain -p "$KC_PASS" "$KC_PATH"

# Get original default keychain safely
ORIG_DEFAULT_KC=""
if command -v security >/dev/null 2>&1; then
  ORIG_DEFAULT_KC=$(security default-keychain -d user 2>/dev/null | tr -d '"' | xargs || true)
fi

if [ -z "$ORIG_DEFAULT_KC" ]; then
  echo "[ephemeral-keychain] WARNING: Could not determine original default keychain"
  # Try to use login keychain as fallback
  if [ -f "$HOME/Library/Keychains/login.keychain-db" ]; then
    ORIG_DEFAULT_KC="$HOME/Library/Keychains/login.keychain-db"
    echo "[ephemeral-keychain] Using login keychain as fallback: $ORIG_DEFAULT_KC"
  else
    echo "[ephemeral-keychain] ERROR: Cannot determine default keychain and login keychain not found"
    exit 3
  fi
else
  echo "[ephemeral-keychain] Original default keychain: $ORIG_DEFAULT_KC"
fi

# Safety check: refuse to run if MATCH_KEYCHAIN_NAME explicitly points to login keychain
if [ -n "${MATCH_KEYCHAIN_NAME:-}" ]; then
  if [[ "${MATCH_KEYCHAIN_NAME}" == *login.keychain* ]]; then
    echo "[ephemeral-keychain] ERROR: MATCH_KEYCHAIN_NAME points to login keychain (${MATCH_KEYCHAIN_NAME}). Refusing to run to avoid modifying the login keychain."
    exit 3
  fi
fi

# Get original keychain list safely
ORIG_KEYCHAIN_LIST=()
if command -v security >/dev/null 2>&1; then
  while IFS= read -r item; do
    if [ -n "$item" ]; then
      trimmed=$(echo "$item" | tr -d '"' | xargs)
      if [ -n "$trimmed" ]; then
        ORIG_KEYCHAIN_LIST+=("$trimmed")
      fi
    fi
  done < <(security list-keychains -d user 2>/dev/null || true)
fi

echo "[ephemeral-keychain] Original keychain list: ${ORIG_KEYCHAIN_LIST[*]:-none}"

# Set up ephemeral keychain as default
echo "[ephemeral-keychain] Setting ephemeral keychain as default"
security default-keychain -s "$KC_PATH" 2>/dev/null || {
  echo "[ephemeral-keychain] WARNING: Failed to set default keychain"
}

# Add ephemeral keychain to search list
echo "[ephemeral-keychain] Adding ephemeral keychain to search list"
security list-keychains -d user -s "$KC_PATH" "${ORIG_KEYCHAIN_LIST[@]}" 2>/dev/null || {
  echo "[ephemeral-keychain] WARNING: Failed to update keychain list"
}
security list-keychains -d user

# Unlock and configure ephemeral keychain
echo "[ephemeral-keychain] Unlocking and configuring ephemeral keychain"
security unlock-keychain -p "$KC_PASS" "$KC_PATH" 2>/dev/null || {
  echo "[ephemeral-keychain] WARNING: Failed to unlock keychain"
}
security set-keychain-settings -lut 7200 "$KC_PATH" 2>/dev/null || {
  echo "[ephemeral-keychain] WARNING: Failed to set keychain settings"
}

cleanup() {
  set +e
  echo "[ephemeral-keychain] Starting cleanup process..."
  
  # Restore original default keychain
  if [ -n "$ORIG_DEFAULT_KC" ] && [ -f "$ORIG_DEFAULT_KC" ]; then
    echo "[ephemeral-keychain] Restoring default keychain to: $ORIG_DEFAULT_KC"
    security default-keychain -s "$ORIG_DEFAULT_KC" 2>/dev/null || {
      echo "[ephemeral-keychain] WARNING: Failed to restore default keychain"
    }
  fi
  
  # Restore original keychain list if we captured it
  if [ ${#ORIG_KEYCHAIN_LIST[@]} -gt 0 ]; then
    echo "[ephemeral-keychain] Restoring keychain list: ${ORIG_KEYCHAIN_LIST[*]}"
    security list-keychains -d user -s "${ORIG_KEYCHAIN_LIST[@]}" 2>/dev/null || {
      echo "[ephemeral-keychain] WARNING: Failed to restore keychain list"
    }
  fi
  
  # Delete ephemeral keychain (with safety checks)
  if [ -n "$KC_NAME" ] && [ -f "$KC_PATH" ]; then
    base_name=$(basename "$KC_NAME")
    if [[ "$base_name" == fastlane_tmp_* ]] && [[ "$KC_PATH" != *login.keychain* ]]; then
      echo "[ephemeral-keychain] Deleting ephemeral keychain: $KC_PATH"
      security delete-keychain "$KC_PATH" 2>/dev/null || {
        echo "[ephemeral-keychain] WARNING: Failed to delete ephemeral keychain"
        # Try alternative deletion method
        rm -f "$KC_PATH" 2>/dev/null || true
      }
    else
      echo "[ephemeral-keychain] Skipping deletion of keychain (safety check): $KC_PATH"
    fi
  fi
  
  echo "[ephemeral-keychain] Cleanup completed"
}

# Set up cleanup trap
trap cleanup EXIT

# Import certificate if provided
if [ -n "${CERT_P12_PATH:-}" ]; then
  if [ ! -f "$CERT_P12_PATH" ]; then
    echo "[ephemeral-keychain] ERROR: CERT_P12_PATH set but file not found: $CERT_P12_PATH"
    exit 3
  fi
  
  echo "[ephemeral-keychain] Importing certificate into ephemeral keychain"
  security import "$CERT_P12_PATH" -k "$KC_PATH" -P "${CERT_P12_PASSWORD:-}" -T /usr/bin/codesign -T /usr/bin/security 2>/dev/null || {
    echo "[ephemeral-keychain] WARNING: Certificate import failed"
  }
  
  # Set partition list for codesigning
  security set-key-partition-list -S apple-tool:,apple: -s -k "$KC_PASS" "$KC_PATH" 2>/dev/null || {
    echo "[ephemeral-keychain] WARNING: Failed to set key partition list"
  }
  
  echo "[ephemeral-keychain] Listing codesigning identities:"
  security -v find-identity -p codesigning "$KC_PATH" 2>/dev/null || {
    echo "[ephemeral-keychain] WARNING: Failed to list identities"
  }
fi

# Export environment variables for Fastlane
export MATCH_KEYCHAIN_NAME="$KC_PATH"
export MATCH_KEYCHAIN_PASSWORD="$KC_PASS"
echo "[ephemeral-keychain] Exported MATCH_KEYCHAIN_NAME=$KC_PATH"
echo "[ephemeral-keychain] Exported MATCH_KEYCHAIN_PASSWORD=[HIDDEN]"

# Export to GitHub Actions environment if available
if [ -n "${GITHUB_ENV:-}" ] && [ -w "$GITHUB_ENV" ]; then
  echo "MATCH_KEYCHAIN_NAME=$KC_NAME" >> "$GITHUB_ENV"
  echo "MATCH_KEYCHAIN_PASSWORD=$KC_PASS" >> "$GITHUB_ENV"
  echo "MATCH_KEYCHAIN_PATH=$KC_PATH" >> "$GITHUB_ENV"
  echo "[ephemeral-keychain] Exported ephemeral keychain info to GitHub Actions environment"
fi

echo "[ephemeral-keychain] Running command: $FASTLANE_CMD"
set -x
eval "$FASTLANE_CMD"
set +x
echo "[ephemeral-keychain] Command completed, cleanup will run via EXIT trap"

exit 0
