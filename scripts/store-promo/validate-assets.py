#!/usr/bin/env python3
"""Validate the Modulo Squares Apple/Google promotion kit.

The validator probes final publication assets with ImageMagick and FFprobe,
writes a CSV manifest even when an asset fails, and exits non-zero when the kit
does not match its production contract.
"""

from __future__ import annotations

import argparse
import csv
import json
import shutil
import subprocess
import sys
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path
from typing import Iterable

sys.path.insert(0, str(Path(__file__).resolve().parent))
import render_provenance  # noqa: E402  (path must be extended first)

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_KIT_ROOT = (
    REPO_ROOT / "packages/mobile/assets/store/promo-kit-2026-08"
)
MANIFEST_COLUMNS = (
    "platform",
    "asset",
    "path",
    "media_type",
    "width",
    "height",
    "format",
    "colorspace",
    "alpha_channel",
    "codec",
    "pixel_format",
    "fps",
    "duration_seconds",
    "size_bytes",
    "status",
    "details",
)


@dataclass(frozen=True)
class ImageRule:
    platform: str
    asset: str
    path: str
    width: int
    height: int
    formats: tuple[str, ...] = ("PNG",)
    require_no_alpha: bool = True
    require_alpha: bool = False
    require_srgb: bool = True
    bit_depth: int = 8
    max_bytes: int | None = None
    # Provenance inputs ("kit:<path>" / "repo:<path>") that render-assets.sh
    # records a content hash for each time it rebuilds this deliverable. An
    # empty tuple means this asset has no automated rebuild pipeline to
    # check freshness against (e.g. hand-authored artwork).
    sources: tuple[str, ...] = ()


@dataclass(frozen=True)
class VideoRule:
    platform: str
    asset: str
    path: str
    width: int
    height: int
    min_duration: float
    max_duration: float
    max_fps: float = 30.0
    codec: str = "h264"
    pixel_format: str = "yuv420p"
    max_bytes: int = 500_000_000
    # Container format_name tokens ffprobe accepts for this deliverable.
    # ffprobe reports the mp4/mov muxer family as the compound string
    # "mov,mp4,m4a,3gp,3g2,mj2"; requiring one of these tokens rejects a
    # renamed .mkv/.ts/etc. that stores-connect would refuse on upload.
    allowed_containers: tuple[str, ...] = ("mp4", "mov")
    # See ImageRule.sources.
    sources: tuple[str, ...] = ()


@dataclass(frozen=True)
class TextRule:
    platform: str
    asset: str
    path: str


APPLE_SCREENSHOTS = (
    "01-drop-numbers-1320x2868.png",
    "02-divide-evenly-1320x2868.png",
    "03-build-combos-1320x2868.png",
    "04-chase-your-best-1320x2868.png",
    "05-learn-the-rules-1320x2868.png",
    "06-remove-ads-1320x2868.png",
)
GOOGLE_SCREENSHOTS = (
    "01-drop-numbers-1080x1920.png",
    "02-divide-evenly-1080x1920.png",
    "03-build-combos-1080x1920.png",
    "04-keep-the-run-going-1080x1920.png",
    "05-learn-the-rules-1080x1920.png",
    "06-customize-settings-1080x1920.png",
)

# Native captures each screenshot is rendered from, in the same order as
# APPLE_SCREENSHOTS/GOOGLE_SCREENSHOTS -- see render-assets.sh's PROMO_SHOTS.
APPLE_SCREENSHOT_CAPTURES = (
    "01-active-gameplay.png",
    "02-start-rules.png",
    "03-score-combo.png",
    "04-paused.png",
    "05-how-to-play.png",
    "07-purchases.png",
)
GOOGLE_SCREENSHOT_CAPTURES = (
    "01-active-gameplay.png",
    "02-start-rules.png",
    "03-score-combo.png",
    "04-paused.png",
    "05-how-to-play.png",
    "06-settings.png",
)

RENDER_TEMPLATE_SOURCE = "repo:scripts/store-promo/render.html"
KEY_ART_GENERATED_SOURCE = "kit:sources/key-art-master-generated.png"

