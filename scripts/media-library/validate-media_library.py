#!/usr/bin/env python3
"""Validate the curated Modulo Squares social media library and inventory sources."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import subprocess
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
LIB = REPO / "media-library"
MEDIA_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".svg", ".mp4", ".mov", ".m4v"}
EXCLUDED_PARTS = {".git", "node_modules", "build", "Pods", ".dart_tool", "media-library"}

EXPECTED_IMAGES = {
    "00-brand/profile/modulo-squares-profile-1024x1024.png": (1024, 1024),
    "00-brand/profile/modulo-squares-profile-512x512.png": (512, 512),
    "00-brand/profile/modulo-squares-profile-400x400.png": (400, 400),
    "00-brand/profile/modulo-squares-profile-320x320.png": (320, 320),
    "00-brand/profile/modulo-squares-profile-256x256.png": (256, 256),
    "00-brand/profile/modulo-squares-profile-200x200.png": (200, 200),
    "00-brand/headers/youtube-channel-banner-2560x1440.png": (2560, 1440),
    "00-brand/headers/x-header-1500x500.png": (1500, 500),
    "00-brand/headers/facebook-cover-1640x624.png": (1640, 624),
    "00-brand/headers/reddit-banner-1920x384.png": (1920, 384),
    "01-evergreen/feed-square/brand-drop-numbers-1080x1080.png": (1080, 1080),
    "01-evergreen/feed-portrait/brand-drop-numbers-1080x1350.png": (1080, 1350),
    "01-evergreen/feed-landscape/key-art-1200x630.png": (1200, 630),
    "01-evergreen/feed-landscape/key-art-1600x900.png": (1600, 900),
    "02-platform-ready/reddit/community-icon-256x256.png": (256, 256),
    "02-platform-ready/reddit/community-banner-1920x384.png": (1920, 384),
    "02-platform-ready/tiktok/profile-200x200.png": (200, 200),
}

for index in range(1, 7):
    for folder, dimensions in (("feed-square", (1080, 1080)), ("feed-portrait", (1080, 1350))):
        matches = list((LIB / "01-evergreen" / folder).glob(f"{index:02d}-*-{dimensions[0]}x{dimensions[1]}.png"))
        if len(matches) == 1:
            EXPECTED_IMAGES[str(matches[0].relative_to(LIB))] = dimensions

for thumbnail in (LIB / "02-platform-ready/youtube/thumbnails").glob("*.png"):
    EXPECTED_IMAGES[str(thumbnail.relative_to(LIB))] = (1280, 720)


def run(*args: str) -> str:
    return subprocess.check_output(args, text=True).strip()


def image_metadata(path: Path) -> dict[str, str | int | float]:
    width, height, image_format, opaque = run(
        "magick", "identify", "-format", "%w\t%h\t%m\t%[opaque]", str(path)
    ).split("\t")
    return {
        "media_type": "image",
        "width": int(width),
        "height": int(height),
        "format": image_format,
        "codec": "",
        "pixel_format": "",
        "fps": "",
        "duration_seconds": "",
        "alpha": "no" if opaque.lower() == "true" else "yes",
    }


def video_metadata(path: Path) -> dict[str, str | int | float]:
    probe = json.loads(run(
        "ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_entries", "stream=width,height,codec_name,pix_fmt,avg_frame_rate:format=duration,format_name",
        "-of", "json", str(path),
    ))
    stream = probe["streams"][0]
    numerator, denominator = (int(value) for value in stream["avg_frame_rate"].split("/"))
    return {
        "media_type": "video",
        "width": int(stream["width"]),
        "height": int(stream["height"]),
        "format": probe["format"].get("format_name", path.suffix.lstrip(".")),
        "codec": stream.get("codec_name", ""),
        "pixel_format": stream.get("pix_fmt", ""),
        "fps": round(numerator / denominator, 3) if denominator else 0,
        "duration_seconds": round(float(probe["format"]["duration"]), 3),
        "alpha": "",
    }


def classify_source(path: Path) -> tuple[str, str]:
    rel = str(path.relative_to(REPO))
    if "/promo-kit-2026-08/sources/" in rel:
        return "review-evidence-not-marketing", "raw capture or working source"
    if rel.startswith("icons/archive/"):
        return "quarantine-do-not-upload", "superseded icon archive"
    if rel.startswith("icons/proposed/"):
        return "quarantine-do-not-upload", "unapproved proposed icon direction"
    if rel.startswith("output/imagegen/"):
        return "review-evidence-not-marketing", "prior generated working output; use curated derivative instead"
    if "/promo-kit-2026-08/" in rel:
        return "curated-source", "validated promotion-kit publication asset"
    if "/fastlane/" in rel or "/assets/store/screenshots/" in rel:
        return "store-only-or-legacy", "store pipeline asset; not selected as social master"
    if "/Assets.xcassets/" in rel or "/android/app/src/main/res/" in rel or "/assets/icons/" in rel or "/web/" in rel:
        return "runtime-technical", "application runtime asset; not a social publication file"
    if rel.startswith("icons/"):
        return "runtime-technical", "icon production asset; use canonical profile export"
    return "review-required", "media found outside known publication paths"


def iter_source_media():
    for path in sorted(REPO.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in MEDIA_EXTENSIONS:
            continue
        if any(part in EXCLUDED_PARTS for part in path.relative_to(REPO).parts):
            continue
        yield path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_source_inventory() -> None:
    output = LIB / "_inventory/source-media.csv"
    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(("source_path", "size_bytes", "classification", "reason", "sha256"))
        for path in iter_source_media():
            classification, reason = classify_source(path)
            writer.writerow((str(path.relative_to(REPO)), path.stat().st_size, classification, reason, sha256(path)))


def validate() -> int:
    failures: list[str] = []
    rows: list[dict[str, object]] = []
    for rel, dimensions in sorted(EXPECTED_IMAGES.items()):
        path = LIB / rel
        if not path.exists():
            failures.append(f"missing expected image: {rel}")
            continue
        metadata = image_metadata(path)
        if (metadata["width"], metadata["height"]) != dimensions:
            failures.append(f"wrong dimensions for {rel}: {metadata['width']}x{metadata['height']}")
        if metadata["alpha"] != "no":
            failures.append(f"upload-facing image contains alpha: {rel}")

    library_media = sorted(
        path for path in LIB.rglob("*")
        if path.is_file() and path.suffix.lower() in MEDIA_EXTENSIONS
        and "quarantine-do-not-upload" not in path.parts
        and "review-evidence-not-marketing" not in path.parts
    )
    for path in library_media:
        rel = str(path.relative_to(LIB))
        try:
            metadata = video_metadata(path) if path.suffix.lower() in {".mp4", ".mov", ".m4v"} else image_metadata(path)
        except (subprocess.CalledProcessError, KeyError, ValueError, json.JSONDecodeError) as error:
            failures.append(f"cannot inspect {rel}: {error}")
            continue
        if metadata["media_type"] == "video":
            if metadata["codec"] != "h264" or metadata["pixel_format"] != "yuv420p":
                failures.append(f"video is not H.264/yuv420p: {rel}")
            if float(metadata["fps"]) > 30.01:
                failures.append(f"video exceeds 30 fps: {rel}")
        rows.append({"path": rel, "size_bytes": path.stat().st_size, "sha256": sha256(path), **metadata})

    manifest_path = LIB / "_inventory/library-manifest.csv"
    fieldnames = ["path", "media_type", "width", "height", "format", "alpha", "codec", "pixel_format", "fps", "duration_seconds", "size_bytes", "sha256"]
    with manifest_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    checksum_path = LIB / "_inventory/library-sha256.txt"
    with checksum_path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(f"{row['sha256']}  {row['path']}\n")

    if failures:
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        print(f"Validation failed: {len(failures)} issue(s)", file=sys.stderr)
        return 1
    print(f"PASS: {len(rows)} upload-facing media files validated")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-inventory", action="store_true", help="also rebuild repository source-media inventory")
    args = parser.parse_args()
    if args.write_inventory:
        write_source_inventory()
    return validate()


if __name__ == "__main__":
    raise SystemExit(main())
