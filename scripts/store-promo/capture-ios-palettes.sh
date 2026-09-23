#!/usr/bin/env bash
# Fresh native iOS media, kept separate from earlier approved assets.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEVICE="${PROMO_IOS_SIMULATOR_UDID:?Set PROMO_IOS_SIMULATOR_UDID to a booted iPhone simulator UDID}"
OUTPUT="${PROMO_IOS_OUTPUT:-${ROOT}/media-library/_source/ios-refresh-2026-09-16}"
RECORDER=""
cleanup() {
  if [[ -n "$RECORDER" ]]; then
    kill -INT "$RECORDER" 2>/dev/null || true
    wait "$RECORDER" 2>/dev/null || true
  fi
  xcrun simctl status_bar "$DEVICE" clear 2>/dev/null || true
}
trap cleanup EXIT
xcrun simctl list devices booted | grep -F "$DEVICE" >/dev/null
if [[ -d "$OUTPUT" && -n "$(ls -A "$OUTPUT")" ]]; then
  echo 'Output is not empty. Choose a new PROMO_IOS_OUTPUT.' >&2
  exit 1
fi
mkdir -p "$OUTPUT"
for palette in deepOcean arcadeNeon warmSunset candyPop; do
  (
    cd "$ROOT/packages/mobile"
    XCODE_XCCONFIG_FILE="$ROOT/scripts/store-promo/capture-simulator.xcconfig" \
    flutter build ios --simulator --debug --target lib/main_store_capture.dart \
      --dart-define=STORE_CAPTURE_EXPERT_DEMO=true \
      --dart-define="STORE_CAPTURE_THEME=$palette"
  )
  xcrun simctl install "$DEVICE" "$ROOT/packages/mobile/build/ios/iphonesimulator/Runner.app"
  xcrun simctl terminate "$DEVICE" com.modulosquares.app.ios 2>/dev/null || true
  xcrun simctl status_bar "$DEVICE" override --time '9:41' \
    --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
  xcrun simctl launch "$DEVICE" com.modulosquares.app.ios >/dev/null
  sleep 9
  xcrun simctl io "$DEVICE" screenshot "$OUTPUT/$palette.png"
  xcrun simctl io "$DEVICE" recordVideo --codec=h264 "$OUTPUT/$palette.partial.mov" &
  RECORDER=$!
  sleep 24
  kill -INT "$RECORDER"
  wait "$RECORDER"
  RECORDER=""
  mv "$OUTPUT/$palette.partial.mov" "$OUTPUT/$palette.mov"
done
xcrun simctl status_bar "$DEVICE" clear
echo "Captured sources to $OUTPUT. Visual review, screenshot RGB export, and video editing are still required."
