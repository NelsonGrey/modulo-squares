#!/usr/bin/env bash

set -euo pipefail

PROMO_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROMO_MOBILE_ROOT="${PROMO_REPO_ROOT}/packages/mobile"
PROMO_KIT_ROOT="${PROMO_MOBILE_ROOT}/assets/store/promo-kit-2026-08"
PROMO_RAW_ROOT="${PROMO_KIT_ROOT}/sources/video/tutorials"
PROMO_DEVICE="${PROMO_IOS_SIMULATOR_UDID:-booted}"
PROMO_BUNDLE_ID="com.modulosquares.app.ios"
PROMO_RUNNER_APP="${PROMO_MOBILE_ROOT}/build/ios/iphonesimulator/Runner.app"
PROMO_RECORD_PID=""

mkdir -p "${PROMO_RAW_ROOT}"

cleanup() {
  if [[ -n "${PROMO_RECORD_PID}" ]] && kill -0 "${PROMO_RECORD_PID}" 2>/dev/null; then
    kill -INT "${PROMO_RECORD_PID}" 2>/dev/null || true
    wait "${PROMO_RECORD_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

build_scene() {
  local scene="$1"
  (
    cd "${PROMO_MOBILE_ROOT}"
    flutter build ios \
      --simulator \
      --debug \
      --target lib/main_youtube_capture.dart \
      --dart-define="YOUTUBE_CAPTURE_SCENE=${scene}"
  )
  xcrun simctl install "${PROMO_DEVICE}" "${PROMO_RUNNER_APP}"
}

record_scene() {
  local scene="$1"
  local output="$2"
  local duration="$3"
  shift 3

  build_scene "${scene}"
  xcrun simctl terminate "${PROMO_DEVICE}" "${PROMO_BUNDLE_ID}" 2>/dev/null || true
  # Record to a sibling temp file and only move it into place once the run
  # finishes, so a failed capture can't clobber an existing good recording
  # (mirrors capture-ios-expert-gameplay.sh). Same directory keeps the final
  # step an atomic rename.
  local final_output="${PROMO_RAW_ROOT}/${output}"
  local tmp_output="${PROMO_RAW_ROOT}/.${output}.partial"
  rm -f "${tmp_output}"
  xcrun simctl io "${PROMO_DEVICE}" recordVideo \
    --codec=h264 \
    --mask=ignored \
    --force \
    "${tmp_output}" &
  local recorder_pid="$!"
  PROMO_RECORD_PID="${recorder_pid}"
  sleep 1
  xcrun simctl launch "${PROMO_DEVICE}" "${PROMO_BUNDLE_ID}" >/dev/null
  # Debug simulator launches can spend several seconds on Flutter's blank
  # launch frame. Keep that lead-in in the source and trim it during render so
  # every reproducible capture begins on a fully painted production screen.
  sleep 7
  "$@"
  sleep "${duration}"
  kill -INT "${recorder_pid}"
  wait "${recorder_pid}"
  PROMO_RECORD_PID=""
  mv "${tmp_output}" "${final_output}"
}

send_keys() {
  local tab_count="$1"
  local shift_tab_count="${2:-0}"
  osascript <<OSA
  tell application "Simulator" to activate
  delay 0.25
  tell application "System Events"
    repeat ${tab_count} times
      key code 48
      delay 0.12
    end repeat
    repeat ${shift_tab_count} times
      key code 48 using shift down
      delay 0.12
    end repeat
    key code 49
  end tell
OSA
}

account_actions() {
  true
}

sign_in_actions() {
  true
}

gamertag_actions() {
  true
}

navigation_actions() {
  send_keys 1
  sleep 2
  send_keys 4
  sleep 2
  send_keys 0 3
  sleep 1
  send_keys 1
}

PROMO_SCENES="${PROMO_YOUTUBE_SCENES:-account gamertag sign-in navigation gameplay}"
for scene in ${PROMO_SCENES}; do
  case "${scene}" in
    account)
      record_scene account account-raw.mov 4 account_actions
      ;;
    gamertag)
      record_scene gamertag gamertag-raw.mov 3 gamertag_actions
      ;;
    sign-in)
      record_scene sign-in sign-in-raw.mov 4 sign_in_actions
      ;;
    navigation)
      record_scene navigation navigation-raw.mov 5 navigation_actions
      ;;
    gameplay)
      record_scene gameplay gameplay-raw.mov 18 true
      ;;
    *)
      echo "Unknown PROMO_YOUTUBE_SCENES value: ${scene}" >&2
      exit 1
      ;;
  esac
done

echo "Captured tutorial sources in ${PROMO_RAW_ROOT}"
