#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
LIB="$REPO_ROOT/media-library"
KIT="$REPO_ROOT/packages/mobile/assets/store/promo-kit-2026-08"
# Overridable for non-macOS / non-Arial environments.
FONT_REGULAR="${MEDIA_LIBRARY_FONT_REGULAR:-/System/Library/Fonts/Supplemental/Arial.ttf}"
FONT_BOLD="${MEDIA_LIBRARY_FONT_BOLD:-/System/Library/Fonts/Supplemental/Arial Bold.ttf}"

for command_name in magick ffmpeg python3; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "Missing required command: $command_name" >&2
    exit 1
  }
done

for font_file in "$FONT_REGULAR" "$FONT_BOLD"; do
  [ -f "$font_file" ] || {
    echo "Missing required font: $font_file" >&2
    exit 1
  }
done

mkdir -p \
  "$LIB/00-brand/profile" \
  "$LIB/00-brand/headers" \
  "$LIB/01-evergreen/feed-square" \
  "$LIB/01-evergreen/feed-portrait" \
  "$LIB/01-evergreen/feed-landscape" \
  "$LIB/02-platform-ready/threads" \
  "$LIB/02-platform-ready/facebook" \
  "$LIB/02-platform-ready/instagram" \
  "$LIB/02-platform-ready/reddit" \
  "$LIB/02-platform-ready/tiktok" \
  "$LIB/02-platform-ready/x" \
  "$LIB/02-platform-ready/youtube/thumbnails" \
  "$LIB/03-video/vertical-shorts" \
  "$LIB/03-video/landscape" \
  "$LIB/03-video/tutorials" \
  "$LIB/04-copy" \
  "$LIB/_inventory" \
  "$LIB/quarantine-do-not-upload" \
  "$LIB/review-evidence-not-marketing"

KEY_ART="$KIT/cross-platform/key-art/modulo-squares-key-art-3840x2160.png"
SOCIAL_SQUARE="$KIT/cross-platform/social/social-square-1080x1080.png"
CHANNEL_BANNER="$KIT/cross-platform/social/youtube-channel-banner-2560x1440.png"
TRAILER_THUMB="$KIT/cross-platform/social/youtube-thumbnail-1280x720.png"
PROFILE_MASTER="$KIT/apple/icon/app-icon-1024x1024.png"

make_flat_png() {
  source_file=$1
  width=$2
  height=$3
  output_file=$4
  gravity=${5:-center}
  magick "$source_file" \
    -resize "${width}x${height}^" \
    -gravity "$gravity" \
    -extent "${width}x${height}" \
    -colorspace sRGB -alpha remove -alpha off -strip \
    -define png:color-type=2 "$output_file"
}

make_contained_png() {
  source_file=$1
  width=$2
  height=$3
  output_file=$4
  inset_width=$((width - 80))
  inset_height=$((height - 80))
  magick \
    \( "$KEY_ART" -resize "${width}x${height}^" -gravity center -extent "${width}x${height}" -blur 0x30 -fill '#06142b' -colorize 42% \) \
    \( "$source_file" -resize "${inset_width}x${inset_height}" \) \
    -gravity center -compose over -composite \
    -colorspace sRGB -alpha remove -alpha off -strip \
    -define png:color-type=2 "$output_file"
}

for size in 1024 512 400 320 256 200; do
  make_flat_png "$PROFILE_MASTER" "$size" "$size" "$LIB/00-brand/profile/modulo-squares-profile-${size}x${size}.png"
done

make_flat_png "$CHANNEL_BANNER" 2560 1440 "$LIB/00-brand/headers/youtube-channel-banner-2560x1440.png"
make_flat_png "$CHANNEL_BANNER" 1500 500 "$LIB/00-brand/headers/x-header-1500x500.png"
make_flat_png "$CHANNEL_BANNER" 1640 624 "$LIB/00-brand/headers/facebook-cover-1640x624.png"
make_flat_png "$CHANNEL_BANNER" 1920 384 "$LIB/00-brand/headers/reddit-banner-1920x384.png"

make_flat_png "$SOCIAL_SQUARE" 1080 1080 "$LIB/01-evergreen/feed-square/brand-drop-numbers-1080x1080.png"
make_contained_png "$SOCIAL_SQUARE" 1080 1350 "$LIB/01-evergreen/feed-portrait/brand-drop-numbers-1080x1350.png"
make_flat_png "$KEY_ART" 1200 630 "$LIB/01-evergreen/feed-landscape/key-art-1200x630.png"
make_flat_png "$KEY_ART" 1600 900 "$LIB/01-evergreen/feed-landscape/key-art-1600x900.png"

