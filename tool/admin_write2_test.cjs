// Proof admin staff-create + inventory stock-in write to the API.
// Serve build/web then: node tool/admin_write2_test.cjs
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
  page.on('response', (r) => { const u = r.url(); const m = r.request().method(); if (/\/admin\/users(\?|$)|stock-in/.test(u) && m === 'POST') posts.push(`${m} ${r.status()} ${u.split('/api')[1]}`); });

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

  // ---- staff create ----
  await page.mouse.click(351, 812); await wait(2200); // Thêm tab -> Quản lý list
  await page.mouse.click(195, 130); await wait(3000); // "Nhân viên & phân quyền" row
  await page.screenshot({ path: `${OUT}/aw2-00-staffpage.png` }); console.log('shot aw2-00-staffpage');
  await page.mouse.click(348, 100); await wait(2500); // "+ Thêm" (SectionHeader action)
  await page.screenshot({ path: `${OUT}/aw2-01-staffform.png` }); console.log('shot aw2-01-staffform');
  // fill fields via click + Tab traversal
  const rnd = Math.floor(Math.random() * 9000 + 1000);
  // Flutter-web text fields focus reliably via Tab, not coordinate clicks.
  await page.keyboard.press('Tab'); await wait(350);            // -> Họ tên
  await page.keyboard.type('NV App ' + rnd, { delay: 35 }); await wait(250);
  await page.keyboard.press('Tab'); await wait(350);            // -> Tên đăng nhập
  await page.keyboard.type('apptest' + rnd, { delay: 35 }); await wait(250);
  await page.keyboard.press('Tab'); await wait(350);            // -> Mật khẩu
  await page.keyboard.type('test123456', { delay: 35 }); await wait(250);
  await page.screenshot({ path: `${OUT}/aw2-02-stafffilled.png` }); console.log('shot aw2-02-stafffilled');
  await page.mouse.click(195, 800); await wait(3500); // Tạo nhân viên
  await page.screenshot({ path: `${OUT}/aw2-03-stafflist.png` }); console.log('shot aw2-03-stafflist');

  // ---- inventory stock-in ----
  await page.mouse.click(195, 812); await wait(3000); // Kho tab
  await page.mouse.click(195, 235); await wait(2500); // first ingredient row -> Nhập kho sheet
  await page.screenshot({ path: `${OUT}/aw2-04-stockin.png` }); console.log('shot aw2-04-stockin');
  await page.keyboard.type('250', { delay: 45 }); await wait(400); // autofocused qty
  await page.mouse.click(195, 800); await wait(3500); // Xác nhận nhập kho
  await page.screenshot({ path: `${OUT}/aw2-05-stockdone.png` }); console.log('shot aw2-05-stockdone');

  console.log('posts:', posts.length ? posts.join(' | ') : '(none)');
  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
