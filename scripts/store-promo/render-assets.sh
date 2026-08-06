#!/usr/bin/env bash

set -euo pipefail

PROMO_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROMO_CODEX_ROOT="${CODEX_HOME:-${HOME}/.codex}"
PROMO_PWCLI="${PROMO_CODEX_ROOT}/skills/playwright/scripts/playwright_cli.sh"
PROMO_PORT="${PROMO_RENDER_PORT:-4173}"
PROMO_BASE_URL="http://127.0.0.1:${PROMO_PORT}/scripts/store-promo/render.html"
PROMO_CAPTURE_ROOT="${PROMO_REPO_ROOT}/output/playwright/store-promo/final"
PROMO_KIT_ROOT="${PROMO_REPO_ROOT}/packages/mobile/assets/store/promo-kit-2026-08"
PROMO_SERVER_PID=""

if [[ ! -x "${PROMO_PWCLI}" ]]; then
  echo "Playwright CLI wrapper not found: ${PROMO_PWCLI}" >&2
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
  "${PROMO_KIT_ROOT}/sources/video/plates"

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

  "${PROMO_PWCLI}" --session store-promo open "${url}" >/dev/null
  "${PROMO_PWCLI}" --session store-promo resize "${width}" "${height}" >/dev/null
  "${PROMO_PWCLI}" --session store-promo snapshot >/dev/null
  "${PROMO_PWCLI}" --session store-promo screenshot --filename "${output}" >/dev/null
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

  google_output="${PROMO_CAPTURE_ROOT}/google/${google_slug}-1080x1920.png"
  capture_page 1080 1920 \
    "${PROMO_BASE_URL}?layout=phone&source=${PROMO_GOOGLE_SOURCE}/${google_source}&headline=${google_headline}&step=${step}" \
    "${google_output}"
  cp "${google_output}" "${PROMO_KIT_ROOT}/google/screenshots/phone/"
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
"${PROMO_PWCLI}" --session store-promo close >/dev/null || true

echo "Rendered store assets into ${PROMO_KIT_ROOT}"
