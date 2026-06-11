// End-to-end proof that real login works in the app against the live API.
// Serve build/web (node tool/serve_web.cjs) then: node tool/login_test.cjs
const puppeteer = require('C:/Users/This PC/AppData/Roaming/npm/node_modules/puppeteer');
const URL = 'http://localhost:8099';
const OUT = 'assets/store/screenshots';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox', '--disable-gpu', '--disable-web-security', '--user-data-dir=D:devpptr-nocors'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 3 });
  page.on('console', (m) => { const t = m.text(); if (/error|exception/i.test(t)) console.log('PAGE:', t.slice(0, 120)); });

  await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
  await wait(5000); // Flutter render + fonts
  await page.screenshot({ path: `${OUT}/login-01-initial.png` });
  console.log('shot login-01-initial');

  // Type credentials (Flutter web receives key events after focusing a field).
  await page.mouse.click(195, 270); await wait(600);
  await page.keyboard.type('cashier01', { delay: 40 }); await wait(400);
  await page.mouse.click(195, 334); await wait(600);
  await page.keyboard.type('cashier123', { delay: 40 }); await wait(400);
  await page.screenshot({ path: `${OUT}/login-02-filled.png` });
  console.log('shot login-02-filled');

  await page.mouse.click(195, 409); await wait(10000); // submit + navigate
  await page.screenshot({ path: `${OUT}/login-03-after.png` });
  console.log('shot login-03-after');

  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
