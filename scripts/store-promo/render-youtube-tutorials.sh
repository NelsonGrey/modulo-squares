#!/usr/bin/env bash

set -euo pipefail

# Preflight: this script composes the tutorials with ImageMagick + ffmpeg and
# records provenance with python3. Fail early with a clear message instead of a
# generic "command not found" mid-render (consistent with the other
# store-promo scripts).
for _tool in magick ffmpeg python3; do
  if ! command -v "${_tool}" >/dev/null 2>&1; then
    echo "error: '${_tool}' is required by $(basename "$0") but was not found on PATH" >&2
    exit 1
  fi
done
unset _tool

PROMO_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROMO_KIT_ROOT="${PROMO_REPO_ROOT}/packages/mobile/assets/store/promo-kit-2026-08"
PROMO_RAW_ROOT="${PROMO_KIT_ROOT}/sources/video/tutorials"
PROMO_OUTPUT_ROOT="${PROMO_KIT_ROOT}/google/video/tutorials"
PROMO_BG="${PROMO_KIT_ROOT}/cross-platform/key-art/modulo-squares-key-art-3840x2160.png"
PROMO_TEMP_ROOT="$(mktemp -d -t modulo-squares-youtube-tutorials)"

mkdir -p "${PROMO_OUTPUT_ROOT}"
trap 'find "${PROMO_TEMP_ROOT}" -type f -delete; rmdir "${PROMO_TEMP_ROOT}"' EXIT

record_provenance() {
  local output="$1"
  shift
  python3 "${PROMO_REPO_ROOT}/scripts/store-promo/render_provenance.py" \
    --kit-root "${PROMO_KIT_ROOT}" \
    --output "$output" \
    "$@" >/dev/null
}

make_title_card() {
  local title="$1"
  local subtitle="$2"
  local output="$3"

  magick "${PROMO_BG}" \
    -resize '1920x1080!' \
    -fill '#4CAF50' -draw 'rectangle 70,720 830,728' \
    -font '/System/Library/Fonts/Supplemental/Arial Bold.ttf' \
    -pointsize 68 -fill white \
    -annotate +70+850 "${title}" \
    -font '/System/Library/Fonts/Supplemental/Arial.ttf' \
    -pointsize 34 -fill 'rgba(255,255,255,0.78)' \
    -annotate +70+920 "${subtitle}" \
    "${output}"
}

render_tutorial() {
  local input="$1"
  local output="$2"
  local title="$3"
  local subtitle="$4"
  local title_card="${PROMO_TEMP_ROOT}/${output%.mp4}-card.png"

  make_title_card "${title}" "${subtitle}" "${title_card}"

  ffmpeg -hide_banner -loglevel warning -y \
    -loop 1 -i "${title_card}" \
    -i "${PROMO_RAW_ROOT}/${input}" \
    -filter_complex "\
      [0:v]scale=1920:1080:flags=lanczos,setsar=1[background];\
      [1:v]trim=start=7.8,setpts=PTS-STARTPTS,fps=30,scale=-2:980:flags=lanczos,setsar=1[phone];\
      [background][phone]overlay=x=W-w-70:y=50:shortest=1,format=yuv420p[video]" \
    -map "[video]" \
    -map_metadata -1 \
    -c:v libx264 \
    -preset slow \
    -crf 18 \
    -profile:v high \
    -level:v 4.2 \
    -pix_fmt yuv420p \
    -r 30 \
    -an \
    -movflags +faststart \
    "${PROMO_OUTPUT_ROOT}/${output}"

  record_provenance "google/video/tutorials/${output}" \
    --source "kit:cross-platform/key-art/modulo-squares-key-art-3840x2160.png" \
    --source "kit:sources/video/tutorials/${input}" \
    --source "repo:scripts/store-promo/render-youtube-tutorials.sh"
}

render_account_tutorial() {
  local title_card="${PROMO_TEMP_ROOT}/account-card.png"
  make_title_card \
    "CREATE YOUR PLAYER" \
    "Email account + public gamertag" \
    "${title_card}"

  ffmpeg -hide_banner -loglevel warning -y \
    -loop 1 -i "${title_card}" \
    -i "${PROMO_RAW_ROOT}/account-raw.mov" \
    -i "${PROMO_RAW_ROOT}/gamertag-raw.mov" \
    -filter_complex "\
      [0:v]scale=1920:1080:flags=lanczos,setsar=1[background];\
      [1:v]trim=start=7.8,setpts=PTS-STARTPTS,fps=30,scale=-2:980:flags=lanczos,setsar=1[account];\
      [2:v]trim=start=7.8,setpts=PTS-STARTPTS,fps=30,scale=-2:980:flags=lanczos,setsar=1[tag];\
      [account][tag]concat=n=2:v=1:a=0[phone];\
      [background][phone]overlay=x=W-w-70:y=50:shortest=1,format=yuv420p[video]" \
    -map "[video]" \
    -map_metadata -1 \
    -c:v libx264 \
    -preset slow \
    -crf 18 \
    -profile:v high \
    -level:v 4.2 \
    -pix_fmt yuv420p \
    -r 30 \
    -an \
    -movflags +faststart \
    "${PROMO_OUTPUT_ROOT}/01-create-account-and-gamertag-1920x1080.mp4"

  record_provenance \
    "google/video/tutorials/01-create-account-and-gamertag-1920x1080.mp4" \
    --source "kit:cross-platform/key-art/modulo-squares-key-art-3840x2160.png" \
    --source "kit:sources/video/tutorials/account-raw.mov" \
    --source "kit:sources/video/tutorials/gamertag-raw.mov" \
    --source "repo:scripts/store-promo/render-youtube-tutorials.sh"
}

render_account_tutorial

render_tutorial \
  sign-in-raw.mov \
  02-sign-in-1920x1080.mp4 \
  "SIGN IN AND PLAY" \
  "Google or email on Android"

render_tutorial \
  navigation-raw.mov \
  03-navigate-the-app-1920x1080.mp4 \
  "FIND EVERYTHING FAST" \
  "Leaderboards, settings, help, and controls"

render_tutorial \
  gameplay-raw.mov \
  04-how-to-play-1920x1080.mp4 \
  "DIVIDE. DROP. COMBO." \
  "Guide each number to a divisor bucket"

echo "Rendered YouTube tutorials in ${PROMO_OUTPUT_ROOT}"
