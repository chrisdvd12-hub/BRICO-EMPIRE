"""Touch-only regression against the real exported game (Chromium/CDP)."""
import io,json,os,subprocess
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parent.parent

def text(page):
    shot=page.screenshot()
    im=Image.open(io.BytesIO(shot));im=im.resize((im.width*2,im.height*2))
    b=io.BytesIO();im.save(b,format='PNG')
    return subprocess.check_output(['tesseract','stdin','stdout'],input=b.getvalue(),stderr=subprocess.DEVNULL).decode()

with sync_playwright() as p:
    browser=p.chromium.launch(args=['--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-gpu-sandbox'])
    results=[]
    # A tall phone and a tablet: the portrait game remains proportional and centred.
    for width,height in [(390,844),(820,1180)]:
        context=browser.new_context(viewport={'width':width,'height':height},has_touch=True,is_mobile=True)
        page=context.new_page();errors=[]
        page.on('pageerror',lambda e:errors.append(str(e)))
        page.goto(os.environ.get('BRICO_TEST_URL','http://127.0.0.1:8001/'),wait_until='networkidle',timeout=60000)
        page.frame_locator('#game').locator('#status').wait_for(state='detached',timeout=60000)
        page.wait_for_timeout(2000)
        box=page.locator('#game').bounding_box()
        assert abs(box['width']/box['height']-9/16)<.002,box
        def point(x,y): return {'x':box['x']+x*box['width']/540,'y':box['y']+y*box['height']/960}
        def tap(x,y):
            xy=point(x,y);page.touchscreen.tap(xy['x'],xy['y']);page.wait_for_timeout(1100)
        for x,y,needle in [(106,902,'Recruter'),(270,902,'grandir'),(434,902,'Succ'),(476,86,'glages')]:
            tap(x,y)
            page.screenshot(path=str(ROOT/f"docs/touch-debug-{width}-{x}.png"))
            actual=text(page)
            assert needle.lower() in actual.lower(),(width,needle,actual)
            tap(454,440)
        # Skip tutorial so its panel does not obstruct the world gesture area.
        tap(458,258)
        cdp=context.new_cdp_session(page)
        def touches(kind,positions):
            cdp.send('Input.dispatchTouchEvent',{'type':kind,'touchPoints':[dict(point(x,y),id=i) for i,x,y in positions]})
        # Pan across a department: release must not open a sheet.
        touches('touchStart',[(0,230,420)])
        for k in range(1,6): touches('touchMove',[(0,230+k*18,420+k*8)])
        touches('touchEnd',[]);page.wait_for_timeout(900)
        assert 'Fermer' not in text(page),'Drag opened a panel'
        # Pinch and release in either finger order; no accidental selection.
        touches('touchStart',[(0,210,450),(1,310,450)])
        for k in range(1,6): touches('touchMove',[(0,210-k*7,450),(1,310+k*7,450)])
        touches('touchEnd',[(1,345,450)]);touches('touchEnd',[])
        page.wait_for_timeout(900)
        assert 'Fermer' not in text(page),'Pinch opened a panel'
        # Recentring and selecting the shelf still work after a gesture.
        tap(396,86);tap(257,397)
        assert 'Capacit' in text(page),'Shelf cannot be touched after gestures'
        page.screenshot(path=str(ROOT/f'docs/touch-{width}.png'))
        assert not errors,errors
        results.append({'viewport':[width,height],'game_rect':box,'four_touch_menus':True,'drag_without_selection':True,'pinch_without_selection':True,'shelf_after_gestures':True,'errors':errors})
        context.close()
    (ROOT/'docs/touch-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
    print(json.dumps(results,ensure_ascii=False,indent=2))
    browser.close()
