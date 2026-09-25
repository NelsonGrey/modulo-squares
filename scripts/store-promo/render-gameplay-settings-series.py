#!/usr/bin/env python3
"""Render narrated iOS gameplay/settings review videos in two social layouts."""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import textwrap

ROOT = Path(__file__).resolve().parents[2]
FONT = "/System/Library/Fonts/Supplemental/Arial.ttf"
BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def run(args):
    subprocess.run([str(arg) for arg in args], check=True)


def duration(path):
    return float(
        subprocess.check_output(
            [
                "ffprobe",
                "-v",
                "error",
                "-show_entries",
                "format=duration",
                "-of",
                "csv=p=0",
                str(path),
            ],
            text=True,
        )
    )


def timestamp(seconds):
    milliseconds = round(seconds * 1000)
    return (
        f"{milliseconds // 3600000:02}:"
        f"{milliseconds // 60000 % 60:02}:"
        f"{milliseconds // 1000 % 60:02},{milliseconds % 1000:03}"
    )


def card(path, title, subtitle, accent, vertical):
    width, height = (1080, 1920) if vertical else (1920, 1080)
    args = [
        "magick",
        "-size",
        f"{width}x{height}",
        "xc:#0B1425",
        "-fill",
        accent,
        "-draw",
        f"rectangle 0,0 {width},12",
        "-font",
        BOLD,
        "-fill",
        "#FFFFFF",
    ]
    if vertical:
        args += [
            "-gravity",
            "North",
            "-pointsize",
            "43",
            "-annotate",
            "+0+36",
            title,
            "-font",
            FONT,
            "-pointsize",
            "25",
            "-fill",
            "#B9C9DF",
            "-annotate",
            "+0+96",
            subtitle,
            "-gravity",
            "South",
            "-pointsize",
            "23",
            "-annotate",
            "+0+36",
            "Modulo Squares  •  AI-generated narration",
        ]
    else:
        args += [
            "-gravity",
            "NorthWest",
            "-pointsize",
            "28",
            "-fill",
            "#B9C9DF",
            "-annotate",
            "+100+145",
            "MODULO SQUARES  /  GAMEPLAY GUIDE",
            "-fill",
            "#FFFFFF",
            "-pointsize",
            "72",
            "-annotate",
            "+100+240",
            textwrap.fill(title, 24),
            "-font",
            FONT,
            "-pointsize",
            "34",
            "-fill",
            "#B9C9DF",
            "-annotate",
            "+100+500",
            textwrap.fill(subtitle, 38),
            "-pointsize",
            "22",
            "-annotate",
            "+100+980",
            "AI-generated narration",
        ]
    run(args + [path])


def write_captions(path, text, audio_seconds):
    words = text.split()
    chunks = [words[index : index + 10] for index in range(0, len(words), 10)]
    cursor = 0.25
    lines = []
    for index, chunk in enumerate(chunks, start=1):
        end = cursor + audio_seconds * len(chunk) / len(words)
        lines.append(
            f"{index}\n{timestamp(cursor)} --> {timestamp(end)}\n"
            + " ".join(chunk)
            + "\n"
        )
        cursor = end
    path.write_text("\n".join(lines))


