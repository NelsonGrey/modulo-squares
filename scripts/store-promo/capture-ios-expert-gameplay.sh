#!/usr/bin/env bash

set -euo pipefail

PROMO_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROMO_MOBILE_ROOT="${PROMO_REPO_ROOT}/packages/mobile"
PROMO_KIT_ROOT="${PROMO_MOBILE_ROOT}/assets/store/promo-kit-2026-08"
PROMO_OUTPUT="${PROMO_KIT_ROOT}/sources/video/iphone-gameplay-raw.mov"
PROMO_DEVICE="${PROMO_IOS_SIMULATOR_UDID:-booted}"
PROMO_CAPTURE_SECONDS="${PROMO_EXPERT_CAPTURE_SECONDS:-32}"
PROMO_BUNDLE_ID="com.modulosquares.app.ios"
PROMO_RUNNER_APP="${PROMO_MOBILE_ROOT}/build/ios/iphonesimulator/Runner.app"
PROMO_TEMP_DIR="$(mktemp -d -t modulo-squares-expert-capture)"
PROMO_TEMP_VIDEO="${PROMO_TEMP_DIR}/iphone-gameplay-raw.mov"
PROMO_RECORD_PID=""

cleanup() {
  if [[ -n "${PROMO_RECORD_PID}" ]] && kill -0 "${PROMO_RECORD_PID}" 2>/dev/null; then
    kill -INT "${PROMO_RECORD_PID}" 2>/dev/null || true
    wait "${PROMO_RECORD_PID}" 2>/dev/null || true
  fi

  if [[ -d "${PROMO_TEMP_DIR}" ]]; then
    find "${PROMO_TEMP_DIR}" -type f -delete
    rmdir "${PROMO_TEMP_DIR}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if ! command -v flutter >/dev/null; then
  echo "Flutter is required to build the expert capture target." >&2
  exit 1
fi

if ! command -v xcrun >/dev/null; then
  echo "Xcode command-line tools are required for Simulator capture." >&2
  exit 1
fi

if ! xcrun simctl list devices booted | grep -q "(Booted)"; then
  echo "Boot an iPhone Simulator before running this script." >&2
  exit 1
fi

(
  cd "${PROMO_MOBILE_ROOT}"
  flutter build ios \
    --simulator \
    --debug \
    --target lib/main_store_capture.dart \
    --dart-define=STORE_CAPTURE_EXPERT_DEMO=true
)

xcrun simctl install "${PROMO_DEVICE}" "${PROMO_RUNNER_APP}"
xcrun simctl terminate "${PROMO_DEVICE}" "${PROMO_BUNDLE_ID}" 2>/dev/null || true

xcrun simctl io "${PROMO_DEVICE}" recordVideo \
  --codec=h264 \
  --mask=ignored \
  --force \
  "${PROMO_TEMP_VIDEO}" &
PROMO_RECORD_PID="$!"

sleep 1
xcrun simctl launch "${PROMO_DEVICE}" "${PROMO_BUNDLE_ID}" >/dev/null
sleep "${PROMO_CAPTURE_SECONDS}"

kill -INT "${PROMO_RECORD_PID}"
wait "${PROMO_RECORD_PID}"
PROMO_RECORD_PID=""

mkdir -p "$(dirname "${PROMO_OUTPUT}")"
mv "${PROMO_TEMP_VIDEO}" "${PROMO_OUTPUT}"
rmdir "${PROMO_TEMP_DIR}"
trap - EXIT

echo "Captured expert gameplay to ${PROMO_OUTPUT}"
