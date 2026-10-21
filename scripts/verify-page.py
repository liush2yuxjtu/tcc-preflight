# Headless 390x844 check: no horizontal scroll, tap targets >=44px, one screen. Usage: python3 verify-page.py URL OUT.png
import sys,json
from playwright.sync_api import sync_playwright
url,out=sys.argv[1],sys.argv[2]
with sync_playwright() as p:
  b=p.chromium.launch(); pg=b.new_page(viewport={'width':390,'height':844},is_mobile=True,has_touch=True,device_scale_factor=2)
  r=pg.goto(url); pg.wait_for_load_state('networkidle')
  m=pg.evaluate("""()=>({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,sh:document.documentElement.scrollHeight,
   lang:document.documentElement.lang,img:document.querySelector('img').naturalWidth,
   small:[...document.querySelectorAll('a,button')].map(e=>e.getBoundingClientRect()).filter(r=>r.width<44||r.height<44).length})""")
  pg.screenshot(path=out); b.close()
m['status']=r.status
checks={'http200':m['status']==200,'noHScroll':m['sw']<=m['cw'],'oneScreen':m['sh']<=844,'tap44':m['small']==0,'en':m['lang']=='en','imgLoaded':m['img']>0}
print(json.dumps({**m,**checks}))
for k,v in checks.items(): print(('PASS ' if v else 'FAIL ')+k)
sys.exit(0 if all(checks.values()) else 1)
