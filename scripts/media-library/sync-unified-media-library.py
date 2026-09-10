#!/usr/bin/env python3
"""Build the shared publishing-first media-library interface.

The migration is intentionally additive. Legacy library paths remain in place;
this script creates or refreshes only the unified contract paths.
"""

from __future__ import annotations

import csv
import hashlib
import os
import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / "media-library"
# The repo is normally identified by its checkout directory name, but a named
# git worktree or a `git clone ... modulo-squares-review` breaks that. Allow an
# explicit override so those checkouts can still rebuild.
PROJECT = os.environ.get("MEDIA_LIBRARY_PROJECT", "").strip() or ROOT.name
MEDIA_EXTENSIONS = {".png", ".jpg", ".jpeg", ".svg", ".mp4", ".mov", ".m4v", ".srt", ".pdf", ".ttf", ".ico"}
PLATFORMS = {
    "facebook": ("profile", "header", "feed", "reels-stories"),
    "instagram": ("profile", "feed", "reels-stories"),
    "reddit": ("profile", "header", "feed", "video"),
    "threads": ("profile", "feed", "video"),
    "tiktok": ("profile", "video"),
    "x": ("profile", "header", "feed", "video"),
    "youtube": ("profile", "header", "thumbnails", "long-form", "shorts"),
}
PROJECT_PREFIX = {"modulo-squares": "MS"}


def ensure(relative: str) -> Path:
    path = LIB / relative
    path.mkdir(parents=True, exist_ok=True)
    return path


def write(relative: str, content: str, *, overwrite: bool = True) -> None:
    path = LIB / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    if overwrite or not path.exists():
        path.write_text(content.rstrip() + "\n", encoding="utf-8")


def copy(source: str | Path, destination: str | Path) -> bool:
    src = source if isinstance(source, Path) else ROOT / source
    dst = destination if isinstance(destination, Path) else LIB / destination
    if not src.is_file():
        return False
    if src.resolve() == dst.resolve():
        return True
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    return True


def copy_tree(source: str | Path, destination: str | Path, extensions: set[str] | None = None) -> int:
    src = source if isinstance(source, Path) else ROOT / source
    dst = destination if isinstance(destination, Path) else LIB / destination
    if not src.is_dir():
        return 0
    count = 0
    for item in sorted(src.rglob("*")):
        if not item.is_file() or item.name == ".DS_Store":
            continue
        if extensions and item.suffix.lower() not in extensions:
            continue
        target = dst / item.relative_to(src)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(item, target)
        count += 1
    return count


def copy_glob(pattern: str, destination: str, extensions: set[str] | None = None) -> int:
    count = 0
    for item in sorted(ROOT.glob(pattern)):
        if not item.is_file() or item.name == ".DS_Store":
            continue
        if extensions and item.suffix.lower() not in extensions:
            continue
        count += int(copy(item, LIB / destination / item.name))
    return count


def common_skeleton() -> None:
    for directory in (
        "00-control",
        "01-brand/masters",
        "01-brand/profiles",
        "01-brand/headers/facebook",
        "01-brand/headers/reddit",
        "01-brand/headers/x",
        "01-brand/headers/youtube",
        "01-brand/guidelines",
        "01-brand/fonts",
        "02-campaigns",
        "04-copy",
        "05-store-listings/apple/icon",
        "05-store-listings/apple/screenshots",
        "05-store-listings/apple/previews",
        "05-store-listings/google-play/icon",
        "05-store-listings/google-play/feature-graphic",
        "05-store-listings/google-play/screenshots",
        "05-store-listings/google-play/previews",
        "_source/brand",
        "_source/captures/ios",
        "_source/captures/android",
        "_source/captures/web",
        "_source/editable",
        "_source/video",
        "_inventory",
        "_hold/review-evidence",
        "_hold/quarantine",
    ):
        ensure(directory)
    for platform, placements in PLATFORMS.items():
        ensure(f"03-platform-ready/{platform}")
        for placement in placements:
            ensure(f"03-platform-ready/{platform}/{placement}")


