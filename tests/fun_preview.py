"""Real Godot WebGL art review, with an isolated progressed test save.
Never accesses a real player's browser profile. Requires Playwright/Pillow/Tesseract.
"""
from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image,ImageStat
from cartoon_web import money,ocr_shot
import json,subprocess
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'docs/brico-fun';OUT.mkdir(parents=True,exist_ok=True)
(OUT/'visual-results.json').unlink(missing_ok=True)
fixture=json.loads((ROOT/'tests/fixtures/brico_fun_visual.json').read_text())
index={'version':1,'active_id':'p_studio','profiles':[{'id':'p_studio','name':'Studio','avatar':0}]}
seed="(()=>{const d=%s;d.last_saved=Math.floor(Date.now()/1000);localStorage.setItem('brico.index.v1:user://players/index.json',JSON.stringify(%s));localStorage.setItem('brico.save.v2:user://players/p_studio.json',JSON.stringify(d))})()"%(json.dumps(fixture),json.dumps(index))
server=subprocess.Popen(['python3',str(ROOT/'tools/serve_web.py'),'--port','8141'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
try:
 with sync_playwright() as p:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage','--enable-unsafe-swiftshader','--use-angle=swiftshader'])
  ctx=b.new_context(viewport={'width':540,'height':960},has_touch=True);ctx.add_init_script(seed)
  page=ctx.new_page();errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda m:errors.append(m.text) if m.type=='error' or 'SCRIPT ERROR:' in m.text else None)
  page.goto('http://127.0.0.1:8141/',wait_until='networkidle',timeout=90000)
  page.wait_for_function('document.getElementById("notice").hidden',timeout=90000);page.wait_for_timeout(600)
  page.screenshot(path=str(OUT/'19-profils.png'));page.touchscreen.tap(270,470);page.wait_for_timeout(4000)
  page.screenshot(path=str(OUT/'20-magasin-brico-fun.png'));assert money(OUT/'20-magasin-brico-fun.png')>=1250,'Actual game HUD must be visible'
  print('PREVIEW_STARTED',errors,flush=True)
  page.wait_for_timeout(15000);page.screenshot(path=str(OUT/'21-magasin-vivant.png'))
  assert max(ImageStat.Stat(Image.open(OUT/'21-magasin-vivant.png').convert('RGB')).stddev)>20,'Blank render'
  page.mouse.move(270,430);page.mouse.wheel(0,-200);page.wait_for_timeout(1000);page.screenshot(path=str(OUT/'22-detail-rayons.png'))
  page.set_viewport_size({'width':375,'height':812});page.wait_for_timeout(1000)
  box=page.locator('#game').bounding_box()
  def tap(x,y):page.touchscreen.tap(box['x']+x/540*box['width'],box['y']+y/960*box['height'])
  tap(408,50);page.wait_for_timeout(700);page.screenshot(path=str(OUT/'23-telephone.png'))
  tap(260,380);page.wait_for_timeout(800);page.screenshot(path=str(OUT/'24-telephone-rayon.png'))
  assert 'En rayon' in ocr_shot(OUT/'24-telephone-rayon.png'),'Phone touch must open stocked shelf panel'
  assert not errors,errors
  result={'engine':'Godot 4.6.3','browser':b.version,'viewports':[[540,960],[375,812]],'fixture':'tests/fixtures/brico_fun_visual.json','checks':{'real_webgl_render':True,'nonblank_hud':True,'phone_touch_selection':True},'errors':errors,'note':'Progressed QA fixture. Software rendering; no physical iPad/Android or mobile FPS measurement.'}
  (OUT/'visual-results.json').write_text(json.dumps(result,indent=2)+'\n');print('PREVIEW_FINAL',result,flush=True);b.close()
finally:
 server.terminate();server.wait(timeout=10)
