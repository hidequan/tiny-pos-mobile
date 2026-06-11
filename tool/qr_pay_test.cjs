// Proof the real QR payment flow: add → pay → QR → confirm → PAID.
// Serve build/web then: node tool/qr_pay_test.cjs
const puppeteer = require('C:/Users/This PC/AppData/Roaming/npm/node_modules/puppeteer');
const URL = 'http://localhost:8099';
const OUT = 'assets/store/screenshots';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox', '--disable-gpu', '--disable-web-security', '--user-data-dir=D:devpptr-nocors'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 3 });
  page.on('console', (m) => { const t = m.text(); if (/error|exception/i.test(t)) console.log('PAGE:', t.slice(0, 140)); });
  const pays = [];
  page.on('response', (r) => { const u = r.url(); const m = r.request().method(); if (/payments\/qr|manual-confirm|\/pos\/bills(\?|$)/.test(u) && m === 'POST') pays.push(`${m} ${r.status()} ${u.split('/api')[1]}`); });

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

  await page.mouse.click(110, 210); await wait(2500); // tap first product -> options sheet
  await page.screenshot({ path: `${OUT}/qr-00-options.png` }); console.log('shot qr-00-options');
  await page.mouse.click(210, 806); await wait(2500); // "Thêm · 29.000đ" (adds + closes)
  await page.mouse.click(195, 745); await wait(2500); // cart bar (anywhere) -> cart sheet
  await page.screenshot({ path: `${OUT}/qr-01-cart.png` }); console.log('shot qr-01-cart');
  await page.mouse.click(195, 806); await wait(2500); // "Thanh toán ·"
  await page.mouse.click(195, 456); await wait(1800); // method "Chuyển khoản / QR"
  await page.screenshot({ path: `${OUT}/qr-015-method.png` }); console.log('shot qr-015-method');
  await page.mouse.click(195, 812); await wait(5000); // "Hoàn tất đơn hàng" -> creates bill+QR
  await page.screenshot({ path: `${OUT}/qr-02-qrsheet.png` }); console.log('shot qr-02-qrsheet');
  await page.mouse.click(195, 812); await wait(4500); // "Khách đã chuyển khoản" -> confirm
  await page.screenshot({ path: `${OUT}/qr-03-success.png` }); console.log('shot qr-03-success');
  console.log('payment posts:', pays.length ? pays.join(' | ') : '(none)');

  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