def preserve_legacy_guide() -> None:
    legacy = LIB / "00-control/LEGACY_LIBRARY_GUIDE.md"
    if not legacy.exists() and (LIB / "README.md").is_file():
        shutil.copy2(LIB / "README.md", legacy)


def campaign(campaign_id: str, slug: str, title: str, objective: str, limitations: str) -> Path:
    base = ensure(f"02-campaigns/{campaign_id}-{slug}")
    for child in ("stills/square", "stills/portrait", "stills/landscape", "stills/vertical", "video/landscape", "video/vertical", "captions"):
        (base / child).mkdir(parents=True, exist_ok=True)
    (base / "CAMPAIGN.md").write_text(
        f"# {campaign_id}: {title}\n\n"
        f"- Status: DRAFT unless an asset is marked READY_LOCAL in the publishing index\n"
        f"- Objective: {objective}\n"
        "- Publication rule: verify the active account, live destination, product state, crop, claims, and rights immediately before publishing.\n"
        f"- Limitations: {limitations}\n",
        encoding="utf-8",
    )
    return base


def copy_campaign_file(source: Path, base: Path) -> None:
    name = source.name.lower()
    if source.suffix.lower() in {".mp4", ".mov", ".m4v"}:
        placement = "video/vertical" if "1080x1920" in name else "video/landscape"
    elif source.suffix.lower() == ".srt":
        placement = "captions"
    elif "1080x1080" in name or "square" in name:
        placement = "stills/square"
    elif "1080x1350" in name or "portrait" in name:
        placement = "stills/portrait"
    elif "1080x1920" in name or "story" in name:
        placement = "stills/vertical"
    else:
        placement = "stills/landscape"
    copy(source, base / placement / source.name)


def copy_profile_to_platforms(source: Path) -> None:
    for platform in PLATFORMS:
        copy(source, LIB / f"03-platform-ready/{platform}/profile/{source.name}")


def distribute_feed(files: list[Path], project: str) -> None:
    for source in files:
        name = source.name
        if "portrait" in name or "1080x1350" in name:
            destinations = ("facebook", "instagram", "threads")
        elif "landscape" in name or "1600x900" in name or "1200x630" in name:
            destinations = ("facebook", "reddit", "x")
        elif "story" in name or "1080x1920" in name:
            for platform in ("facebook", "instagram"):
                copy(source, LIB / f"03-platform-ready/{platform}/reels-stories/{name}")
            continue
        else:
            destinations = ("facebook", "instagram", "reddit", "threads", "x")
        for platform in destinations:
            copy(source, LIB / f"03-platform-ready/{platform}/feed/{name}")


def distribute_vertical_videos(files: list[Path]) -> None:
    for source in files:
        for platform, placement in (
            ("facebook", "reels-stories"),
            ("instagram", "reels-stories"),
            ("reddit", "video"),
            ("threads", "video"),
            ("tiktok", "video"),
            ("x", "video"),
            ("youtube", "shorts"),
        ):
            copy(source, LIB / f"03-platform-ready/{platform}/{placement}/{source.name}")


def markdown_alt_text_to_csv(source: Path, destination: Path) -> None:
    rows: list[tuple[str, str]] = []
    if source.is_file():
        for line in source.read_text(encoding="utf-8").splitlines():
            if not line.startswith("|") or "---" in line or "Alt text" in line or "Asset family" in line:
                continue
            cells = [cell.strip() for cell in line.strip("|").split("|")]
            if len(cells) >= 2:
                rows.append((cells[0], cells[1]))
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(("asset_id", "alt_text"))
        writer.writerows(rows)


