#!/usr/bin/env bash

set -euo pipefail

PROMO_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROMO_KIT_ROOT="${PROMO_REPO_ROOT}/packages/mobile/assets/store/promo-kit-2026-08"
PROMO_VIDEO_SOURCE_ROOT="${PROMO_KIT_ROOT}/sources/video"
PROMO_PLATE_ROOT="${PROMO_VIDEO_SOURCE_ROOT}/plates"

PROMO_RAW_GAMEPLAY="${PROMO_VIDEO_SOURCE_ROOT}/iphone-gameplay-raw.mov"
PROMO_APPLE_VIDEO="${PROMO_KIT_ROOT}/apple/app-preview/modulo-squares-app-preview-iphone-portrait-886x1920.mp4"
PROMO_GOOGLE_VIDEO="${PROMO_KIT_ROOT}/google/video/modulo-squares-youtube-promo-1920x1080.mp4"
PROMO_SOCIAL_ROOT="${PROMO_KIT_ROOT}/cross-platform/video-clips"

PROMO_PLATES=(
  "${PROMO_PLATE_ROOT}/01-drop-numbers.png"
  "${PROMO_PLATE_ROOT}/02-think-fast.png"
  "${PROMO_PLATE_ROOT}/03-divide-evenly.png"
  "${PROMO_PLATE_ROOT}/04-build-combos.png"
  "${PROMO_PLATE_ROOT}/05-fill-grid.png"
  "${PROMO_PLATE_ROOT}/06-keep-thinking.png"
)

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "FFmpeg is required to render the promotion videos." >&2
  exit 1
fi

PROMO_REQUIRED_SOURCES=(
  "${PROMO_RAW_GAMEPLAY}"
  "${PROMO_PLATES[@]}"
)

for source in "${PROMO_REQUIRED_SOURCES[@]}"; do
  if [[ ! -f "${source}" ]]; then
    echo "Missing video source: ${source}" >&2
    echo "Run ./scripts/store-promo/render-assets.sh before rendering videos." >&2
    exit 1
  fi
done

mkdir -p \
  "$(dirname "${PROMO_APPLE_VIDEO}")" \
  "$(dirname "${PROMO_GOOGLE_VIDEO}")" \
  "${PROMO_SOCIAL_ROOT}"

# Records which source-file hashes produced a published deliverable, so
# validate-assets.py can detect deliverables that are stale relative to the
# raw gameplay capture, the branded plates, or the Apple preview they were
# built from.
record_provenance() {
  local output="$1"
  shift
  python3 "${PROMO_REPO_ROOT}/scripts/store-promo/render_provenance.py" \
    --kit-root "${PROMO_KIT_ROOT}" \
    --output "${output}" \
    "$@"
}

# Apple App Preview: one uninterrupted 16.9-second expert run. The source
# begins with Simulator launch frames; 7.5 seconds lands on the in-app rules
# overlay immediately before the capture-only expert driver starts playing.
ffmpeg -hide_banner -loglevel warning -y \
  -ss 7.5 -t 16.9 -i "${PROMO_RAW_GAMEPLAY}" \
  -filter_complex "[0:v]scale=886:1920:flags=lanczos,fps=30,trim=duration=16.9,setpts=PTS-STARTPTS,setsar=1,format=yuv420p[video]" \
  -map "[video]" \
  -map_metadata -1 \
  -c:v libx264 \
  -preset slow \
  -crf 18 \
  -profile:v high \
  -level:v 4.0 \
  -pix_fmt yuv420p \
  -r 30 \
  -an \
  -movflags +faststart \
  "${PROMO_APPLE_VIDEO}"

record_provenance "apple/app-preview/modulo-squares-app-preview-iphone-portrait-886x1920.mp4" \
  --source "kit:sources/video/iphone-gameplay-raw.mov"