IMAGE_RULES = (
    ImageRule(
        "Apple",
        "App icon",
        "apple/icon/app-icon-1024x1024.png",
        1024,
        1024,
    ),
    ImageRule(
        "Apple",
        "Unlock Premium promotional image",
        "apple/in-app-purchase/remove-ads-1024x1024.png",
        1024,
        1024,
    ),
    *(
        ImageRule(
            "Apple",
            f"iPhone screenshot {index}",
            f"apple/screenshots/iphone-6.9/{filename}",
            1320,
            2868,
            sources=(
                RENDER_TEMPLATE_SOURCE,
                f"kit:sources/captures/iphone-6.9/{capture}",
            ),
        )
        for index, (filename, capture) in enumerate(
            zip(APPLE_SCREENSHOTS, APPLE_SCREENSHOT_CAPTURES), start=1
        )
    ),
    ImageRule(
        "Google",
        "Play Store icon",
        "google/icon/play-store-icon-512x512.png",
        512,
        512,
        require_no_alpha=False,
        require_alpha=True,
        max_bytes=1_024 * 1024,
    ),
    ImageRule(
        "Google",
        "Feature graphic",
        "google/feature-graphic/feature-graphic-1024x500.png",
        1024,
        500,
    ),
    *(
        ImageRule(
            "Google",
            f"Phone screenshot {index}",
            f"google/screenshots/phone/{filename}",
            1080,
            1920,
            sources=(
                RENDER_TEMPLATE_SOURCE,
                f"kit:sources/captures/android-phone/{capture}",
            ),
        )
        for index, (filename, capture) in enumerate(
            zip(GOOGLE_SCREENSHOTS, GOOGLE_SCREENSHOT_CAPTURES), start=1
        )
    ),
    ImageRule(
        "Cross-platform",
        "Key art master",
        "cross-platform/key-art/modulo-squares-key-art-3840x2160.png",
        3840,
        2160,
    ),
    ImageRule(
        "Cross-platform",
        "YouTube thumbnail",
        "cross-platform/social/youtube-thumbnail-1280x720.png",
        1280,
        720,
        sources=(RENDER_TEMPLATE_SOURCE, KEY_ART_GENERATED_SOURCE),
    ),
    ImageRule(
        "Cross-platform",
        "YouTube channel banner",
        "cross-platform/social/youtube-channel-banner-2560x1440.png",
        2560,
        1440,
        sources=(RENDER_TEMPLATE_SOURCE, KEY_ART_GENERATED_SOURCE),
    ),
    ImageRule(
        "Cross-platform",
        "Social square",
        "cross-platform/social/social-square-1080x1080.png",
        1080,
        1080,
        sources=(RENDER_TEMPLATE_SOURCE, KEY_ART_GENERATED_SOURCE),
    ),
)

VIDEO_RULES = (
    VideoRule(
        "Apple",
        "iPhone app preview",
        "apple/app-preview/modulo-squares-app-preview-iphone-portrait-886x1920.mp4",
        886,
        1920,
        15.0,
        30.0,
        sources=("kit:sources/video/iphone-gameplay-raw.mov",),
    ),
    VideoRule(
        "Google",
        "YouTube gameplay promo master",
        "google/video/modulo-squares-youtube-promo-1920x1080.mp4",
        1920,
        1080,
        15.0,
        30.0,
        sources=(
            "kit:apple/app-preview/modulo-squares-app-preview-iphone-portrait-886x1920.mp4",
            "kit:sources/video/plates/01-drop-numbers.png",
            "kit:sources/video/plates/02-think-fast.png",
            "kit:sources/video/plates/03-divide-evenly.png",
            "kit:sources/video/plates/04-build-combos.png",
            "kit:sources/video/plates/05-fill-grid.png",
            "kit:sources/video/plates/06-keep-thinking.png",
        ),
    ),
    VideoRule(
        "Cross-platform",
        "Social clip 1",
        "cross-platform/video-clips/01-drop-and-decide-1080x1920.mp4",
        1080,
        1920,
        4.0,
        15.0,
        sources=("kit:apple/app-preview/modulo-squares-app-preview-iphone-portrait-886x1920.mp4",),
    ),
    VideoRule(
        "Cross-platform",
        "Social clip 2",
        "cross-platform/video-clips/02-combo-and-progress-1080x1920.mp4",
        1080,
        1920,
        4.0,
        15.0,
        sources=("kit:apple/app-preview/modulo-squares-app-preview-iphone-portrait-886x1920.mp4",),
    ),
    VideoRule(
        "Cross-platform",
        "Social clip 3",
        "cross-platform/video-clips/03-speed-and-streak-1080x1920.mp4",
        1080,
        1920,
        4.0,
        15.0,
        sources=("kit:apple/app-preview/modulo-squares-app-preview-iphone-portrait-886x1920.mp4",),
    ),
)

