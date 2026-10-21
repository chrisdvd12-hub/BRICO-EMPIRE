#!/usr/bin/env python3
"""Verify the prebuilt Godot export that static hosts will actually serve."""
import gzip
import hashlib
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
web = root / 'web'
html = (web / 'game.html').read_text()
config = json.loads(re.search(r'const GODOT_CONFIG = (.*?);', html).group(1))
for name in ['index.html', 'game.html', 'game.js', 'game.pck', 'game.wasm.gz',
             'game.audio.worklet.js', 'game.audio.position.worklet.js',
             'GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt']:
    assert (web / name).is_file(), f'Missing export asset: {name}'
pack = (web / 'game.pck').read_bytes()
assert pack[:4] == b'GDPC', 'Invalid Godot pack signature'
assert len(pack) == config['fileSizes']['game.pck'], 'HTML and pack are from different exports'
engine = gzip.decompress((web / 'game.wasm.gz').read_bytes())
assert engine[:8] == b'\x00asm\x01\x00\x00\x00', 'Invalid WebAssembly engine'
assert len(engine) == config['fileSizes']['game.wasm'], 'Incorrect engine size'
assert 'const GODOT_THREADS_ENABLED = false;' in html, 'Use the single-thread export'
assert 'DecompressionStream' in html, 'Compressed runtime loader is missing'
settings = json.loads((root / 'vercel.json').read_text())
assert settings['outputDirectory'] == 'web' and not settings.get('buildCommand')
assert not settings.get('rewrites'), 'Do not replace engine assets with the HTML page'
for rule in settings.get('headers', []):
    for header in rule['headers']:
        assert header['key'].lower() != 'content-encoding', 'Runtime is decompressed by its loader'
print(json.dumps({'pack_bytes':len(pack),'pack_sha256':hashlib.sha256(pack).hexdigest(),
                  'engine_bytes':len(engine),'compressed_engine_bytes':(web/'game.wasm.gz').stat().st_size,
                  'vercel_output':'web','result':'PASS'},indent=2))
