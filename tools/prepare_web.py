#!/usr/bin/env python3
"""Compress the official engine and add a streaming loader after each Godot export."""
import gzip
from pathlib import Path
root = Path(__file__).resolve().parent.parent
web = root / 'web'
wasm = web / 'game.wasm'
if not wasm.exists():
    raise SystemExit('Export Godot absent : exporter Web vers web/game.html d’abord.')
(web / 'game.wasm.gz').write_bytes(gzip.compress(wasm.read_bytes(), compresslevel=9, mtime=0))
loader = '''<script>
// Official Godot WASM, gzip transport, decompressed once by the browser.
// This avoids large static-host asset limits without requiring special server headers.
(() => {
  const originalFetch = window.fetch.bind(window);
  window.fetch = async function(input, options) {
    const url = new URL(input instanceof Request ? input.url : String(input), location.href);
    if (!url.pathname.endsWith('/game.wasm')) return originalFetch(input, options);
    if (!('DecompressionStream' in window)) throw new Error('Navigateur trop ancien : utiliser Safari 16.4+ ou Chrome récent.');
    url.pathname += '.gz';
    const compressed = await originalFetch(url, options);
    if (!compressed.ok) throw new Error('Chargement du moteur impossible : HTTP ' + compressed.status);
    return new Response(compressed.body.pipeThrough(new DecompressionStream('gzip')), {
      status: 200, headers: {'Content-Type': 'application/wasm'}
    });
  };
})();
</script>
'''
html = web / 'game.html'
text = html.read_text()
text = text.replace('<html lang="en">','<html lang="fr">')
text = text.replace('\tdisplay: block;\n', '\tdisplay: block; touch-action: none; -webkit-user-select: none; user-select: none;\n')
if '// Official Godot WASM' not in text:
    text = text.replace('<script src="game.js"></script>', loader + '<script src="game.js"></script>')
html.write_text(text)
print('Runtime compressé :', (web / 'game.wasm.gz').stat().st_size, 'octets')
