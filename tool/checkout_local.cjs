// Proves the cash checkout creates a REAL bill — against the LOCAL backend.
// Serve build/web (built with API_BASE=localhost:4000), then run this.
const puppeteer = require('C:/Users/This PC/AppData/Roaming/npm/node_modules/puppeteer');
const URL = 'http://localhost:8099';
const OUT = 'assets/store/screenshots';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-gpu', '--disable-web-security', '--user-data-dir=D:\\dev\\pptr2'],
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 2 });

  await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
  await wait(5000);
  // login
  await page.mouse.click(195, 270); await wait(400);
  await page.keyboard.type('cashier01', { delay: 30 });
  await page.mouse.click(195, 334); await wait(400);
  await page.keyboard.type('cashier123', { delay: 30 });
  await page.mouse.click(195, 409); await wait(7000); // menu load
  await page.screenshot({ path: `${OUT}/co-1-sell.png` }); console.log('1 sell');

  // tap first product (adds to cart)
  await page.mouse.click(100, 250); await wait(1500);
  await page.screenshot({ path: `${OUT}/co-2-added.png` }); console.log('2 added');

  // open cart via cart bar (right side "Xem đơn")
  await page.mouse.click(330, 770); await wait(1800);
  await page.screenshot({ path: `${OUT}/co-3-cart.png` }); console.log('3 cart');

  // pay button (footer)
  await page.mouse.click(195, 805); await wait(1800);
  await page.screenshot({ path: `${OUT}/co-4-pay.png` }); console.log('4 pay');

  // pick a quick cash amount (first chip row) then complete
  await page.mouse.click(120, 430); await wait(900);
  await page.screenshot({ path: `${OUT}/co-5-cash.png` }); console.log('5 cash');
  await page.mouse.click(195, 805); await wait(6000); // complete -> create bill + pay
  await page.screenshot({ path: `${OUT}/co-6-done.png` }); console.log('6 done');

  await browser.close();
  console.log('finished');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