TEXT_RULES = (
    TextRule("Apple", "English (U.S.) listing copy", "copy/apple-en-US.md"),
    TextRule("Google", "English (U.S.) listing copy", "copy/google-en-US.md"),
    TextRule(
        "Cross-platform",
        "Campaign copy",
        "copy/campaign-copy.md",
    ),
    TextRule(
        "Cross-platform",
        "Video production script",
        "copy/video-production-script.md",
    ),
    TextRule("Cross-platform", "Store specifications", "specifications.md"),
    TextRule("Cross-platform", "Kit operator guide", "README.md"),
)


def run(command: list[str]) -> str:
    completed = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        message = completed.stderr.strip() or completed.stdout.strip()
        raise RuntimeError(message or f"Command failed: {' '.join(command)}")
    return completed.stdout.strip()


def has_alpha_channel(channels: str) -> bool:
    channel_name = channels.strip().split()[0].lower()
    return channel_name in {
        "rgba",
        "srgba",
        "cmyka",
        "graya",
        "grayalpha",
        "linearrgba",
    }


def empty_row(platform: str, asset: str, path: str, media_type: str) -> dict[str, object]:
    return {
        column: "" for column in MANIFEST_COLUMNS
    } | {
        "platform": platform,
        "asset": asset,
        "path": path,
        "media_type": media_type,
    }


def validate_image(kit_root: Path, rule: ImageRule) -> dict[str, object]:
    row = empty_row(rule.platform, rule.asset, rule.path, "image")
    path = kit_root / rule.path
    errors: list[str] = []

    if not path.is_file():
        row.update(status="FAIL", details="missing file")
        return row

    row["size_bytes"] = path.stat().st_size
    try:
        output = run(
            [
                "magick",
                "identify",
                "-format",
                "%m\t%w\t%h\t%[channels]\t%z\t%[colorspace]",
                str(path),
            ]
        )
        image_format, width, height, channels, depth, colorspace = output.split("\t")
        width_int = int(width)
        height_int = int(height)
        depth_int = int(depth)
        alpha = has_alpha_channel(channels)
        row.update(
            width=width_int,
            height=height_int,
            format=image_format,
            colorspace=colorspace,
            alpha_channel="yes" if alpha else "no",
        )

        if (width_int, height_int) != (rule.width, rule.height):
            errors.append(
                f"dimensions {width_int}x{height_int}; expected {rule.width}x{rule.height}"
            )
        if image_format.upper() not in rule.formats:
            errors.append(
                f"format {image_format}; expected {' or '.join(rule.formats)}"
            )
        if depth_int != rule.bit_depth:
            errors.append(f"bit depth {depth_int}; expected {rule.bit_depth}")
        if rule.require_srgb and colorspace.lower() not in {"srgb", "rgb"}:
            errors.append(f"colorspace {colorspace}; expected sRGB")
        if rule.require_no_alpha and alpha:
            errors.append("contains an alpha channel; expected flattened RGB")
        if rule.require_alpha and not alpha:
            errors.append("has no alpha channel; expected a 32-bit RGBA PNG")
        if rule.max_bytes is not None and path.stat().st_size > rule.max_bytes:
            errors.append(
                f"size {path.stat().st_size} bytes; maximum {rule.max_bytes} bytes"
            )
    except (RuntimeError, ValueError) as error:
        errors.append(f"probe failed: {error}")

    stale = render_provenance.stale_sources(kit_root, rule.path, rule.sources)
    if stale:
        errors.append(
            "stale output: rerun the renderer -- changed since last render: "
            + ", ".join(stale)
        )

    row.update(
        status="FAIL" if errors else "PASS",
        details="; ".join(errors) if errors else "meets production rule",
    )
    return row


