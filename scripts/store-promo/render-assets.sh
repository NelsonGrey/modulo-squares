#!/usr/bin/env bash

set -euo pipefail

PROMO_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROMO_CAPTURE_CLI="${PROMO_REPO_ROOT}/scripts/store-promo/capture.mjs"
PROMO_PROVENANCE_CLI="${PROMO_REPO_ROOT}/scripts/store-promo/render_provenance.py"
PROMO_PORT="${PROMO_RENDER_PORT:-4173}"
PROMO_BASE_URL="http://127.0.0.1:${PROMO_PORT}/scripts/store-promo/render.html"
PROMO_CAPTURE_ROOT="${PROMO_REPO_ROOT}/output/playwright/store-promo/final"
PROMO_KIT_ROOT="${PROMO_REPO_ROOT}/packages/mobile/assets/store/promo-kit-2026-08"
PROMO_FASTLANE_SCREENSHOTS="${PROMO_REPO_ROOT}/packages/mobile/ios/fastlane/screenshots/en-US"
PROMO_SERVER_PID=""

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required to render store assets." >&2
  exit 1
fi

if [[ ! -d "${PROMO_REPO_ROOT}/node_modules/playwright" ]]; then
  echo "Playwright is not installed. From the repository root, run:" >&2
  echo "  npm install" >&2
  echo "  npx playwright install --with-deps chromium" >&2
  exit 1
fi

mkdir -p \
  "${PROMO_CAPTURE_ROOT}/apple" \
  "${PROMO_CAPTURE_ROOT}/google" \
  "${PROMO_CAPTURE_ROOT}/social" \
  "${PROMO_CAPTURE_ROOT}/video-plates" \
  "${PROMO_KIT_ROOT}/apple/screenshots/iphone-6.9" \
  "${PROMO_KIT_ROOT}/google/screenshots/phone" \
  "${PROMO_KIT_ROOT}/cross-platform/social" \
  "${PROMO_KIT_ROOT}/sources/video/plates" \
  "${PROMO_FASTLANE_SCREENSHOTS}"

if ! curl --silent --fail "http://127.0.0.1:${PROMO_PORT}/scripts/store-promo/render.html" >/dev/null; then
  (
    cd "${PROMO_REPO_ROOT}"
    python3 -m http.server "${PROMO_PORT}" --bind 127.0.0.1
  ) >/dev/null 2>&1 &
  PROMO_SERVER_PID="$!"
  trap 'if [[ -n "${PROMO_SERVER_PID}" ]]; then kill "${PROMO_SERVER_PID}" 2>/dev/null || true; fi' EXIT

  for _ in {1..30}; do
    curl --silent --fail "http://127.0.0.1:${PROMO_PORT}/scripts/store-promo/render.html" >/dev/null && break
    sleep 0.2
  done
fi

capture_page() {
  local width="$1"
  local height="$2"
  local url="$3"
  local output="$4"

  node "${PROMO_CAPTURE_CLI}" "${width}" "${height}" "${url}" "${output}"
}

# Records which source-file hashes produced a published deliverable, so
# validate-assets.py can detect deliverables that are stale relative to
# render.html or the native captures/plates they were built from.
record_provenance() {
  local output="$1"
  shift
  python3 "${PROMO_PROVENANCE_CLI}" \
    --kit-root "${PROMO_KIT_ROOT}" \
    --output "${output}" \
    "$@"
}

PROMO_SHOTS=(
  "01-drop-numbers|01-drop-numbers|01-active-gameplay.png|Drop%20Numbers.%0AThink%20Fast.|01-active-gameplay.png|Drop%20Numbers.%0AThink%20Fast."
  "02-divide-evenly|02-divide-evenly|02-start-rules.png|Choose%20a%20Bucket%0AThat%20Divides%20Evenly|02-start-rules.png|Choose%20a%20Bucket%0AThat%20Divides%20Evenly"
  "03-build-combos|03-build-combos|03-score-combo.png|Build%20Combos.%0AFill%20the%20Grid.|03-score-combo.png|Build%20Combos.%0AFill%20the%20Grid."
  "04-chase-your-best|04-keep-the-run-going|04-paused.png|Pause%20Anytime.%0AChase%20Your%20Best.|04-paused.png|Pause%20Anytime.%0AKeep%20the%20Run%20Going."
  "05-learn-the-rules|05-learn-the-rules|05-how-to-play.png|Learn%20the%20Rules%0Ain%20Seconds|05-how-to-play.png|Learn%20the%20Rules%0Ain%20Seconds"
  "06-remove-ads|06-customize-settings|07-purchases.png|Play%20Free.%0ARemove%20Ads%20Once.|06-settings.png|Tune%20the%20Game%0ATo%20Your%20Style"
)

PROMO_APPLE_SOURCE="../../packages/mobile/assets/store/promo-kit-2026-08/sources/captures/iphone-6.9"
PROMO_GOOGLE_SOURCE="../../packages/mobile/assets/store/promo-kit-2026-08/sources/captures/android-phone"

