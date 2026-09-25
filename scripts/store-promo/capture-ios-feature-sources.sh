#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEVICE="${PROMO_IOS_SIMULATOR_UDID:?Set PROMO_IOS_SIMULATOR_UDID}"
OUTPUT="${PROMO_IOS_OUTPUT:-${ROOT}/media-library/_source/ios-feature-series-$(date +%F)/captures}"
BUNDLE_ID="com.modulosquares.app.ios"
RUNNER="${ROOT}/packages/mobile/build/ios/iphonesimulator/Runner.app"
RECORDER=""

cleanup() {
  if [[ -n "$RECORDER" ]]; then
    kill -INT "$RECORDER" 2>/dev/null || true
    wait "$RECORDER" 2>/dev/null || true
  fi
  xcrun simctl status_bar "$DEVICE" clear 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$OUTPUT"

capture() {
  local target="$1"
  local name="$2"
  local seconds="$3"
  local extra_define="$4"

  if [[ -e "$OUTPUT/$name.mov" ]]; then
    echo "Refusing to replace $OUTPUT/$name.mov" >&2
    exit 1
  fi

  (
    cd "$ROOT/packages/mobile"
    XCODE_XCCONFIG_FILE="$ROOT/scripts/store-promo/capture-simulator.xcconfig" \
      flutter build ios --simulator --debug --target "$target" \
      --dart-define=STORE_CAPTURE_THEME=deepOcean \
      $extra_define
  )
  xcrun simctl install "$DEVICE" "$RUNNER"
  xcrun simctl terminate "$DEVICE" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl status_bar "$DEVICE" override --time '9:41' \
    --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --batteryState charged --batteryLevel 100
  xcrun simctl io "$DEVICE" recordVideo --codec=h264 --force \
    "$OUTPUT/$name.partial.mov" &
  RECORDER=$!
  sleep 1
  xcrun simctl launch "$DEVICE" "$BUNDLE_ID" >"$OUTPUT/$name-launch.txt"
  sleep "$seconds"
  kill -INT "$RECORDER"
  wait "$RECORDER" || true
  RECORDER=""
  mv "$OUTPUT/$name.partial.mov" "$OUTPUT/$name.mov"
}

capture lib/main_store_capture.dart gameplay 34 \
  --dart-define=STORE_CAPTURE_EXPERT_DEMO=true
capture lib/main_settings_tour_capture.dart settings-tour 27 \
  --dart-define=STORE_CAPTURE_EXPERT_DEMO=true

echo "Captured current gameplay and settings sources in $OUTPUT"
