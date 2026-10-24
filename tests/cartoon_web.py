"""Run the real WebAssembly game, touch controls and separate local profiles.
Requires Playwright, Chromium, Pillow and Tesseract. Starts a local server unless
BRICO_TEST_URL is set; does not contact player accounts or alter existing saves.
"""
from playwright.sync_api import sync_playwright
from pathlib import Path
from PIL import Image
import io,json,os,re,subprocess,time
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'docs/cartoon'
def ocr_shot(path,crop=None):
 im=Image.open(path)
 if crop: im=im.crop(crop)
 im=im.resize((im.width*2,im.height*2));buf=io.BytesIO();im.save(buf,format='PNG')
 return subprocess.check_output(['tesseract','stdin','stdout','--psm','6'],input=buf.getvalue(),stderr=subprocess.DEVNULL).decode()
def money(path):
 text=ocr_shot(path,(80,50,272,102));m=re.search(r'[0-9][0-9 ]*',text)
 assert m,text
 return int(m[0].replace(' ',''))
def snapshot(page,name):
 path=OUT/name;page.screenshot(path=str(path));return path
def ready(page):
 page.wait_for_function('document.getElementById("notice").hidden',timeout=90000)
 page.wait_for_timeout(500)
def storage(frame):
 return frame.evaluate('Object.fromEntries(Object.entries(localStorage).filter(([k])=>k.startsWith("brico.")).map(([k,v])=>[k,JSON.parse(v)]))')
def touch_drag(cdp,start,end):
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':start[0],'y':start[1]}]})
 for i in range(1,9):
  cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{'x':start[0]+(end[0]-start[0])*i/8,'y':start[1]+(end[1]-start[1])*i/8}]})
 cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]})
def main():
 OUT.mkdir(parents=True,exist_ok=True);(OUT/'browser-results.json').unlink(missing_ok=True)
 server=None;url=os.environ.get('BRICO_TEST_URL')
 if not url:
  server=subprocess.Popen(['python3',str(ROOT/'tools/serve_web.py'),'--port','8132'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
  url='http://127.0.0.1:8132/'
 try:
  with sync_playwright() as p:
   b=p.chromium.launch(executable_path=os.environ.get('BRICO_CHROMIUM','/usr/bin/chromium'),headless=True,args=['--no-sandbox','--disable-dev-shm-usage','--enable-unsafe-swiftshader','--use-angle=swiftshader'])
   context=b.new_context(viewport={'width':540,'height':960},has_touch=True)
   page=context.new_page();errors=[];logs=[]
   page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:logs.append(m.text) if m.type=='error' else None)
   page.goto(url,wait_until='networkidle',timeout=90000);ready(page);snapshot(page,'01-profils.png')
   page.touchscreen.tap(270,758);page.keyboard.type('Alice');page.keyboard.press('Enter')
   page.wait_for_timeout(4000);snapshot(page,'02-magasin.png');print('GAME',errors,logs,flush=True)
   started=time.monotonic()
   while True:
    page.wait_for_timeout(10000);path=snapshot(page,'03-ventes.png')
    if money(path)>200:break
    assert time.monotonic()-started<180,'No settled sale in browser'
   sale_balance=money(path);print('SALES',sale_balance,errors,logs,flush=True)
   # Mouse wheel and a real touch drag; inspect the resulting portraits.
   page.mouse.move(270,430);page.mouse.wheel(0,-300);page.wait_for_timeout(800);snapshot(page,'08-zoom.png')
   cdp=context.new_cdp_session(page);touch_drag(cdp,(250,420),(330,470));page.wait_for_timeout(800);snapshot(page,'09-deplacement.png')
   page.touchscreen.tap(420,78);page.wait_for_timeout(800)
   # A tap on the tooling shelf must open its actual interactive panel.
   page.touchscreen.tap(245,407);page.wait_for_timeout(700)
   selected=snapshot(page,'10-rayon.png');selected_text=ocr_shot(selected)
   assert 'En rayon' in selected_text and 'Capacité' in selected_text and 'Acheter' in selected_text,selected_text
   # Close sheet before switching player, so no scene gesture crosses the panel.
   page.touchscreen.tap(484,431);page.wait_for_timeout(500)
   page.touchscreen.tap(476,78);page.wait_for_timeout(800);snapshot(page,'04-parametres.png')
   page.touchscreen.tap(270,566);page.wait_for_timeout(800);snapshot(page,'05-changer.png');print('SWITCH',errors,logs,flush=True)
   page.touchscreen.tap(270,758);page.keyboard.type('Bob');page.keyboard.press('Enter');page.wait_for_timeout(1500)
   assert money(snapshot(page,'06-bob.png'))==200,'Bob must start independently'
   before=storage(page.frames[1]);index=before['brico.index.v1:user://players/index.json']
   assert [x['name'] for x in index['profiles']]==['Alice','Bob'],index
   alice=index['profiles'][0]['id'];bob=index['profiles'][1]['id']
   alice_saved=before['brico.save.v2:user://players/'+alice+'.json'];assert alice_saved['money']>=sale_balance and alice_saved['total_sales']>0,alice_saved
   page.reload(wait_until='networkidle');ready(page)
   snapshot(page,'07-rechargement.png')
   after=storage(page.frames[1]);reloaded_index=after['brico.index.v1:user://players/index.json']
   assert [p['name'] for p in reloaded_index['profiles']]==['Alice','Bob'],reloaded_index
   assert reloaded_index['active_id']==bob
   # Selecting Alice again must load her settled revenue, rather than a new store.
   page.touchscreen.tap(270,480);page.wait_for_timeout(1500)
   restored=money(snapshot(page,'11-alice-reprise.png'));assert restored>=sale_balance,restored
   assert not errors,errors
   assert not logs,logs
   result={'browser':b.version,'viewport':[540,960],'errors':errors,'console_errors':logs,'checks':{'settled_sale':True,'alice_balance_after_sale':sale_balance,'alice_balance_restored':restored,'bob_initial_balance':200,'profiles_survive_reload':True,'touch_shelf_selection':True,'camera_drag_and_mouse_zoom_exercised':True},'engine':'Godot 4.6.3','note':'Chromium software rendering; no physical Safari/iPad or mobile FPS measurement.'}
   (OUT/'browser-results.json').write_text(json.dumps(result,indent=2)+'\n');print('FINAL',json.dumps(result),flush=True)
   b.close()
 finally:
  if server:server.terminate();server.wait(timeout=10)
if __name__=='__main__':main()
