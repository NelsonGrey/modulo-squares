#!/usr/bin/env python3
"""Compose native iOS footage with approved AI narration into review pilots."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import textwrap

ROOT = Path(__file__).resolve().parents[2]
FONT = '/System/Library/Fonts/Supplemental/Arial.ttf'
BOLD = '/System/Library/Fonts/Supplemental/Arial Bold.ttf'


def run(args):
    subprocess.run([str(arg) for arg in args], check=True)


def duration(path):
    return float(subprocess.check_output(
        ['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
         '-of', 'csv=p=0', str(path)], text=True))


def timestamp(seconds):
    milliseconds = round(seconds * 1000)
    return f'{milliseconds // 3600000:02}:{milliseconds // 60000 % 60:02}:{milliseconds // 1000 % 60:02},{milliseconds % 1000:03}'


def card(path, title, subtitle, accent, vertical):
    width, height = (1080, 1920) if vertical else (1920, 1080)
    args = ['magick', '-size', f'{width}x{height}', 'xc:#0B1425',
            '-fill', accent, '-draw', f'rectangle 0,0 {width},12',
            '-font', BOLD, '-fill', '#FFFFFF']
    if vertical:
        args += ['-gravity', 'North', '-pointsize', '43', '-annotate', '+0+36', title,
                 '-font', FONT, '-pointsize', '25', '-fill', '#B9C9DF',
                 '-annotate', '+0+96', subtitle,
                 '-gravity', 'South', '-pointsize', '23', '-annotate', '+0+36',
                 'Modulo Squares  •  AI-generated narration']
    else:
        args += ['-gravity', 'NorthWest', '-pointsize', '28', '-fill', '#B9C9DF',
                 '-annotate', '+100+145', 'MODULO SQUARES  /  APPEARANCE',
                 '-fill', '#FFFFFF', '-pointsize', '84',
                 '-annotate', '+100+240', textwrap.fill(title, 22),
                 '-font', FONT, '-pointsize', '38', '-fill', '#B9C9DF',
                 '-annotate', '+100+490', textwrap.fill(subtitle, 38),
                 '-pointsize', '22', '-annotate', '+100+980', 'AI-generated narration']
    run(args + [path])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('sources', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--tour-start', type=float, required=True,
                        help='Visually verified start of Settings sequence in raw tour')
    args = parser.parse_args()
    if args.output.exists() and any(args.output.iterdir()):
        raise SystemExit('Choose an empty output directory; existing pilots are preserved.')
    args.output.mkdir(parents=True, exist_ok=True)
    work = args.output / 'edit-sources'
    work.mkdir()
    script = json.loads((ROOT / 'scripts/store-promo/appearance-pilot.json').read_text())
    shots = [
        ('palette-tour.mov', args.tour_start, 'Make it your own', 'Settings → Appearance → Save', '#6CD4F5'),
        ('deepOcean.mov', 0, 'Deep Ocean', 'Cool color. Clear focus.', '#6CD4F5'),
        ('arcadeNeon.mov', 0, 'Arcade Neon', 'Bring on the bright colors.', '#B388FF'),
        ('warmSunset.mov', 0, 'Warm Sunset', 'A warmer way to play.', '#FFB36A'),
        ('candyPop.mov', 0, 'Candy Pop', 'Add a playful burst of color.', '#FF85BB'),
        ('deepOcean.mov', 8, 'Find your next clean landing', 'Same challenge. Your favorite look.', '#6CD4F5'),
    ]
    total = 0
    captions = []
    segments = []
    for segment, shot in zip(script['segments'], shots):
        audio = args.sources / 'narration' / (segment['id'] + '.wav')
        audio_seconds = duration(audio)
        seconds = round((audio_seconds + 1.0) * 30) / 30
        source = args.sources / 'captures' / shot[0]
        if duration(source) < shot[1] + seconds:
            raise SystemExit(f'Insufficient moving footage for {segment["id"]}')
        words = segment['text'].split()
        chunks = [words[i:i + 10] for i in range(0, len(words), 10)]
        cursor = total + 0.25
        for chunk in chunks:
            end = cursor + audio_seconds * len(chunk) / len(words)
            captions.append(f'{len(captions)+1}\n{timestamp(cursor)} --> {timestamp(end)}\n' + ' '.join(chunk) + '\n')
            cursor = end
        segments.append(dict(segment, source=shot[0], source_start=shot[1],
                             start=total, duration=seconds))
        for vertical in (False, True):
            layout = 'vertical' if vertical else 'landscape'
            background = work / f'{segment["id"]}-{layout}.png'
            output = work / f'{segment["id"]}-{layout}.mp4'
            card(background, shot[2], shot[3], shot[4], vertical)
            h, x, y = (1668, '(W-w)/2', 154) if vertical else (980, 1310, 50)
            filters = (f'[1:v]fps=30,scale=-2:{h}:flags=lanczos,setsar=1[phone];'
                       f'[0:v][phone]overlay=x={x}:y={y}:shortest=1,format=yuv420p[v];'
                       '[2:a]adelay=250:all=1,apad,aresample=48000[a]')
            run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-n',
                 '-loop', '1', '-framerate', '30', '-i', background,
                 '-ss', shot[1], '-i', source, '-i', audio,
                 '-filter_complex', filters, '-map', '[v]', '-map', '[a]',
                 '-t', seconds, '-c:v', 'libx264', '-preset', 'fast', '-crf', '18',
                 '-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-ac', '2',
                 '-movflags', '+faststart', output])
        total += seconds
    for layout in ('landscape', 'vertical'):
        concat = work / f'{layout}.txt'
        concat.write_text(''.join(f"file '{s['id']}-{layout}.mp4'\n" for s in script['segments']))
        run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-n', '-f', 'concat',
             '-safe', '0', '-i', concat, '-c:v', 'copy', '-af', 'loudnorm=I=-16:TP=-1.5:LRA=11',
             '-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-movflags', '+faststart',
             args.output / f'appearance-pilot-{layout}.mp4'])
    (args.output / 'appearance-pilot.en.srt').write_text('\n'.join(captions))
    (args.output / 'edit-decision-list.json').write_text(json.dumps(segments, indent=2) + '\n')
    provenance = dict(ai_generated_narration=True, model=script['model'], voice=script['voice'],
                      disclosure=script['disclosure'],
                      status='Pilot for owner voice and pacing review; not yet published',
                      footage='Native iOS Simulator recording of production widgets in local capture build',
                      files={p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                             for p in args.output.glob('*') if p.is_file()})
    (args.output / 'PROVENANCE.json').write_text(json.dumps(provenance, indent=2) + '\n')
    print(f'Rendered {total:.2f}s pilot in landscape and vertical layouts.')


if __name__ == '__main__':
    main()
