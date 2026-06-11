// Proof the real voucher flow: create bill at pay-open → apply XINCHAOTHANG6 →
// discounted total → pay cash → success. Serve build/web then run this.
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
  page.on('response', (r) => { const u = r.url(); const m = r.request().method(); if (/apply-voucher|payments\/cash|\/pos\/bills(\?|$)/.test(u) && m === 'POST') posts.push(`${m} ${r.status()} ${u.split('/api')[1]}`); });

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

  await page.mouse.click(110, 210); await wait(2500); // product -> options sheet
  await page.mouse.click(210, 806); await wait(2500); // Thêm
  await page.mouse.click(195, 745); await wait(2500); // cart bar -> cart sheet
  await page.mouse.click(195, 806); await wait(5000); // Thanh toán -> creates bill, pay sheet
  await page.screenshot({ path: `${OUT}/vou-01-paysheet.png` }); console.log('shot vou-01-paysheet');

  // voucher field near top of pay sheet (y~252); type then Áp dụng (x~326)
  await page.mouse.click(145, 252); await wait(600); // focus voucher TextField
  await page.keyboard.type('XINCHAOTHANG6', { delay: 45 }); await wait(500);
  await page.mouse.click(326, 252); await wait(3500); // Áp dụng
  await page.screenshot({ path: `${OUT}/vou-02-applied.png` }); console.log('shot vou-02-applied');

  // pay cash: pick a quick amount (100.000đ ~ y684) then Hoàn tất (~y800)
  await page.mouse.click(234, 684); await wait(1200);
  await page.mouse.click(195, 800); await wait(4500); // Hoàn tất đơn hàng
  await page.screenshot({ path: `${OUT}/vou-03-success.png` }); console.log('shot vou-03-success');
  console.log('posts:', posts.length ? posts.join(' | ') : '(none)');

  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
