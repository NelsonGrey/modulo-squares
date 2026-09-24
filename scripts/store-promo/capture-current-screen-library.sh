#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MOBILE="$ROOT/packages/mobile"
KIT="$MOBILE/assets/store/promo-kit-2026-08"
IOS_OUTPUT="$KIT/sources/captures/iphone-6.9"
ANDROID_OUTPUT="$KIT/sources/captures/android-phone"
IOS_DEVICE="${PROMO_IOS_SIMULATOR_UDID:?Set PROMO_IOS_SIMULATOR_UDID}"
ANDROID_DEVICE="${PROMO_ANDROID_DEVICE:-emulator-5554}"
IOS_BUNDLE="com.modulosquares.app.ios"
ANDROID_BUNDLE="com.modulosquares.app.android"

ios_build_install() {
  local target="$1"
  shift
  (
    cd "$MOBILE"
    XCODE_XCCONFIG_FILE="$ROOT/scripts/store-promo/capture-simulator.xcconfig" \
      flutter build ios --simulator --debug --target "$target" "$@"
  )
  xcrun simctl install "$IOS_DEVICE" "$MOBILE/build/ios/iphonesimulator/Runner.app"
  xcrun simctl terminate "$IOS_DEVICE" "$IOS_BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$IOS_DEVICE" "$IOS_BUNDLE" >/dev/null
}

ios_shot() {
  xcrun simctl io "$IOS_DEVICE" screenshot "$IOS_OUTPUT/$1"
}

android_build_install() {
  local target="$1"
  shift
  (
    cd "$MOBILE"
    flutter build apk --debug --target "$target" "$@"
  )
  adb -s "$ANDROID_DEVICE" install -r "$MOBILE/build/app/outputs/flutter-apk/app-debug.apk" >/dev/null
  adb -s "$ANDROID_DEVICE" shell am force-stop "$ANDROID_BUNDLE"
  adb -s "$ANDROID_DEVICE" shell monkey -p "$ANDROID_BUNDLE" 1 >/dev/null
}

android_shot() {
  adb -s "$ANDROID_DEVICE" exec-out screencap -p >"$ANDROID_OUTPUT/$1"
}

capture_ios() {
  xcrun simctl status_bar "$IOS_DEVICE" override --time '9:41' \
    --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --batteryState charged --batteryLevel 100

  ios_build_install lib/main_how_to_capture.dart \
    --dart-define=STORE_CAPTURE_THEME=deepOcean
  sleep 2
  ios_shot 02-start-rules.png
  sleep 3
  ios_shot 05-how-to-play.png

  ios_build_install lib/main_store_capture.dart \
    --dart-define=STORE_CAPTURE_EXPERT_DEMO=true \
    --dart-define=STORE_CAPTURE_THEME=deepOcean
  sleep 6
  ios_shot 01-active-gameplay.png
  sleep 6
  ios_shot 03-score-combo.png

  ios_build_install lib/main_overlay_capture.dart \
    --dart-define=STORE_CAPTURE_EXPERT_DEMO=true \
    --dart-define=STORE_CAPTURE_THEME=deepOcean
  sleep 8
  ios_shot 04-paused.png
  sleep 6
  ios_shot 06-settings.png
  sleep 5
  ios_shot 07-purchases.png
  xcrun simctl status_bar "$IOS_DEVICE" clear
}

capture_android_native() {
  adb -s "$ANDROID_DEVICE" shell settings put global policy_control immersive.navigation='*'

  android_build_install lib/main_how_to_capture.dart \
    --dart-define=STORE_CAPTURE_THEME=deepOcean
  sleep 2
  android_shot 02-start-rules.png
  sleep 3
  android_shot 05-how-to-play.png

  android_build_install lib/main_store_capture.dart \
    --dart-define=STORE_CAPTURE_EXPERT_DEMO=true \
    --dart-define=STORE_CAPTURE_THEME=deepOcean
  sleep 6
  android_shot 01-active-gameplay.png
  sleep 6
  android_shot 03-score-combo.png

  android_build_install lib/main_overlay_capture.dart \
    --dart-define=STORE_CAPTURE_EXPERT_DEMO=true \
    --dart-define=STORE_CAPTURE_THEME=deepOcean
  sleep 8
  android_shot 04-paused.png
  sleep 6
  android_shot 06-settings.png
  sleep 5
  android_shot 07-purchases.png
  adb -s "$ANDROID_DEVICE" shell settings delete global policy_control >/dev/null
}

compose_android() {
  local legacy="${PROMO_ANDROID_CHROME_SOURCE:?Set PROMO_ANDROID_CHROME_SOURCE to the preserved native Android captures}"
  python3 - "$IOS_OUTPUT" "$ANDROID_OUTPUT" "$legacy" <<'PY'
from pathlib import Path
from PIL import Image
import sys

ios, android, legacy = map(Path, sys.argv[1:])
for source in sorted(ios.glob('*.png')):
    base = Image.open(legacy / source.name).convert('RGB')
    current = Image.open(source).convert('RGB')
    app = current.crop((0, 140, current.width, 2768)).resize(
        (1080, 2060), Image.Resampling.LANCZOS
    )
    base.paste(app, (0, 72))
    base.save(android / source.name, optimize=True)
PY
}

case "${1:-all}" in
  ios) capture_ios ;;
  android)
    if [[ "${PROMO_ANDROID_NATIVE_CAPTURE:-0}" == "1" ]]; then
      capture_android_native
    else
      compose_android
    fi
    ;;
  all)
    capture_ios
    if [[ "${PROMO_ANDROID_NATIVE_CAPTURE:-0}" == "1" ]]; then
      capture_android_native
    else
      compose_android
    fi
    ;;
  *) echo "Usage: $0 [ios|android|all]" >&2; exit 2 ;;
esac

echo "Captured the current seven-state screen library."
