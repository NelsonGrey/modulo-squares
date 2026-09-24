#!/usr/bin/env python3
"""Export reviewed native screenshots without resizing or replacing old sets."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ACCEPTED = {(1260, 2736), (1290, 2796), (1320, 2868)}
NAMES = [
    ('deepOcean.png', '01-deep-ocean.png', 'Deep Ocean'),
    ('arcadeNeon.png', '02-arcade-neon.png', 'Arcade Neon'),
    ('warmSunset.png', '03-warm-sunset.png', 'Warm Sunset'),
    ('candyPop.png', '04-candy-pop.png', 'Candy Pop'),
    ('appearance-settings.png', '05-choose-your-appearance.png', 'Choose your appearance'),
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.output.exists() and any(args.output.iterdir()):
        raise SystemExit('Choose an empty output directory.')
    for name, _, _ in NAMES:
        source = args.source / name
        dimensions = subprocess.check_output(
            ['magick', 'identify', '-format', '%w %h', str(source)], text=True)
        if tuple(map(int, dimensions.split())) not in ACCEPTED:
            raise SystemExit(f'Unsupported native dimensions: {name}: {dimensions}')
    args.output.mkdir(parents=True, exist_ok=True)
    rows = []
    for name, export_name, title in NAMES:
        source, output = args.source / name, args.output / export_name
        subprocess.run(['magick', str(source), '-background', 'black',
                        '-alpha', 'remove', '-alpha', 'off', '-colorspace', 'sRGB',
                        '-define', 'png:color-type=2', str(output)], check=True)
        rows.append(dict(file=export_name, title=title,
                         source=str(source.resolve()),
                         source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                         sha256=hashlib.sha256(output.read_bytes()).hexdigest()))
    (args.output / 'CAPTURE_PROVENANCE.json').write_text(json.dumps(dict(
        source_commit=subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
        context='Native iOS Simulator; local deterministic capture target using production gameplay widgets',
        transforms='Remove alpha and encode sRGB PNG; no resizing or UI retouching',
        files=rows), indent=2) + '\n')
    print(f'Exported {len(rows)} opaque native screenshots.')


if __name__ == '__main__':
    main()
