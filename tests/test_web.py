"""Browser smoke test; needs Playwright + Chromium, with tools/serve_web.py running."""
import json
import subprocess
import re
from pathlib import Path
from playwright.sync_api import sync_playwright

root = Path(__file__).resolve().parent.parent
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True, args=['--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-gpu-sandbox'])
    page = browser.new_page(viewport={'width':540,'height':960}, has_touch=True)
    errors = []
    logs = []
    page.on('pageerror', lambda e: errors.append(str(e)))
    page.on('console', lambda m: logs.append(m.text))
    page.goto('http://127.0.0.1:8000/', wait_until='networkidle', timeout=60000)
    frame = page.frame_locator('#game')
    frame.locator('#canvas').wait_for(state='visible')
    page.wait_for_function("getComputedStyle(document.getElementById('notice')).display === 'none'")
    frame.locator('#status').wait_for(state='detached', timeout=60000)
    page.wait_for_timeout(6000)
    page.screenshot(path=str(root/'docs/06-web-demarrage.png'))
    # Real browser rendering continues while automatic customers buy.
    page.wait_for_timeout(30000)
    page.screenshot(path=str(root/'docs/07-web-ventes.png'))
    # Open a real menu using pointer events routed into the Godot canvas.
    page.mouse.click(97,898)
    page.wait_for_timeout(600)
    page.screenshot(path=str(root/'docs/08-web-equipe.png'))
    frame_object = page.frames[1]
    indexed = frame_object.evaluate("""async () => {
      if(!indexedDB.databases) return [];
      return await indexedDB.databases();
    }""")
    page.reload(wait_until='networkidle')
    page.wait_for_timeout(6000)
    page.screenshot(path=str(root/'docs/09-web-recharge.png'))
    initial_text = subprocess.check_output(['tesseract',str(root/'docs/06-web-demarrage.png'),'stdout'],stderr=subprocess.DEVNULL,text=True)
    sales_text = subprocess.check_output(['tesseract',str(root/'docs/07-web-ventes.png'),'stdout'],stderr=subprocess.DEVNULL,text=True)
    team_text = subprocess.check_output(['tesseract',str(root/'docs/08-web-equipe.png'),'stdout'],stderr=subprocess.DEVNULL,text=True)
    reload_text = subprocess.check_output(['tesseract',str(root/'docs/09-web-recharge.png'),'stdout'],stderr=subprocess.DEVNULL,text=True)
    assert 'BRICOEMPIRE' in re.sub(r'\s+','',sales_text), sales_text
    assert 'Recruter' in team_text, team_text
    def money(text):
        match = re.search(r'([0-9][0-9 ]*) pi[eéè]ces',text)
        assert match, text
        return int(match.group(1).replace(' ',''))
    assert money(sales_text) > money(initial_text), 'Automatic sales must increase actual displayed money'
    assert money(reload_text) >= money(sales_text), 'Reload must preserve collected money'
    print(json.dumps({'displayed_money':[money(initial_text),money(sales_text),money(reload_text)],'browser':browser.version,'errors':errors,'console':logs,'indexed_databases':indexed},ensure_ascii=False,indent=2))
    assert not errors, errors
    assert any('Godot Engine' in item for item in logs), 'Godot must actually start'
    assert any('Brico Empire' in item or 'userfs' in item for item in map(str,indexed)), 'persistent storage database must exist'
    browser.close()
