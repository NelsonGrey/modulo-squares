#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)

python3 "$repo_root/scripts/media-library/validate-media_library.py"
python3 "$repo_root/scripts/media-library/validate-unified-media-library.py"
