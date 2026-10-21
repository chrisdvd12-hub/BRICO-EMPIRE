#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
"${GODOT_BIN:-godot}" --headless --editor --path . --import --quit
"${GODOT_BIN:-godot}" --headless --path . --export-release Web web/game.html
python3 tools/prepare_web.py