def parse_fps(value: str) -> float:
    if not value or value == "0/0":
        return 0.0
    return float(Fraction(value))


def validate_video(kit_root: Path, rule: VideoRule) -> dict[str, object]:
    row = empty_row(rule.platform, rule.asset, rule.path, "video")
    path = kit_root / rule.path
    errors: list[str] = []

    if not path.is_file():
        row.update(status="FAIL", details="missing file")
        return row

    row["size_bytes"] = path.stat().st_size
    try:
        probe = json.loads(
            run(
                [
                    "ffprobe",
                    "-v",
                    "error",
                    "-select_streams",
                    "v:0",
                    "-show_entries",
                    "stream=codec_name,width,height,pix_fmt,avg_frame_rate,r_frame_rate",
                    "-show_entries",
                    "format=format_name,duration,size",
                    "-of",
                    "json",
                    str(path),
                ]
            )
        )
        stream = probe["streams"][0]
        file_format = probe["format"]
        width = int(stream["width"])
        height = int(stream["height"])
        duration = float(file_format["duration"])
        fps = parse_fps(stream.get("avg_frame_rate") or stream.get("r_frame_rate", ""))
        codec = stream.get("codec_name", "")
        pixel_format = stream.get("pix_fmt", "")
        container_format = file_format.get("format_name", "")
        row.update(
            width=width,
            height=height,
            format=container_format,
            codec=codec,
            pixel_format=pixel_format,
            fps=f"{fps:.3f}",
            duration_seconds=f"{duration:.3f}",
        )

        # ffprobe reports the container as a comma-separated list of muxer
        # aliases (e.g. "mov,mp4,m4a,3gp,3g2,mj2"); a correctly encoded
        # H.264/yuv420p stream renamed into an unsupported container (e.g.
        # Matroska, MPEG-TS) would otherwise pass every other check here but
        # be rejected by App Store Connect/Play Console on actual upload.
        container_tokens = {
            token.strip().lower() for token in container_format.split(",") if token.strip()
        }
        if not container_tokens & set(rule.allowed_containers):
            errors.append(
                f"container {container_format or '(unknown)'}; expected one of "
                f"{' or '.join(rule.allowed_containers)}"
            )

        if (width, height) != (rule.width, rule.height):
            errors.append(
                f"dimensions {width}x{height}; expected {rule.width}x{rule.height}"
            )
        if codec != rule.codec:
            errors.append(f"codec {codec}; expected {rule.codec}")
        if pixel_format != rule.pixel_format:
            errors.append(
                f"pixel format {pixel_format}; expected {rule.pixel_format}"
            )
        if fps <= 0 or fps > rule.max_fps + 0.001:
            errors.append(f"frame rate {fps:.3f}; maximum {rule.max_fps:.3f}")
        if not rule.min_duration <= duration <= rule.max_duration:
            errors.append(
                f"duration {duration:.3f}s; expected {rule.min_duration:.0f}-{rule.max_duration:.0f}s"
            )
        if path.stat().st_size > rule.max_bytes:
            errors.append(
                f"size {path.stat().st_size} bytes; maximum {rule.max_bytes} bytes"
            )
    except (IndexError, KeyError, RuntimeError, ValueError, json.JSONDecodeError) as error:
        errors.append(f"probe failed: {error}")

    stale = render_provenance.stale_sources(kit_root, rule.path, rule.sources)
    if stale:
        errors.append(
            "stale output: rerun the renderer -- changed since last render: "
            + ", ".join(stale)
        )

    row.update(
        status="FAIL" if errors else "PASS",
        details="; ".join(errors) if errors else "meets production rule",
    )
    return row


