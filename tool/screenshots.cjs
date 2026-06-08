// Captures store screenshots of the running web build via headless Chromium.
//   1) serve build/web (node tool/serve_web.cjs)  2) node tool/screenshots.cjs
const puppeteer = require('C:/Users/This PC/AppData/Roaming/npm/node_modules/puppeteer');

const URL = 'http://localhost:8099';
const OUT = 'assets/store/screenshots';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox', '--disable-gpu'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 3 });

  async function load() {
    await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
    await wait(4500); // let Flutter/CanvasKit + fonts render
  }
  async function shot(name) {
    await page.screenshot({ path: `${OUT}/${name}.png` });
    console.log('shot', name);
  }
  const click = async (x, y, settle = 2200) => { await page.mouse.click(x, y); await wait(settle); };

  // 1) Login
  await load();
  await shot('01-login');

  // 2+3) Cashier: sell, then tables tab
  await click(195, 300); // "Thu ngân" role card
  await shot('02-cashier-sell');
  await click(244, 815); // bottom nav: "Sơ đồ bàn" (3rd of 4)
  await shot('03-cashier-tables');

  // 4) KDS queue
  await load();
  await click(195, 392); // "KDS / Bar" role card
  await shot('04-kds-queue');

  // 5+6) Admin: home, then reports tab
  await load();
  await click(195, 485); // "Quản trị" role card
  await shot('05-admin-home');
  await click(234, 815); // bottom nav: "Báo cáo" (4th of 5)
  await shot('06-admin-reports');

  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
