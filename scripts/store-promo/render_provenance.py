#!/usr/bin/env python3
"""Content-hash provenance ledger for the store-promo renderers.

`render-assets.sh` and `render-videos.sh` call this script's CLI to record
which source-file hashes produced each published deliverable. `validate-
assets.py` imports `stale_sources()` to detect deliverables that are stale
relative to those recorded hashes -- e.g. `render.html`, a native capture, or
a video plate changed without rerunning the renderer that consumes it.

A source is identified as `kit:<promo-kit-relative-path>` (native captures,
video plates, or other files inside the promotion kit) or
`repo:<repository-relative-path>` (shared inputs such as `render.html` that
live outside the kit). Comparing content hashes rather than file
modification times avoids false positives from `git checkout` -- which does
not preserve original commit timestamps and can leave a freshly checked-out
source with a newer mtime than an equally freshly checked-out output that
was in fact rendered from it.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LEDGER_FILENAME = "render-provenance.json"


def hash_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def resolve_source(kit_root: Path, source: str) -> Path:
    scope, separator, relative = source.partition(":")
    if not separator:
        raise ValueError(
            f"Source must be prefixed with 'kit:' or 'repo:': {source!r}"
        )
    if scope == "repo":
        return REPO_ROOT / relative
    if scope == "kit":
        return kit_root / relative
    raise ValueError(f"Unknown source scope {scope!r} in {source!r}")


def ledger_path(kit_root: Path) -> Path:
    return kit_root / LEDGER_FILENAME


def load_ledger(kit_root: Path) -> dict[str, dict[str, str]]:
    path = ledger_path(kit_root)
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def save_ledger(kit_root: Path, ledger: dict[str, dict[str, str]]) -> None:
    path = ledger_path(kit_root)
    path.write_text(
        json.dumps(ledger, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def record(kit_root: Path, output: str, sources: list[str]) -> None:
    """Hash `sources` now and store them as the recipe for `output`."""
    ledger = load_ledger(kit_root)
    ledger[output] = {
        source: hash_file(resolve_source(kit_root, source)) for source in sources
    }
    save_ledger(kit_root, ledger)


def stale_sources(
    kit_root: Path, output: str, sources: tuple[str, ...]
) -> list[str]:
    """Return the subset of `sources` whose current content hash no longer
    matches the hash recorded the last time `output` was rendered -- this
    also covers a `source` that was never recorded (e.g. a rule that has
    never been rendered through this pipeline). A source that is currently
    missing on disk is skipped here; callers already surface missing files
    via their own existence checks.
    """
    if not sources:
        return []
    recorded = load_ledger(kit_root).get(output, {})
    stale: list[str] = []
    for source in sources:
        source_path = resolve_source(kit_root, source)
        if not source_path.is_file():
            continue
        if recorded.get(source) != hash_file(source_path):
            stale.append(source)
    return stale


def _main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kit-root", type=Path, required=True)
    parser.add_argument(
        "--output",
        required=True,
        help="Promo-kit-relative path of the rendered deliverable.",
    )
    parser.add_argument(
        "--source",
        action="append",
        required=True,
        dest="sources",
        help="kit:<relative-path> or repo:<relative-path>; may repeat.",
    )
    args = parser.parse_args()
    record(args.kit_root.resolve(), args.output, args.sources)
    print(f"Recorded provenance for {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(_main())