def migrate_modulo() -> None:
    copy("media-library/_inventory/ASSET_AUDIT.md", "00-control/READINESS.md")
    write("00-control/GAP_REGISTER.md", """# Gap register

| Gap | Status | Next action |
|---|---|---|
| Public App Store and Google Play availability | BLOCKED | Verify from the posting device and region before using availability or download claims. |
| YouTube banner crop | NEEDS_PLATFORM_PREVIEW | Preview in YouTube Studio and record the review date. |
| Testimonials, ratings, download counts, and player-generated leaderboard proof | BLOCKED | Use only after current evidence exists and publication is approved. |
""")
    copy("media-library/04-copy/OWNED_PROPERTIES.md", "00-control/OWNED_PROPERTIES.md")
    copy("media-library/_inventory/ASSET_AUDIT.md", "00-control/PLATFORM_SPECS.md")
    copy("media-library/04-copy/PUBLISHING_CHECKLIST.md", "00-control/PUBLISHING_CHECKLIST.md")
    copy_tree("media-library/00-brand/profile", "01-brand/profiles", MEDIA_EXTENSIONS)
    header_map = {"facebook-cover": "facebook", "reddit-banner": "reddit", "x-header": "x", "youtube-channel": "youtube"}
    for item in (ROOT / "media-library/00-brand/headers").glob("*"):
        for token, platform in header_map.items():
            if token in item.name:
                copy(item, LIB / f"01-brand/headers/{platform}/{item.name}")
                copy(item, LIB / f"03-platform-ready/{platform}/header/{item.name}")
    profile = ROOT / "media-library/00-brand/profile/modulo-squares-profile-1024x1024.png"
    copy_profile_to_platforms(profile)
    specs = [
        ("C001", "drop-numbers", "Drop numbers", "Introduce the core falling-number decision.", "Storefront availability remains release-gated."),
        ("C002", "divide-evenly", "Divide evenly", "Explain the divisor-bucket rule.", "Avoid retired remainder-bucket language."),
        ("C003", "build-combos", "Build combos", "Show score, combo, and progression feedback.", "Do not imply guaranteed performance gains."),
        ("C004", "keep-the-run-going", "Keep the run going", "Show pace and run tension.", "Scores and leaderboard claims require current evidence."),
        ("C005", "learn-the-rules", "Learn the rules", "Teach the game loop clearly.", "Use current divisibility mechanics only."),
        ("C006", "customize-settings", "Customize settings", "Explain visual cues and settings.", "Describe only settings visible in the current product."),
    ]
    feed_files: list[Path] = []
    for cid, slug, title, objective, limits in specs:
        base = campaign(cid, slug, title, objective, limits)
        index = int(cid[-3:])
        patterns = [f"media-library/01-evergreen/**/*{index:02d}-*.png"]
        if cid == "C001":
            patterns += ["media-library/01-evergreen/**/*brand-drop-numbers*.png", "media-library/01-evergreen/feed-landscape/key-art-*.png"]
        for pattern in patterns:
            for item in sorted(ROOT.glob(pattern)):
                copy_campaign_file(item, base)
                feed_files.append(item)
    video_campaign = campaign("C007", "product-tour", "Product tour and tutorials", "Show gameplay and onboarding in motion.", "Silent caption-led masters; preview captions and add only licensed platform audio.")
    for item in sorted((ROOT / "media-library/03-video").rglob("*")):
        if item.is_file() and item.suffix.lower() in {".mp4", ".srt"}:
            copy_campaign_file(item, video_campaign)
    distribute_feed(sorted(set(feed_files)), PROJECT)
    verticals = sorted((ROOT / "media-library/03-video/vertical-shorts").glob("*.mp4"))
    distribute_vertical_videos(verticals)
    copy_tree("media-library/02-platform-ready/youtube/thumbnails", "03-platform-ready/youtube/thumbnails", MEDIA_EXTENSIONS)
    copy_tree("media-library/03-video/tutorials", "03-platform-ready/youtube/long-form", MEDIA_EXTENSIONS)
    copy_tree("media-library/03-video/landscape", "03-platform-ready/youtube/long-form", MEDIA_EXTENSIONS)
    for source, destination in (
        ("media-library/04-copy/PROFILE_COPY.md", "04-copy/PROFILE_COPY.md"),
        ("media-library/04-copy/POST_LIBRARY.md", "04-copy/POST_LIBRARY.md"),
        ("media-library/04-copy/30_DAY_CALENDAR.md", "04-copy/CONTENT_CALENDAR.md"),
        ("packages/mobile/assets/store/promo-kit-2026-08/copy/youtube-tutorials.md", "04-copy/VIDEO_METADATA.md"),
    ):
        copy(source, destination)
    markdown_alt_text_to_csv(ROOT / "media-library/04-copy/ALT_TEXT.md", LIB / "04-copy/ALT_TEXT.csv")
    copy_tree("packages/mobile/assets/store/promo-kit-2026-08/apple/icon", "05-store-listings/apple/icon", MEDIA_EXTENSIONS)
    copy_tree("packages/mobile/assets/store/promo-kit-2026-08/apple/screenshots", "05-store-listings/apple/screenshots", MEDIA_EXTENSIONS)
    copy_tree("packages/mobile/assets/store/promo-kit-2026-08/apple/app-preview", "05-store-listings/apple/previews", MEDIA_EXTENSIONS)
    copy_tree("packages/mobile/assets/store/promo-kit-2026-08/google/icon", "05-store-listings/google-play/icon", MEDIA_EXTENSIONS)
    copy_tree("packages/mobile/assets/store/promo-kit-2026-08/google/feature-graphic", "05-store-listings/google-play/feature-graphic", MEDIA_EXTENSIONS)
    copy_tree("packages/mobile/assets/store/promo-kit-2026-08/google/screenshots", "05-store-listings/google-play/screenshots", MEDIA_EXTENSIONS)
    write("_source/README.md", "# Source locations\n\nThe validated promotion kit at `packages/mobile/assets/store/promo-kit-2026-08/` remains the visual source of truth. Raw captures and working video sources remain there and are not routine upload selections.")
    copy("media-library/_inventory/PROVENANCE.md", "_inventory/PROVENANCE.md")
    write("_hold/review-evidence/README.md", "# Review evidence\n\nRaw captures and working output remain indexed outside this folder and must not be published as marketing.")
    write("_hold/quarantine/README.md", "# Quarantine\n\nSuperseded and unapproved icon families remain outside the unified publishing path. Do not upload them.")