# Google Play / YouTube master: six equal branded plates behind the Apple preview.
ffmpeg -hide_banner -loglevel warning -y \
  -loop 1 -framerate 30 -t 2.816667 -i "${PROMO_PLATES[0]}" \
  -loop 1 -framerate 30 -t 2.816667 -i "${PROMO_PLATES[1]}" \
  -loop 1 -framerate 30 -t 2.816667 -i "${PROMO_PLATES[2]}" \
  -loop 1 -framerate 30 -t 2.816667 -i "${PROMO_PLATES[3]}" \
  -loop 1 -framerate 30 -t 2.816667 -i "${PROMO_PLATES[4]}" \
  -loop 1 -framerate 30 -t 2.816667 -i "${PROMO_PLATES[5]}" \
  -i "${PROMO_APPLE_VIDEO}" \
  -filter_complex "\
    [0:v]scale=1920:1080:flags=lanczos,fps=30,trim=duration=2.816667,setpts=PTS-STARTPTS,setsar=1[p0];\
    [1:v]scale=1920:1080:flags=lanczos,fps=30,trim=duration=2.816667,setpts=PTS-STARTPTS,setsar=1[p1];\
    [2:v]scale=1920:1080:flags=lanczos,fps=30,trim=duration=2.816667,setpts=PTS-STARTPTS,setsar=1[p2];\
    [3:v]scale=1920:1080:flags=lanczos,fps=30,trim=duration=2.816667,setpts=PTS-STARTPTS,setsar=1[p3];\
    [4:v]scale=1920:1080:flags=lanczos,fps=30,trim=duration=2.816667,setpts=PTS-STARTPTS,setsar=1[p4];\
    [5:v]scale=1920:1080:flags=lanczos,fps=30,trim=duration=2.816667,setpts=PTS-STARTPTS,setsar=1[p5];\
    [p0][p1][p2][p3][p4][p5]concat=n=6:v=1:a=0[plates];\
    [6:v]fps=30,scale=-2:1000:flags=lanczos,setpts=PTS-STARTPTS,setsar=1[phone];\
    [plates][phone]overlay=x=W-w-60:y=40:shortest=1:eof_action=endall,trim=duration=16.9,setpts=PTS-STARTPTS,format=yuv420p[video]" \
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
  "${PROMO_GOOGLE_VIDEO}"

record_provenance "google/video/modulo-squares-youtube-promo-1920x1080.mp4" \
  --source "kit:apple/app-preview/modulo-squares-app-preview-iphone-portrait-886x1920.mp4" \
  --source "kit:sources/video/plates/01-drop-numbers.png" \
  --source "kit:sources/video/plates/02-think-fast.png" \
  --source "kit:sources/video/plates/03-divide-evenly.png" \
  --source "kit:sources/video/plates/04-build-combos.png" \
  --source "kit:sources/video/plates/05-fill-grid.png" \
  --source "kit:sources/video/plates/06-keep-thinking.png"

PROMO_SOCIAL_CLIPS=(
  "0.8|01-drop-and-decide-1080x1920.mp4"
  "6.0|02-combo-and-progress-1080x1920.mp4"
  "11.4|03-speed-and-streak-1080x1920.mp4"
)

for clip in "${PROMO_SOCIAL_CLIPS[@]}"; do
  IFS='|' read -r start filename <<<"${clip}"

  ffmpeg -hide_banner -loglevel warning -y \
    -ss "${start}" -t 5.5 -i "${PROMO_APPLE_VIDEO}" \
    -filter_complex "\
      [0:v]split=2[background-source][foreground-source];\
      [background-source]scale=1080:1920:force_original_aspect_ratio=increase:flags=lanczos,crop=1080:1920,gblur=sigma=28[background];\
      [foreground-source]scale=-2:1920:flags=lanczos,setsar=1[foreground];\
      [background][foreground]overlay=x=(W-w)/2:y=0:shortest=1,format=yuv420p[video]" \
    -map "[video]" \
    -map_metadata -1 \
    -c:v libx264 \
    -preset slow \
    -crf 18 \
    -profile:v high \
    -level:v 4.1 \
    -pix_fmt yuv420p \
    -r 30 \
    -t 5.5 \
    -an \
    -movflags +faststart \
    "${PROMO_SOCIAL_ROOT}/${filename}"

  record_provenance "cross-platform/video-clips/${filename}" \
    --source "kit:apple/app-preview/modulo-squares-app-preview-iphone-portrait-886x1920.mp4"
done

echo "Rendered promotion videos into ${PROMO_KIT_ROOT}"
