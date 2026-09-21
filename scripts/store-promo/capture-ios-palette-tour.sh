#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEVICE="${PROMO_IOS_SIMULATOR_UDID:?Set PROMO_IOS_SIMULATOR_UDID}"
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
mkdir -p "$OUTPUT"
if [[ -e "$OUTPUT/palette-tour.mov" ]]; then
  echo 'A tour already exists; choose a new PROMO_IOS_OUTPUT.' >&2
  exit 1
fi
(
  cd "$ROOT/packages/mobile"
  XCODE_XCCONFIG_FILE="$ROOT/scripts/store-promo/capture-simulator.xcconfig" \
    flutter build ios --simulator --debug --target lib/main_palette_tour_capture.dart \
    --dart-define=STORE_CAPTURE_EXPERT_DEMO=true \
    --dart-define=STORE_CAPTURE_THEME=deepOcean
)
xcrun simctl install "$DEVICE" "$ROOT/packages/mobile/build/ios/iphonesimulator/Runner.app"
xcrun simctl terminate "$DEVICE" com.modulosquares.app.ios 2>/dev/null || true
xcrun simctl status_bar "$DEVICE" override --time '9:41' \
  --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
xcrun simctl io "$DEVICE" recordVideo --codec=h264 "$OUTPUT/palette-tour.partial.mov" &
RECORDER=$!
sleep 1
xcrun simctl launch "$DEVICE" com.modulosquares.app.ios > "$OUTPUT/palette-tour-launch.txt"
sleep 40
sleep 25
kill -INT "$RECORDER"
wait "$RECORDER"
RECORDER=""
mv "$OUTPUT/palette-tour.partial.mov" "$OUTPUT/palette-tour.mov"
echo "Tour source captured. Review startup trim, settings actions, and motion before editing."