def chip_callouts(vertical):
    """Return timed chip highlights aligned to the approved narration."""
    timings = [
        ("COMBO", 5.00, 5.70, 0, 0),
        ("DIFFICULTY", 5.70, 6.55, 1, 0),
        ("FALL SPEED", 6.55, 7.45, 2, 0),
        ("MOVE SPEED", 7.45, 8.20, 0, 1),
        ("NUMBER RANGE", 8.20, 9.15, 1, 1),
        ("DEFICIT", 9.15, 10.60, 2, 1),
    ]
    if vertical:
        columns = [184, 426, 667]
        rows = [571, 651]
        width, height = 229, 65
    else:
        columns = [1326, 1468, 1610]
        rows = [295, 342]
        width, height = 135, 39

    filters = []
    for label, start, end, column, row in timings:
        enabled = f"between(t,{start:.2f},{end:.2f})"
        x, y = columns[column], rows[row]
        filters.append(
            f"drawbox=x={x}:y={y}:w={width}:h={height}:"
            f"color=#FFD23D@0.30:t=fill:enable='{enabled}'"
        )
        filters.append(
            f"drawbox=x={x}:y={y}:w={width}:h={height}:"
            f"color=#FFD23D:t=6:enable='{enabled}'"
        )
        if vertical:
            pointer_x, pointer_y = x + width // 2 - 3, y + height
            pointer_width, pointer_height = 6, 28
        else:
            pointer_x, pointer_y = x - 30, y + height // 2 - 3
            pointer_width, pointer_height = 30, 6
        filters.append(
            f"drawbox=x={pointer_x}:y={pointer_y}:w={pointer_width}:"
            f"h={pointer_height}:color=#FFD23D:t=fill:enable='{enabled}'"
        )
    return "," + ",".join(filters)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("sources", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.output.exists() and any(args.output.iterdir()):
        raise SystemExit("Choose an empty output directory; existing videos are preserved.")
    args.output.mkdir(parents=True, exist_ok=True)
    script = json.loads(
        (ROOT / "scripts/store-promo/gameplay-settings-series.json").read_text()
    )

    rendered = []
    for episode in script["segments"]:
        episode_dir = args.output / episode["id"]
        episode_dir.mkdir()
        audio = args.sources / "narration" / f"{episode['id']}.wav"
        source = args.sources / "captures" / episode["source"]
        audio_seconds = duration(audio)
        seconds = round((audio_seconds + 1.0) * 30) / 30
        if duration(source) < episode["source_start"] + seconds:
            raise SystemExit(f"Insufficient footage for {episode['id']}")

        write_captions(
            episode_dir / f"{episode['id']}.en.srt", episode["text"], audio_seconds
        )
        for vertical in (False, True):
            layout = "vertical" if vertical else "landscape"
            background = episode_dir / f"{episode['id']}-{layout}-thumbnail.png"
            output = episode_dir / f"{episode['id']}-{layout}.mp4"
            card(
                background,
                episode["title"],
                episode["subtitle"],
                episode["accent"],
                vertical,
            )
            height, x, y = (1668, "(W-w)/2", 154) if vertical else (980, 1310, 50)
            callouts = chip_callouts(vertical) if episode["id"] == "01-read-the-game" else ""
            filters = (
                f"[1:v]fps=30,scale=-2:{height}:flags=lanczos,setsar=1[phone];"
                f"[0:v][phone]overlay=x={x}:y={y}:shortest=1,format=yuv420p"
                f"{callouts}[v];"
                "[2:a]adelay=250:all=1,loudnorm=I=-16:TP=-1.5:LRA=11,"
                "apad,aresample=48000[a]"
            )
            run(
                [
                    "ffmpeg",
                    "-hide_banner",
                    "-loglevel",
                    "error",
                    "-n",
                    "-loop",
                    "1",
                    "-framerate",
                    "30",
                    "-i",
                    background,
                    "-ss",
                    episode["source_start"],
                    "-i",
                    source,
                    "-i",
                    audio,
                    "-filter_complex",
                    filters,
                    "-map",
                    "[v]",
                    "-map",
                    "[a]",
                    "-t",
                    seconds,
                    "-c:v",
                    "libx264",
                    "-preset",
                    "fast",
                    "-crf",
                    "18",
                    "-c:a",
                    "aac",
                    "-b:a",
                    "192k",
                    "-ar",
                    "48000",
                    "-ac",
                    "2",
                    "-movflags",
                    "+faststart",
                    "-disposition:a:0",
                    "default",
                    "-metadata:s:a:0",
                    "language=eng",
                    output,
                ]
            )
        rendered.append(
            {
                "id": episode["id"],
                "title": episode["title"],
                "duration": seconds,
                "source": episode["source"],
                "source_start": episode["source_start"],
            }
        )

    provenance = {
        "ai_generated_narration": True,
        "model": script["model"],
        "voice": script["voice"],
        "disclosure": script["disclosure"],
        "speech_alignment": "OpenAI Whisper word timestamps for episode 01",
        "callout_treatment": "Timed yellow pulse and pointer synchronized to each narrated HUD chip name",
        "status": "Review videos; not published",
        "footage": "Native iOS Simulator recording of production widgets in a local capture build",
        "episodes": rendered,
        "files": {
            str(path.relative_to(args.output)): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in args.output.rglob("*")
            if path.is_file()
        },
    }
    (args.output / "PROVENANCE.json").write_text(json.dumps(provenance, indent=2) + "\n")
    print(f"Rendered {len(rendered)} episodes in landscape and vertical layouts.")


if __name__ == "__main__":
    main()
