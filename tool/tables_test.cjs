// Proof the cashier Sơ đồ bàn screen reads the real floor map from the API.
// Serve build/web (node tool/serve_web.cjs) then: node tool/tables_test.cjs
const puppeteer = require('C:/Users/This PC/AppData/Roaming/npm/node_modules/puppeteer');
const URL = 'http://localhost:8099';
const OUT = 'assets/store/screenshots';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox', '--disable-gpu', '--disable-web-security', '--user-data-dir=D:devpptr-nocors'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 3 });
  page.on('console', (m) => { const t = m.text(); if (/error|exception/i.test(t)) console.log('PAGE:', t.slice(0, 140)); });
  const reqs = [];
  page.on('response', (r) => { const u = r.url(); if (/table-map|table-sessions/.test(u)) reqs.push(`${r.status()} ${u.split('/api')[1]}`); });

  await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
  await wait(5000);
  await page.mouse.click(195, 270); await wait(500);
  await page.keyboard.type('cashier01', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 334); await wait(500);
  await page.keyboard.type('cashier123', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 409); await wait(9000); // land on POS sell

  // bottom nav: 4 tabs across 390 → 'Sơ đồ bàn' is index 2 (~x=243), y≈810
  await page.mouse.click(243, 812); await wait(4000);
  await page.screenshot({ path: `${OUT}/tables-01-map.png` });
  console.log('shot tables-01-map');
  console.log('table requests:', reqs.length ? reqs.join(' | ') : '(none)');

  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