def probe(path: Path) -> dict[str, str]:
    values = {"width": "", "height": "", "duration_seconds": "", "codec": "", "pixel_format": "", "audio": "", "alpha": ""}
    if path.suffix.lower() in {".mp4", ".mov", ".m4v"} and shutil.which("ffprobe"):
        result = subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "stream=codec_type,codec_name,pix_fmt,width,height:format=duration", "-of", "csv=p=0", str(path)],
            capture_output=True, text=True, check=False,
        )
        for line in result.stdout.splitlines():
            cells = line.split(",")
            if cells and cells[0] == "video" and len(cells) >= 5:
                values.update(codec=cells[1], width=cells[2], height=cells[3], pixel_format=cells[4])
            elif cells and cells[0] == "audio":
                values["audio"] = "yes"
            elif len(cells) == 1 and re.fullmatch(r"\d+(\.\d+)?", cells[0]):
                values["duration_seconds"] = cells[0]
    elif path.suffix.lower() in {".png", ".jpg", ".jpeg"} and shutil.which("sips"):
        result = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", "-g", "hasAlpha", str(path)], capture_output=True, text=True, check=False)
        for line in result.stdout.splitlines():
            if "pixelWidth:" in line:
                values["width"] = line.split(":", 1)[1].strip()
            elif "pixelHeight:" in line:
                values["height"] = line.split(":", 1)[1].strip()
            elif "hasAlpha:" in line:
                values["alpha"] = line.split(":", 1)[1].strip().lower()
    return values


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def status_for(path: Path) -> str:
    name = str(path.relative_to(LIB)).lower()
    if "candidate" in name or "unverified" in name:
        return "NEEDS_PLATFORM_PREVIEW"
    if "/headers/" in f"/{name}" or (name.startswith("03-platform-ready/") and "/header/" in f"/{name}"):
        return "NEEDS_PLATFORM_PREVIEW"
    return "READY_LOCAL"


