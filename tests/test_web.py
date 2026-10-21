"""Exercise the real Godot web export, including sales, UI and browser persistence.
Requires Playwright/Chromium, Pillow, Tesseract and tools/serve_web.py.
"""
import io
import json
import os
import re
import subprocess
import time
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright

root = Path(__file__).resolve().parent.parent

def ocr(name, money_only=False):
    image = Image.open(root/'docs'/name)
    if money_only:
        scale = image.width/540
        image = image.crop(tuple(round(x*scale) for x in (20,58,265,119)))
    image = image.resize((image.width*2,image.height*2))
    data = io.BytesIO(); image.save(data,format='PNG')
    args = ['tesseract','stdin','stdout'] + (['--psm','7'] if money_only else [])
    return subprocess.check_output(args,input=data.getvalue(),stderr=subprocess.DEVNULL).decode()

def money(name):
    text = ocr(name, money_only=True)
    match = re.search(r'([0-9][0-9 ]*)\s*pi[eéè]ces',text)
    assert match, f'Cannot read the money field: {text}'
    return int(match.group(1).replace(' ',''))

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True,args=['--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-gpu-sandbox'])
    width = int(os.environ.get('BRICO_TEST_WIDTH','540'))
    height = round(width*16/9)
    page = browser.new_page(viewport={'width':width,'height':height},has_touch=True)
    errors, console_errors, logs = [], [], []
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.on('console',lambda m:(logs.append(m.text),console_errors.append(m.text) if m.type=='error' else None))
    page.goto(os.environ.get('BRICO_TEST_URL','http://127.0.0.1:8000/'),wait_until='networkidle',timeout=60000)
    frame = page.frame_locator('#game')
    frame.locator('#canvas').wait_for(state='visible')
    page.wait_for_function("getComputedStyle(document.getElementById('notice')).display === 'none'")
    frame.locator('#status').wait_for(state='detached',timeout=60000)
    page.wait_for_timeout(6000)
    page.screenshot(path=str(root/'docs/06-web-demarrage.png'))
    initial = money('06-web-demarrage.png')
    started = time.monotonic()
    while True:
        page.wait_for_timeout(5000)
        page.screenshot(path=str(root/'docs/07-web-ventes.png'))
        after_sales = money('07-web-ventes.png')
        if after_sales > initial: break
        assert time.monotonic()-started < 120,'No automatic sale within the browser test timeout'
    sale_wait_seconds = round(time.monotonic()-started,1)
    # Pointer positions scale with the portrait game canvas.
    page.mouse.click(97*width/540,898*height/960)
    page.wait_for_timeout(600)
    page.screenshot(path=str(root/'docs/08-web-equipe.png'))
    assert 'Recruter' in ocr('08-web-equipe.png'),'The team menu must actually open'
    indexed = page.frames[1].evaluate("async () => indexedDB.databases ? await indexedDB.databases() : []")
    page.reload(wait_until='networkidle')
    page.frame_locator('#game').locator('#status').wait_for(state='detached',timeout=60000)
    page.wait_for_timeout(6000)
    page.screenshot(path=str(root/'docs/09-web-recharge.png'))
    after_reload = money('09-web-recharge.png')
    assert after_reload >= after_sales,'Reload must preserve collected money'
    assert not errors,errors
    assert not console_errors,console_errors
    assert any('Godot Engine' in item for item in logs),'Godot must actually start'
    assert any('userfs' in str(item) for item in indexed),'Persistent storage database must exist'
    result={'displayed_money':[initial,after_sales,after_reload],'sale_wait_seconds':sale_wait_seconds,
            'browser':browser.version,'viewport':[width,height],'errors':errors,'console_errors':console_errors,
            'console':logs,'indexed_databases':indexed}
    (root/'docs/web-results.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
    print(json.dumps(result,ensure_ascii=False,indent=2))
    browser.close()
