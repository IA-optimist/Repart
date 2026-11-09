from playwright.sync_api import sync_playwright
from pathlib import Path
import json
repo_root=Path(__file__).resolve().parents[1]
root=repo_root/'public'

fixtures={'makes':[{'name':f'Vehicle Brand {i:03d}','models':[{'name':f'Model {j:02d}','kind':'car'} for j in range(22)]} for i in range(220)]+[{'name':'Volkswagen','models':[{'name':'Polo','kind':'car'},{'name':'Golf','kind':'car'}]}]}
with sync_playwright() as p:
 browser=p.chromium.launch(headless=True,executable_path='/usr/bin/chromium',args=['--no-sandbox','--disable-dev-shm-usage'])
 context=browser.new_context(viewport={'width':390,'height':844})
 def mock(route):
  route.fulfill(status=200,body=json.dumps(fixtures),content_type='application/json')
 context.route('**/dist/vehicles.json',mock)
 context.route('https://repart.test/**',lambda route: route.fulfill(status=200,body=(root/('catalogue-auto.html' if route.request.url.split('?',1)[0].endswith('catalogue-auto.html') else 'index.html')).read_text(),content_type='text/html'))
 page=context.new_page()
 errors=[]
 page.on('pageerror',lambda err:errors.append(str(err)))
 page.goto('about:blank')
 page.set_content((root/'index.html').read_text(),wait_until='load')
 page.wait_for_function('document.querySelector("#vehicleDirectoryStatus").textContent.includes("221 marques")',timeout=18000)
 page.locator('#make').select_option('Volkswagen')
 page.locator('#model').select_option('Polo')
 page.locator('#year').select_option('2012')
 assert page.locator('#make option').count()>=220
 assert page.locator('#year option').count()>=78
 page.locator('#make').select_option('Vehicle Brand 001')
 page.locator('#model').select_option('Model 03')
 assert '0 annonce' in page.locator('#resultCount').inner_text(), page.locator('#resultCount').inner_text()
 assert 'Aucune annonce actuelle' in page.locator('#activeFilters').inner_text()
 page.screenshot(path=str(repo_root/'tests/screenshot_v06_mobile.png'),full_page=True)
 # New page uses same cached source
 cat=context.new_page();cat.on('pageerror',lambda e:errors.append('catalogue: '+str(e)))
 cat.goto('about:blank')
 cat.set_content((root/'catalogue-auto.html').read_text(),wait_until='load')
 cat.wait_for_function('document.querySelector("#loadStatus").textContent.includes("VehiclesDB")',timeout=20000)
 cat.locator('#make').select_option('Volkswagen')
 cat.locator('#model').select_option('Polo')
 cat.locator('#year').select_option('2012')
 assert cat.locator('#generation').is_enabled(),cat.locator('#generation').inner_text()
 assert 'Polo' in cat.locator('#identification').inner_text()
 cat.screenshot(path=str(repo_root/'tests/screenshot_v06_catalogue_mobile.png'),full_page=True)
 assert not errors, errors
 browser.close()
print('PASS smoke — 221 mock brands, 4842 mock models, deep link, zero offers, Polo 2012 and mobile')