for index in "${!PROMO_SHOTS[@]}"; do
  IFS='|' read -r apple_slug google_slug apple_source apple_headline google_source google_headline <<<"${PROMO_SHOTS[$index]}"
  step="$((index + 1))"

  apple_output="${PROMO_CAPTURE_ROOT}/apple/${apple_slug}-1320x2868.png"
  capture_page 1320 2868 \
    "${PROMO_BASE_URL}?layout=phone&source=${PROMO_APPLE_SOURCE}/${apple_source}&headline=${apple_headline}&step=${step}" \
    "${apple_output}"
  cp "${apple_output}" "${PROMO_KIT_ROOT}/apple/screenshots/iphone-6.9/"
  # verify_metadata/submit_to_app_store read screenshots from Fastlane's
  # own screenshots_path, not the promo kit -- keep both in sync.
  cp "${apple_output}" "${PROMO_FASTLANE_SCREENSHOTS}/"
  record_provenance "apple/screenshots/iphone-6.9/${apple_slug}-1320x2868.png" \
    --source "repo:scripts/store-promo/render.html" \
    --source "kit:sources/captures/iphone-6.9/${apple_source}"

  google_output="${PROMO_CAPTURE_ROOT}/google/${google_slug}-1080x1920.png"
  capture_page 1080 1920 \
    "${PROMO_BASE_URL}?layout=phone&source=${PROMO_GOOGLE_SOURCE}/${google_source}&headline=${google_headline}&step=${step}" \
    "${google_output}"
  cp "${google_output}" "${PROMO_KIT_ROOT}/google/screenshots/phone/"
  record_provenance "google/screenshots/phone/${google_slug}-1080x1920.png" \
    --source "repo:scripts/store-promo/render.html" \
    --source "kit:sources/captures/android-phone/${google_source}"
done

PROMO_VIDEO_PLATES=(
  "01-drop-numbers.png|DROP%20NUMBERS|Guide%20each%20falling%20number%20into%20a%20bucket%20that%20divides%20it%20evenly."
  "02-think-fast.png|THINK%20FAST|Guide%20each%20falling%20number%20into%20a%20bucket%20that%20divides%20it%20evenly."
  "03-divide-evenly.png|DIVIDE%20EVENLY|Guide%20each%20falling%20number%20into%20a%20bucket%20that%20divides%20it%20evenly."
  "04-build-combos.png|BUILD%20COMBOS|Guide%20each%20falling%20number%20into%20a%20bucket%20that%20divides%20it%20evenly."
  "05-fill-grid.png|FILL%20THE%20GRID|Guide%20each%20falling%20number%20into%20a%20bucket%20that%20divides%20it%20evenly."
  "06-keep-thinking.png|KEEP%20THINKING|Guide%20each%20falling%20number%20into%20a%20bucket%20that%20divides%20it%20evenly."
)

for plate in "${PROMO_VIDEO_PLATES[@]}"; do
  IFS='|' read -r filename headline subhead <<<"${plate}"
  plate_output="${PROMO_CAPTURE_ROOT}/video-plates/${filename}"

  capture_page 1920 1080 \
    "${PROMO_BASE_URL}?layout=landscape&eyebrow=THE%20MODULAR%20MATH%20PUZZLE&headline=${headline}&subhead=${subhead}" \
    "${plate_output}"
  cp "${plate_output}" "${PROMO_KIT_ROOT}/sources/video/plates/"
done

capture_page 1280 720 \
  "${PROMO_BASE_URL}?layout=keyart&headline=Modulo%20Squares&subhead=Drop%20numbers.%20Think%20fast.%20Find%20the%20divisor." \
  "${PROMO_CAPTURE_ROOT}/social/youtube-thumbnail-1280x720.png"

capture_page 2560 1440 \
  "${PROMO_BASE_URL}?layout=banner&headline=Modulo%20Squares&eyebrow=THE%20MODULAR%20MATH%20PUZZLE" \
  "${PROMO_CAPTURE_ROOT}/social/youtube-channel-banner-2560x1440.png"

capture_page 1080 1080 \
  "${PROMO_BASE_URL}?layout=keyart&headline=Drop%20Numbers.%0AThink%20Fast.&subhead=The%20modular%20math%20puzzle." \
  "${PROMO_CAPTURE_ROOT}/social/social-square-1080x1080.png"

cp "${PROMO_CAPTURE_ROOT}/social/"*.png "${PROMO_KIT_ROOT}/cross-platform/social/"

for social_file in youtube-thumbnail-1280x720.png youtube-channel-banner-2560x1440.png social-square-1080x1080.png; do
  record_provenance "cross-platform/social/${social_file}" \
    --source "repo:scripts/store-promo/render.html" \
    --source "kit:sources/key-art-master-generated.png"
done

echo "Rendered store assets into ${PROMO_KIT_ROOT}"