def campaign_for(path: Path) -> str:
    match = re.search(r"/(C\d{3})-", "/" + str(path.relative_to(LIB)))
    if match:
        return match.group(1)
    name = path.name
    old = re.match(r"(\d{2})-", name)
    return f"C{int(old.group(1)):03d}" if old else "C000"


def platform_for(path: Path) -> str:
    parts = path.relative_to(LIB).parts
    return parts[1] if parts and parts[0] == "03-platform-ready" else ""


def copy_id_for(path: Path, platform: str) -> str:
    placement = path.relative_to(LIB / f"03-platform-ready/{platform}").parts[0]
    if placement in {"profile", "header"}:
        return "NONE"
    name = path.name.lower()
    number_match = re.match(r"(\d{2})-", name)
    number = int(number_match.group(1)) if number_match else 1
    if platform == "youtube":
        if "official-gameplay" in name or "youtube-promo" in name:
            return "YT01"
        tutorial_map = {1: "YT02", 2: "YT03", 3: "YT04", 4: "YT05"}
        return tutorial_map.get(number, "YT01")
    mappings = {
        "facebook": {1: "FB01", 2: "FB02", 3: "FB02", 4: "FB03", 5: "FB03", 6: "FB02"},
        "instagram": {1: "IG02", 2: "IG02", 3: "IG03", 4: "IG03", 5: "IG04", 6: "IG05"},
        "reddit": {1: "R03", 2: "R03", 3: "R02", 4: "R02", 5: "R03", 6: "R02"},
        "threads": {1: "T01", 2: "T02", 3: "T02", 4: "T04", 5: "T03", 6: "T05"},
        "tiktok": {1: "TK01", 2: "TK04", 3: "TK02", 4: "TK03", 5: "TK04", 6: "TK05"},
        "x": {1: "X01", 2: "X03", 3: "X05", 4: "X02", 5: "X04", 6: "X06"},
    }
    return mappings[platform].get(number, next(iter(mappings[platform].values())))


