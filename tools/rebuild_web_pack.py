#!/usr/bin/env python3
"""Rebuild resources against the committed official Godot 4.6.3 web runtime.
No export templates needed for a resource-only export; no JS/WASM engine changes.
"""
import json,re,shutil,subprocess
from pathlib import Path
root=Path(__file__).resolve().parent.parent
version=subprocess.check_output(['godot','--version'],text=True).strip()
assert version.startswith('4.6.3.'),f'Use Godot 4.6.3, got {version}'
def run_godot(args):
    result=subprocess.run(['godot',*args],capture_output=True,text=True)
    output=result.stdout+result.stderr
    print(output)
    assert result.returncode==0 and 'SCRIPT ERROR:' not in output and 'Parse Error:' not in output,'Godot import/export failed'
run_godot(['--headless','--editor','--path',str(root),'--import','--quit'])
run_godot(['--headless','--path',str(root),'--export-pack','Web',str(root/'web/game.pck')])
p=root/'web/game.html';html=p.read_text();m=re.search(r'const GODOT_CONFIG = (.*?);',html)
config=json.loads(m[1]);config['fileSizes']['game.pck']=(root/'web/game.pck').stat().st_size
p.write_text(html[:m.start(1)]+json.dumps(config,separators=(',',':'))+html[m.end(1):])
shutil.copyfile(root/'web/game.pck',root/'dist/brico-empire.pck')
subprocess.run(['python3',str(root/'tools/check_web_export.py')],check=True)