def validate_text(kit_root: Path, rule: TextRule) -> dict[str, object]:
    row = empty_row(rule.platform, rule.asset, rule.path, "text")
    path = kit_root / rule.path
    if not path.is_file():
        row.update(status="FAIL", details="missing file")
        return row

    size = path.stat().st_size
    row["size_bytes"] = size
    row["format"] = "Markdown"
    if size == 0 or not path.read_text(encoding="utf-8").strip():
        row.update(status="FAIL", details="file is empty")
    else:
        row.update(status="PASS", details="present and non-empty")
    return row


def unexpected_media_rows(
    kit_root: Path,
    rules: Iterable[ImageRule | VideoRule],
) -> list[dict[str, object]]:
    expected = {rule.path for rule in rules}
    checked_directories = {
        "apple/screenshots/iphone-6.9": {".png", ".jpg", ".jpeg"},
        "google/screenshots/phone": {".png", ".jpg", ".jpeg"},
        "cross-platform/social": {".png", ".jpg", ".jpeg"},
        "cross-platform/video-clips": {".mp4", ".mov", ".m4v"},
    }
    rows: list[dict[str, object]] = []
    for relative_directory, extensions in checked_directories.items():
        directory = kit_root / relative_directory
        if not directory.is_dir():
            continue
        for path in sorted(directory.iterdir()):
            relative_path = path.relative_to(kit_root).as_posix()
            if path.is_file() and path.suffix.lower() in extensions and relative_path not in expected:
                row = empty_row(
                    "Unknown",
                    "Unexpected publication asset",
                    relative_path,
                    "unknown",
                )
                row.update(
                    size_bytes=path.stat().st_size,
                    status="FAIL",
                    details="remove stale media or add an explicit validation rule",
                )
                rows.append(row)
    return rows


def write_manifest(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=MANIFEST_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--kit-root",
        type=Path,
        default=DEFAULT_KIT_ROOT,
        help="Promotion-kit root (defaults to this repository's August 2026 kit).",
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        help="Manifest destination (defaults to KIT_ROOT/asset-manifest.csv).",
    )
    parser.add_argument(
        "--bootstrap-provenance",
        action="store_true",
        help=(
            "Record current source hashes as the baseline for every rule "
            "with declared sources, without validating anything. Use this "
            "after confirming the kit's rendered deliverables genuinely "
            "match their sources (e.g. right after a full re-render, or "
            "once when adopting this staleness check on an already-current "
            "kit) -- it does not rebuild or check any asset."
        ),
    )
    args = parser.parse_args()

    kit_root = args.kit_root.resolve()

    if args.bootstrap_provenance:
        for rule in (*IMAGE_RULES, *VIDEO_RULES):
            if rule.sources:
                render_provenance.record(kit_root, rule.path, list(rule.sources))
        print(f"Recorded provenance baseline for {kit_root}")
        return 0

    missing_tools = [tool for tool in ("magick", "ffprobe") if shutil.which(tool) is None]
    if missing_tools:
        print(
            f"Missing required command(s): {', '.join(missing_tools)}",
            file=sys.stderr,
        )
        return 2

    manifest = (args.manifest or kit_root / "asset-manifest.csv").resolve()
    rows = [validate_image(kit_root, rule) for rule in IMAGE_RULES]
    rows.extend(validate_video(kit_root, rule) for rule in VIDEO_RULES)
    rows.extend(validate_text(kit_root, rule) for rule in TEXT_RULES)
    rows.extend(unexpected_media_rows(kit_root, (*IMAGE_RULES, *VIDEO_RULES)))
    write_manifest(manifest, rows)

    failures = [row for row in rows if row["status"] != "PASS"]
    print(f"Wrote {manifest}")
    print(f"Validated {len(rows)} deliverables: {len(rows) - len(failures)} passed, {len(failures)} failed")
    for row in failures:
        print(f"FAIL {row['path']}: {row['details']}", file=sys.stderr)
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
