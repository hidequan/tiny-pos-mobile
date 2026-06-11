// Proof inventory adjustment: Kho -> ingredient -> Điều chỉnh -> actual count.
// Serve build/web then: node tool/adjust_test.cjs
const puppeteer = require('C:/Users/This PC/AppData/Roaming/npm/node_modules/puppeteer');
const URL = 'http://localhost:8099';
const OUT = 'assets/store/screenshots';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox', '--disable-gpu', '--disable-web-security', '--user-data-dir=D:devpptr-nocors'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 3 });
  page.on('console', (m) => { const t = m.text(); if (/error|exception/i.test(t)) console.log('PAGE:', t.slice(0, 140)); });
  const posts = [];
  page.on('response', (r) => { const u = r.url(); const m = r.request().method(); if (/adjustments|stock-in/.test(u) && m === 'POST') posts.push(`${m} ${r.status()} ${u.split('/api')[1]}`); });

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

  await page.mouse.click(195, 812); await wait(3000); // Kho tab
  await page.mouse.click(195, 267); await wait(2500); // first ingredient -> sheet
  await page.screenshot({ path: `${OUT}/adj-00-sheet.png` }); console.log('shot adj-00-sheet');
  await page.mouse.click(285, 618); await wait(1500); // "Điều chỉnh" segment
  await page.screenshot({ path: `${OUT}/adj-01-mode.png` }); console.log('shot adj-01-mode');
  await page.keyboard.press('Tab'); await wait(400); // focus the qty field (Flutter-web)
  await page.keyboard.type('2000', { delay: 45 }); await wait(800); // actual counted amount
  await page.screenshot({ path: `${OUT}/adj-02-delta.png` }); console.log('shot adj-02-delta');
  await page.mouse.click(195, 800); await wait(3500); // Xác nhận điều chỉnh
  await page.screenshot({ path: `${OUT}/adj-03-done.png` }); console.log('shot adj-03-done');

  console.log('posts:', posts.length ? posts.join(' | ') : '(none)');
  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