def make_indexes_and_manifests() -> None:
    prefix = PROJECT_PREFIX[PROJECT]
    previous_by_path: dict[str, str] = {}
    previous_by_parent_sha: dict[tuple[str, str], str] = {}
    previous_manifest = LIB / "_inventory/ASSET_MANIFEST.csv"
    if previous_manifest.is_file():
        with previous_manifest.open(newline="", encoding="utf-8") as handle:
            for row in csv.DictReader(handle):
                if row.get("asset_id") and row.get("path"):
                    previous_by_path[row["path"]] = row["asset_id"]
                if row.get("asset_id") and row.get("sha256") and row.get("path"):
                    key = (str(Path(row["path"]).parent), row["sha256"])
                    previous_by_parent_sha.setdefault(key, row["asset_id"])
    # Build the source manifest first so every upload asset that is a byte-for-
    # byte copy of a source can carry that source's stable id (provenance /
    # replacement / restricted-source checks depend on the link).
    source_rows = []
    source_id_by_sha: dict[str, str] = {}
    source_candidates = sorted(path for root in (LIB / "_source", LIB / "_hold") for path in root.rglob("*") if path.is_file() and path.name != ".DS_Store")
    for path in source_candidates:
        rel = str(path.relative_to(LIB))
        classification = "review-evidence" if "review-evidence" in rel else "quarantine" if "quarantine" in rel else "production-source"
        source_id = f"{prefix}-S-{hashlib.sha1(rel.encode()).hexdigest()[:10].upper()}"
        source_sha = sha256(path)
        source_id_by_sha.setdefault(source_sha, source_id)
        source_rows.append((source_id, rel, path.suffix.lower().lstrip("."), classification, "See PROVENANCE.md", "Repository-owned or separately documented", "unknown", "2026-09-04", "Not a routine upload source", source_sha))
    with (LIB / "_inventory/SOURCE_MANIFEST.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(("source_asset_id", "source_path", "source_type", "classification", "capture_context", "rights", "contains_personal_data", "reviewed_on", "notes", "sha256"))
        writer.writerows(source_rows)

    managed_roots = [LIB / name for name in ("01-brand", "02-campaigns", "03-platform-ready", "05-store-listings")]
    assets = sorted(path for root in managed_roots for path in root.rglob("*") if path.is_file() and path.suffix.lower() in MEDIA_EXTENSIONS and path.name != ".DS_Store")
    rows = []
    id_by_path: dict[Path, str] = {}
    for path in assets:
        rel = str(path.relative_to(LIB))
        file_sha = sha256(path)
        parent_sha = (str(Path(rel).parent), file_sha)
        asset_id = previous_by_path.get(rel) or previous_by_parent_sha.get(parent_sha) or f"{prefix}-A-{hashlib.sha1(rel.encode()).hexdigest()[:10].upper()}"
        id_by_path[path] = asset_id
        meta = probe(path)
        media_type = "video" if path.suffix.lower() in {".mp4", ".mov", ".m4v"} else "caption" if path.suffix.lower() == ".srt" else "image" if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".svg", ".ico"} else "document"
        placement = path.parent.name
        rows.append({
            "asset_id": asset_id, "path": rel, "media_type": media_type, "purpose": placement,
            "campaign_id": campaign_for(path), "platform": platform_for(path), "width": meta["width"], "height": meta["height"],
            "duration_seconds": meta["duration_seconds"], "format": path.suffix.lower().lstrip("."), "alpha": meta["alpha"],
            "codec": meta["codec"], "pixel_format": meta["pixel_format"], "audio": meta["audio"], "status": status_for(path),
            "source_asset_id": source_id_by_sha.get(file_sha, ""), "version": "01", "reviewed_on": "2026-09-04", "sha256": file_sha,
        })
    fields = ["asset_id", "path", "media_type", "purpose", "campaign_id", "platform", "width", "height", "duration_seconds", "format", "alpha", "codec", "pixel_format", "audio", "status", "source_asset_id", "version", "reviewed_on", "sha256"]
    with (LIB / "_inventory/ASSET_MANIFEST.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    publishing_rows = []
    for platform in PLATFORMS:
        base = LIB / f"03-platform-ready/{platform}"
        platform_assets = sorted(path for path in base.rglob("*") if path.is_file() and path.suffix.lower() in MEDIA_EXTENSIONS)
        lines = [f"# {platform.title()} publishing index", "", "Use only the files listed below. READY_LOCAL still requires the common publishing checklist and a native destination preview when the placement can crop or obscure content.", "", "| Placement | Asset | Status | Copy ID |", "|---|---|---|---|"]
        if not platform_assets:
            lines.append("| — | No asset available; see the gap register | BLOCKED | NONE |")
        for path in platform_assets:
            placement = path.relative_to(base).parts[0]
            status = status_for(path)
            copy_id = copy_id_for(path, platform)
            asset_id = id_by_path[path]
            lines.append(f"| {placement} | `{path.name}` ({asset_id}) | {status} | {copy_id} |")
            publishing_rows.append((platform, placement, asset_id, copy_id, status, "", "yes", "", "Complete 00-control/PUBLISHING_CHECKLIST.md"))
        write(f"03-platform-ready/{platform}/INDEX.md", "\n".join(lines))
    with (LIB / "_inventory/PUBLISHING_INDEX.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(("platform", "placement", "asset_id", "copy_id", "status", "cta_url", "preview_required", "last_previewed_on", "notes"))
        writer.writerows(publishing_rows)
    legacy_inventory_names = {"library-manifest.csv", "library-sha256.txt", "assets.csv", "source-index.csv", "source-sha256.txt", "source-media.csv"}
    checksum_files = sorted(
        path for path in LIB.rglob("*")
        if path.is_file()
        and path.name not in {".DS_Store", "CHECKSUMS.sha256"}
        and not (path.parent == LIB / "_inventory" and path.name in legacy_inventory_names)
    )
    with (LIB / "_inventory/CHECKSUMS.sha256").open("w", encoding="utf-8") as handle:
        for path in checksum_files:
            handle.write(f"{sha256(path)}  {path.relative_to(LIB)}\n")


def write_root_readme() -> None:
    display = PROJECT.replace("-", " ").title()
    write("README.md", f"""# {display} media library

This library implements the Modulo Squares publishing-first media structure.

## Start here

1. Check `00-control/READINESS.md` and `00-control/GAP_REGISTER.md`.
2. Open `03-platform-ready/<platform>/INDEX.md` and select the listed asset and copy ID.
3. Retrieve matching copy from `04-copy/POST_LIBRARY.md` and alt text from `04-copy/ALT_TEXT.csv`.
4. Complete `00-control/PUBLISHING_CHECKLIST.md` immediately before publishing.

## Folder map

| Folder | Purpose |
|---|---|
| `00-control/` | Readiness, gaps, accounts, platform specifications, and publishing checklist |
| `01-brand/` | Canonical brand masters and channel-setup exports |
| `02-campaigns/` | Reusable campaign masters organized by stable campaign ID |
| `03-platform-ready/` | The only routine upload source, organized identically for every project |
| `04-copy/` | Profile copy, post library, calendar, alt text, and video metadata |
| `05-store-listings/` | App Store and Google Play upload media, kept separate from social posts |
| `_source/` | Production inputs and editable files; not routine upload selections |
| `_inventory/` | Standard asset/source manifests, publishing index, provenance, and checksums |
| `_hold/` | Review evidence and quarantined material that must not be published |

The previous project-specific paths remain temporarily for compatibility and checksum comparison. `00-control/LEGACY_LIBRARY_GUIDE.md` preserves the former navigation guide.

## Rebuild and validate

```sh
./scripts/media-library/build-media-library.sh
./scripts/media-library/validate-media-library.sh
```

Local validation does not prove account ownership, public availability, link health, rights clearance, or native platform crop approval.
""")


GAP_README_TEXT = "# No current asset\n\nThis required contract location has no current approved asset. See `00-control/GAP_REGISTER.md` before producing or publishing a replacement.\n"


def add_gap_readmes() -> None:
    for directory in sorted(path for path in LIB.rglob("*") if path.is_dir()):
        if directory == LIB or any(part.startswith(".") for part in directory.relative_to(LIB).parts):
            continue
        placeholder = directory / "README.md"
        # Look at the whole subtree, not just immediate children: a directory
        # like `03-platform-ready/youtube` or `05-store-listings/apple` holds
        # its assets in placement subdirectories and would otherwise be
        # mislabelled as an empty gap.
        has_real_asset = any(
            child.is_file() and child.name != "README.md"
            for child in directory.rglob("*")
        )
        if has_real_asset:
            # A descendant now carries a real asset -- clear any stale gap note
            # this function previously wrote here.
            if placeholder.is_file() and placeholder.read_text(encoding="utf-8") == GAP_README_TEXT:
                placeholder.unlink()
            continue
        if directory.name in {"square", "portrait", "landscape", "vertical", "captions"} and "02-campaigns" in directory.parts:
            continue
        placeholder.write_text(GAP_README_TEXT, encoding="utf-8")


def main() -> int:
    if PROJECT not in PROJECT_PREFIX:
        raise SystemExit(f"Unsupported repository: {PROJECT}")
    common_skeleton()
    preserve_legacy_guide()
    migrate_modulo()
    add_gap_readmes()
    write_root_readme()
    for residue in LIB.rglob(".DS_Store"):
        residue.unlink()
    make_indexes_and_manifests()
    for residue in LIB.rglob(".DS_Store"):
        residue.unlink()
    print(f"Unified media library synchronized for {PROJECT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
