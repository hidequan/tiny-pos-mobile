// Proof the cashier shift screen reads the real open shift + records cash-in.
// Serve build/web then: node tool/shift_test.cjs
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
  page.on('response', (r) => { const u = r.url(); const m = r.request().method(); if (/shifts\/current|cash-in|cash-out|shifts\/open|\/close/.test(u)) reqs.push(`${m} ${r.status()} ${u.split('/api')[1]}`); });

  await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
  await wait(2500);
  await page.evaluate(() => { try { localStorage.clear(); } catch (e) {} });
  await page.reload({ waitUntil: 'networkidle2', timeout: 60000 });
  await wait(5000);
  await page.mouse.click(195, 270); await wait(500);
  await page.keyboard.type('cashier01', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 334); await wait(500);
  await page.keyboard.type('cashier123', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 409); await wait(9000); // POS sell

  await page.mouse.click(341, 812); await wait(4000); // "Ca làm" tab (4th)
  await page.screenshot({ path: `${OUT}/shift-01-screen.png` }); console.log('shot shift-01-screen');

  // "Thu thêm" button (left of the row, ~y=740 area)
  await page.mouse.click(110, 740); await wait(2500);
  await page.screenshot({ path: `${OUT}/shift-02-cashin.png` }); console.log('shot shift-02-cashin');
  await page.keyboard.press('Tab'); await wait(400); // focus amount (Flutter-web)
  await page.keyboard.type('100000', { delay: 40 }); await wait(500);
  await page.mouse.click(195, 800); await wait(3500); // Xác nhận thu
  await page.screenshot({ path: `${OUT}/shift-03-after.png` }); console.log('shot shift-03-after');

  console.log('shift requests:', reqs.length ? reqs.join(' | ') : '(none)');
  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
