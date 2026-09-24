#!/usr/bin/env python3
"""Generate approved narration; credentials are read in memory, never printed."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import urllib.error
import urllib.request

import requests


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('script', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--keychain-service', help='Use only after owner authorization')
    args = parser.parse_args()
    key = os.environ.get('OPENAI_API_KEY', '')
    if args.keychain_service:
        result = subprocess.run(
            ['security', 'find-generic-password', '-s', args.keychain_service, '-w'],
            capture_output=True, text=True, check=False)
        if result.returncode == 0:
            key = result.stdout.strip()
    if not key.startswith('sk-'):
        raise SystemExit('No credential available; no request made.')
    script = json.loads(args.script.read_text())
    args.output.mkdir(parents=True, exist_ok=True)
    for segment in script['segments']:
        output = args.output / (segment['id'] + '.wav')
        if output.exists():
            raise SystemExit(f'Refusing to replace existing audio: {output.name}')
        payload = {k: script[k] for k in ('model', 'voice', 'instructions')}
        payload.update(input=segment['text'], response_format='wav')
        request = urllib.request.Request(
            'https://api.openai.com/v1/audio/speech',
            data=json.dumps(payload).encode(),
            headers={'Authorization': 'Bearer ' + key, 'Content-Type': 'application/json'})
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                data = response.read()
                request_id = response.headers.get('x-request-id')
        except urllib.error.HTTPError as error:
            try:
                code = json.loads(error.read()).get('error', {}).get('code', 'unknown')
            except (ValueError, AttributeError):
                code = 'unknown'
            raise SystemExit(f'Speech request failed: HTTP {error.code}, code={code}')
        except urllib.error.URLError:
            # Some macOS Python installs do not inherit the same current CA
            # bundle as curl. Requests carries its own certifi bundle, so use
            # it as a credential-safe fallback without placing the key in a
            # command line or writing it to disk.
            try:
                response = requests.post(
                    'https://api.openai.com/v1/audio/speech',
                    json=payload,
                    headers={'Authorization': 'Bearer ' + key},
                    timeout=120,
                )
                response.raise_for_status()
                data = response.content
                request_id = response.headers.get('x-request-id')
            except requests.RequestException as error:
                status = getattr(error.response, 'status_code', 'network')
                raise SystemExit(
                    f'Speech request failed: HTTP {status}; credential not logged.'
                ) from None
        if data[:4] != b'RIFF':
            raise SystemExit('Unexpected audio format; output not saved.')
        output.write_bytes(data)
        provenance = dict(payload, ai_generated=True,
                          disclosure=script['disclosure'], request_id=request_id,
                          generated_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                          sha256=hashlib.sha256(data).hexdigest())
        output.with_suffix('.json').write_text(json.dumps(provenance, indent=2) + '\n')
        print(f'Generated {output.name}', flush=True)


if __name__ == '__main__':
    main()
