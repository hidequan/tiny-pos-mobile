// Proof the admin Tổng quan + Báo cáo read real /admin/reports data.
// Serve build/web (node tool/serve_web.cjs) then: node tool/admin_test.cjs
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
  page.on('response', (r) => { const u = r.url(); if (/admin\/reports/.test(u)) reqs.push(`${r.status()} ${u.split('/api')[1].split('?')[0]}`); });

  await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
  await wait(2500);
  // Drop any cached session (shared_preferences = localStorage on web) so the
  // login form actually shows instead of auto-restoring a prior role.
  await page.evaluate(() => { try { localStorage.clear(); } catch (e) {} });
  await page.reload({ waitUntil: 'networkidle2', timeout: 60000 });
  await wait(5000);
  await page.mouse.click(195, 270); await wait(500);
  await page.keyboard.type('manager01', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 334); await wait(500);
  await page.keyboard.type('manager123', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 409); await wait(9000); // land on admin home

  await page.screenshot({ path: `${OUT}/admin-01-home.png` });
  console.log('shot admin-01-home');

  // bottom nav 5 tabs across 390 → 'Báo cáo' is index 3 (~x=273), y≈812
  await page.mouse.click(273, 812); await wait(4000);
  await page.screenshot({ path: `${OUT}/admin-02-reports.png` });
  console.log('shot admin-02-reports');
  console.log('report requests:', reqs.length ? reqs.join(' | ') : '(none)');

  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