index=1
for source_file in "$KIT"/google/screenshots/phone/*.png; do
  stem=$(basename "$source_file" .png)
  stem=${stem%-1080x1920}
  make_contained_png "$source_file" 1080 1080 "$LIB/01-evergreen/feed-square/${stem}-1080x1080.png"
  make_contained_png "$source_file" 1080 1350 "$LIB/01-evergreen/feed-portrait/${stem}-1080x1350.png"
  make_flat_png "$source_file" 1080 1920 "$LIB/02-platform-ready/instagram/story-${stem}-1080x1920.png" north
  index=$((index + 1))
done

# Platform folders contain convenient copies of the best-fit exports. The
# canonical derivatives remain under 00-brand and 01-evergreen.
cp -p "$LIB/01-evergreen/feed-portrait/brand-drop-numbers-1080x1350.png" "$LIB/02-platform-ready/threads/brand-drop-numbers-1080x1350.png"
cp -p "$LIB/01-evergreen/feed-landscape/key-art-1200x630.png" "$LIB/02-platform-ready/facebook/key-art-1200x630.png"
cp -p "$LIB/01-evergreen/feed-square/brand-drop-numbers-1080x1080.png" "$LIB/02-platform-ready/instagram/brand-drop-numbers-1080x1080.png"
cp -p "$LIB/01-evergreen/feed-landscape/key-art-1200x630.png" "$LIB/02-platform-ready/reddit/key-art-1200x630.png"
cp -p "$LIB/00-brand/profile/modulo-squares-profile-256x256.png" "$LIB/02-platform-ready/reddit/community-icon-256x256.png"
cp -p "$LIB/00-brand/headers/reddit-banner-1920x384.png" "$LIB/02-platform-ready/reddit/community-banner-1920x384.png"
cp -p "$LIB/00-brand/profile/modulo-squares-profile-200x200.png" "$LIB/02-platform-ready/tiktok/profile-200x200.png"
cp -p "$LIB/01-evergreen/feed-landscape/key-art-1600x900.png" "$LIB/02-platform-ready/x/key-art-1600x900.png"
cp -p "$TRAILER_THUMB" "$LIB/02-platform-ready/youtube/thumbnails/00-official-gameplay-trailer-1280x720.png"

cp -p "$KIT"/cross-platform/video-clips/*.mp4 "$LIB/03-video/vertical-shorts/"
cp -p "$KIT/google/video/modulo-squares-youtube-promo-1920x1080.mp4" "$LIB/03-video/landscape/"
cp -p "$KIT"/google/video/tutorials/*.mp4 "$LIB/03-video/tutorials/"

WORK_DIR=$(mktemp -d /tmp/modulo-media-library.XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT HUP INT TERM

make_tutorial_thumbnail() {
  video_file=$1
  output_file=$2
  label=$3
  frame_file="$WORK_DIR/frame.png"
  ffmpeg -loglevel error -y -ss 2 -i "$video_file" -frames:v 1 "$frame_file"
  magick "$frame_file" -resize '1280x720^' -gravity center -extent 1280x720 \
    -fill '#07152d' -draw 'rectangle 0,520 1280,720' \
    -font "$FONT_BOLD" -fill white -pointsize 54 -gravity southwest \
    -annotate +64+92 "$label" \
    -font "$FONT_REGULAR" -fill '#bde9ff' -pointsize 24 \
    -annotate +67+48 'MODULO SQUARES TUTORIAL' \
    -colorspace sRGB -alpha remove -alpha off -strip \
    -define png:color-type=2 "$output_file"
}

make_tutorial_thumbnail "$KIT/google/video/tutorials/01-create-account-and-gamertag-1920x1080.mp4" \
  "$LIB/02-platform-ready/youtube/thumbnails/01-create-your-player-1280x720.png" 'CREATE YOUR PLAYER'
make_tutorial_thumbnail "$KIT/google/video/tutorials/02-sign-in-1920x1080.mp4" \
  "$LIB/02-platform-ready/youtube/thumbnails/02-sign-in-and-play-1280x720.png" 'SIGN IN AND PLAY'
make_tutorial_thumbnail "$KIT/google/video/tutorials/03-navigate-the-app-1920x1080.mp4" \
  "$LIB/02-platform-ready/youtube/thumbnails/03-find-everything-fast-1280x720.png" 'FIND EVERYTHING FAST'
make_tutorial_thumbnail "$KIT/google/video/tutorials/04-how-to-play-1920x1080.mp4" \
  "$LIB/02-platform-ready/youtube/thumbnails/04-divide-drop-combo-1280x720.png" 'DIVIDE. DROP. COMBO.'

# Finder metadata is not part of the deliverable library.
find "$LIB" -type f -name '.DS_Store' -delete

python3 "$REPO_ROOT/scripts/media-library/validate-media_library.py" --write-inventory
python3 "$REPO_ROOT/scripts/media-library/sync-unified-media-library.py"
python3 "$REPO_ROOT/scripts/media-library/validate-unified-media-library.py"

echo "Media library rebuilt and validated: $LIB"
