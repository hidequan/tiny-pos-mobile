// Proof "In bill" generates a real PDF receipt (pay cash → success → print).
// Serve build/web then: node tool/receipt_test.cjs
const puppeteer = require('C:/Users/This PC/AppData/Roaming/npm/node_modules/puppeteer');
const URL = 'http://localhost:8099';
const OUT = 'assets/store/screenshots';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox', '--disable-gpu', '--disable-web-security', '--user-data-dir=D:devpptr-nocors'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 3 });
  page.on('console', (m) => { const t = m.text(); if (/error|exception/i.test(t)) console.log('PAGE:', t.slice(0, 160)); });
  let fontFetched = false;
  page.on('response', (r) => { if (/Roboto-(Regular|Medium)\.ttf/.test(r.url())) fontFetched = true; });
  // Hook print + pdf blob creation so we can detect receipt generation.
  await page.evaluateOnNewDocument(() => {
    window.__printed = 0; window.__pdf = 0; window.__iframes = 0;
    const op = window.print; window.print = function () { window.__printed++; try { return op.apply(this, arguments); } catch (e) {} };
    const OB = window.Blob;
    window.Blob = function (parts, opts) { try { if (opts && opts.type && /pdf/i.test(opts.type)) window.__pdf++; } catch (e) {} return new OB(parts, opts || {}); };
    window.Blob.prototype = OB.prototype;
    try {
      new MutationObserver((muts) => muts.forEach((m) => m.addedNodes.forEach((n) => { if (n.tagName === 'IFRAME') window.__iframes++; })))
        .observe(document.documentElement, { childList: true, subtree: true });
    } catch (e) {}
  });

  await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
  await wait(2500);
  await page.evaluate(() => { try { localStorage.clear(); } catch (e) {} });
  await page.reload({ waitUntil: 'networkidle2', timeout: 60000 });
  await wait(5000);
  await page.mouse.click(195, 270); await wait(500);
  await page.keyboard.type('cashier01', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 334); await wait(500);
  await page.keyboard.type('cashier123', { delay: 40 }); await wait(300);
  await page.mouse.click(195, 409); await wait(9000);

  await page.mouse.click(110, 210); await wait(2500); // product -> options
  await page.mouse.click(210, 806); await wait(2500); // Thêm
  await page.mouse.click(195, 745); await wait(2500); // cart bar
  await page.mouse.click(195, 806); await wait(5000); // Thanh toán -> bill + pay sheet (cash default)
  await page.mouse.click(86, 684); await wait(1200);  // exact-amount quick cash pill
  await page.mouse.click(195, 800); await wait(5000); // Hoàn tất -> success
  await page.screenshot({ path: `${OUT}/rc-01-success.png` }); console.log('shot rc-01-success');
  await page.mouse.click(95, 810); await wait(5000); // "In bill"
  await page.screenshot({ path: `${OUT}/rc-02-afterprint.png` }); console.log('shot rc-02-afterprint');
  const r = await page.evaluate(() => ({ printed: window.__printed, pdf: window.__pdf, iframes: window.__iframes }));
  console.log('print result:', JSON.stringify(r), '| receiptFontFetched:', fontFetched);

  await browser.close();
  console.log('done');
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
