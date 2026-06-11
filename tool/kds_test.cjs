// Proof the KDS (Bar) screen reads real tickets from the local API.
// Serve build/web (node tool/serve_web.cjs) then: node tool/kds_test.cjs
const puppeteer = require('C:/Users/This PC/AppData/Roaming/npm/node_modules/puppeteer');
const URL = 'http://localhost:8099';
const OUT = 'assets/store/screenshots';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox', '--disable-gpu', '--disable-web-security', '--user-data-dir=D:devpptr-nocors'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 3 });
  page.on('console', (m) => { const t = m.text(); if (/error|exception/i.test(t)) console.log('PAGE:', t.slice(0, 140)); });
  const kdsReqs = [];
  page.on('response', (r) => { const u = r.url(); if (/\/kds\//.test(u)) kdsReqs.push(`${r.status()} ${u.split('/api')[1]}`); });

  await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
  await wait(5000);
  await page.mouse.click(195, 270); await wait(500);
  await page.keyboard.type('barista01', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 334); await wait(500);
  await page.keyboard.type('barista123', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 409); await wait(11000); // submit + land on KDS

  await page.screenshot({ path: `${OUT}/kds-01-queue.png` });
  console.log('shot kds-01-queue');
  console.log('KDS requests:', kdsReqs.length ? kdsReqs.join(' | ') : '(none)');

  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
