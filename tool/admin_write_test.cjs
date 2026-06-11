// Proof admin product writes hit the API: toggle a product's availability.
// Serve build/web then: node tool/admin_write_test.cjs
const puppeteer = require('C:/Users/This PC/AppData/Roaming/npm/node_modules/puppeteer');
const URL = 'http://localhost:8099';
const OUT = 'assets/store/screenshots';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox', '--disable-gpu', '--disable-web-security', '--user-data-dir=D:devpptr-nocors'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 3 });
  page.on('console', (m) => { const t = m.text(); if (/error|exception/i.test(t)) console.log('PAGE:', t.slice(0, 140)); });
  const writes = [];
  page.on('response', (r) => { const u = r.url(); const m = r.request().method(); if (/\/admin\/products/.test(u) && m !== 'GET') writes.push(`${m} ${r.status()} ${u.split('/api')[1]}`); });

  await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
  await wait(2500);
  await page.evaluate(() => { try { localStorage.clear(); } catch (e) {} });
  await page.reload({ waitUntil: 'networkidle2', timeout: 60000 });
  await wait(5000);
  await page.mouse.click(195, 270); await wait(500);
  await page.keyboard.type('manager01', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 334); await wait(500);
  await page.keyboard.type('manager123', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 409); await wait(9000); // admin home

  await page.mouse.click(117, 812); await wait(3500); // Thực đơn tab
  await page.mouse.click(180, 170); await wait(2500); // tap product row -> detail sheet
  await page.screenshot({ path: `${OUT}/admin-07-detail.png` }); console.log('shot admin-07-detail');
  // availability switch in the sheet's first ("Đang bán") card, right edge
  await page.mouse.click(335, 380); await wait(4500); // toggle off (PATCH) -> sheet closes
  await page.screenshot({ path: `${OUT}/admin-07-toggle.png` }); console.log('shot admin-07-toggle');
  // toggle back on to restore: reopen detail + switch again
  await page.mouse.click(180, 170); await wait(2500);
  await page.mouse.click(335, 380); await wait(4500);
  console.log('product writes:', writes.length ? writes.join(' | ') : '(none)');

  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
