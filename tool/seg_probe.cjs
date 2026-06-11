// Safe probe: open Kho sheet, tap segment at Y, screenshot (no submit).
const puppeteer = require('C:/Users/This PC/AppData/Roaming/npm/node_modules/puppeteer');
const URL = 'http://localhost:8099';
const OUT = 'assets/store/screenshots';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const Y = Number(process.argv[2] || 618);

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox', '--disable-gpu', '--disable-web-security', '--user-data-dir=D:devpptr-nocors'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 3 });
  await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
  await wait(2500);
  await page.evaluate(() => { try { localStorage.clear(); } catch (e) {} });
  await page.reload({ waitUntil: 'networkidle2', timeout: 60000 });
  await wait(5000);
  await page.mouse.click(195, 270); await wait(500);
  await page.keyboard.type('manager01', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 334); await wait(500);
  await page.keyboard.type('manager123', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 409); await wait(9000);
  await page.mouse.click(195, 812); await wait(3000); // Kho
  await page.mouse.click(195, 267); await wait(2500); // ingredient -> sheet
  await page.mouse.click(285, Y); await wait(1500);   // segment probe
  await page.screenshot({ path: `${OUT}/seg-y${Y}.png` }); console.log('shot seg-y' + Y);
  await browser.close();
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
