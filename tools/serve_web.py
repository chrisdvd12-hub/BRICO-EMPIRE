#!/usr/bin/env python3
"""Serve the committed Godot export. No pip dependencies; never a production server."""
import argparse
import functools
import http.server
from pathlib import Path

class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      '.wasm': 'application/wasm', '.pck': 'application/octet-stream'}
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        super().end_headers()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Lancer Brico Empire dans un navigateur.')
    parser.add_argument('--bind', default='127.0.0.1', help='Adresse d’écoute, localhost par défaut')
    parser.add_argument('--port', type=int, default=8000)
    args = parser.parse_args()
    directory = Path(__file__).resolve().parent.parent / 'web'
    if not (directory / 'game.wasm.gz').exists():
        parser.error('Export absent : lancer Godot --export-release Web web/game.html')
    server = http.server.ThreadingHTTPServer((args.bind, args.port), functools.partial(Handler, directory=str(directory)))
    print(f'Brico Empire : http://{args.bind}:{args.port} — Ctrl+C pour arrêter', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.server_close()
