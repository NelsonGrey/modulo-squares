#!/usr/bin/env bash
# Publishes the Google Play store listing (title, descriptions, icon, feature
# graphic, phone screenshots) via the Android Publisher API, using the
# google-play-console-service service account. Productizes the one-off manual
# API push done 2026-07-31 (see docs/GO_LIVE_RUNBOOK.md §2.3c) into a
# re-runnable script.
#
# Source content lives at packages/mobile/android/fastlane/metadata/android/en-US/
# (the same directory layout fastlane's own `supply` action expects), so
# updating the listing later is just editing those files and re-running this.
#
# Auth gotcha (cost real time to work out the first time, see runbook):
# `gcloud auth print-access-token --impersonate-service-account=...` silently
# drops any --scopes flag. The fix is to operate on the *directly activated*
# service account identity (gcloud auth activate-service-account --key-file=...
# once, ahead of time) and pass --scopes explicitly on print-access-token.
#
# Usage: scripts/store-promo/publish-play-listing.sh
#   Requires: gcloud CLI with google-play-console-service@modulo-squares-prod
#   already activated (gcloud auth list), or GOOGLE_PLAY_SA_KEY_FILE set to a
#   service-account JSON key to activate fresh.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
METADATA="$REPO_ROOT/packages/mobile/android/fastlane/metadata/android/en-US"
PACKAGE_NAME="com.modulosquares.app.android"
SA_ACCOUNT="google-play-console-service@modulo-squares-prod.iam.gserviceaccount.com"
API="https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}"
UPLOAD_API="https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${PACKAGE_NAME}"

if [ -n "${GOOGLE_PLAY_SA_KEY_FILE:-}" ]; then
  gcloud auth activate-service-account "$SA_ACCOUNT" --key-file="$GOOGLE_PLAY_SA_KEY_FILE"
fi

TOKEN=$(gcloud auth print-access-token --account="$SA_ACCOUNT" --scopes=https://www.googleapis.com/auth/androidpublisher)

curl_json() {
  curl -sf -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$@"
}

echo "Opening a new edit..."
EDIT_ID=$(curl_json -X POST "$API/edits" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
echo "Edit ID: $EDIT_ID"

echo "Updating en-US listing text..."
curl_json -X PUT "$API/edits/$EDIT_ID/listings/en-US" -d @- <<JSON
{
  "language": "en-US",
  "title": $(python3 -c "import json,sys; print(json.dumps(open(sys.argv[1]).read().strip()))" "$METADATA/title.txt"),
  "shortDescription": $(python3 -c "import json,sys; print(json.dumps(open(sys.argv[1]).read().strip()))" "$METADATA/short_description.txt"),
  "fullDescription": $(python3 -c "import json,sys; print(json.dumps(open(sys.argv[1]).read()))" "$METADATA/full_description.txt")
}
JSON

upload_image() {
  local image_type="$1"
  local file_path="$2"
  echo "Uploading $image_type: $(basename "$file_path")"
  curl -sf -H "Authorization: Bearer $TOKEN" -H "Content-Type: image/png" \
    -X POST --data-binary "@$file_path" \
    "$UPLOAD_API/edits/$EDIT_ID/listings/en-US/$image_type" > /dev/null
}

# Icon and feature graphic are singletons -- clear existing before re-upload
# so re-runs don't just append duplicates.
curl_json -X DELETE "$API/edits/$EDIT_ID/listings/en-US/icon" > /dev/null 2>&1 || true
curl_json -X DELETE "$API/edits/$EDIT_ID/listings/en-US/featureGraphic" > /dev/null 2>&1 || true
curl_json -X DELETE "$API/edits/$EDIT_ID/listings/en-US/phoneScreenshots" > /dev/null 2>&1 || true

upload_image "icon" "$METADATA/images/icon.png"
upload_image "featureGraphic" "$METADATA/images/featureGraphic.png"
for shot in "$METADATA"/images/phoneScreenshots/*.png; do
  upload_image "phoneScreenshots" "$shot"
done

echo "Committing edit..."
curl_json -X POST "$API/edits/$EDIT_ID:commit" | python3 -c "import json,sys; d=json.load(sys.stdin); print('Committed edit', d.get('id'))"

echo "Verifying via read-back..."
VERIFY_EDIT=$(curl_json -X POST "$API/edits" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
curl_json "$API/edits/$VERIFY_EDIT/listings/en-US" | python3 -m json.tool
curl_json -X DELETE "$API/edits/$VERIFY_EDIT" > /dev/null 2>&1 || true

echo "✅ Play Store listing published and verified."
