// Comprehensive end-to-end functional test of every feature the Flutter app uses.
// Hits the SAME backend endpoints the app's repositories call, against the LOCAL
// backend (safe). Reads exhaustively + exercises representative write round-trips.
const BASE = 'http://localhost:4000/api';
let pass = 0, fail = 0;
const fails = [];

async function login(u, p) {
  const r = await fetch(`${BASE}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ username: u, password: p }) });
  const j = await r.json();
  if (!j.data?.accessToken) throw new Error('login failed ' + u);
  return j.data.accessToken;
}
function H(tok) { return { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' }; }
async function api(tok, method, path, body) {
  const r = await fetch(`${BASE}${path}`, { method, headers: H(tok), body: body ? JSON.stringify(body) : undefined });
  const text = await r.text();
  let j; try { j = text ? JSON.parse(text) : {}; } catch { j = { raw: text }; }
  if (!r.ok) throw new Error(`${r.status} ${path} :: ${(j.error?.message || j.message || text || '').slice(0, 80)}`);
  return j.data !== undefined ? j.data : j;
}
async function check(name, fn) {
  try { const info = await fn(); pass++; console.log(`  \x1b[32m✓\x1b[0m ${name}${info ? ` \x1b[90m— ${info}\x1b[0m` : ''}`); return true; }
  catch (e) { fail++; fails.push(`${name}: ${e.message}`); console.log(`  \x1b[31m✗\x1b[0m ${name} \x1b[31m— ${e.message}\x1b[0m`); return false; }
}
function section(t) { console.log(`\n\x1b[1m\x1b[33m== ${t} ==\x1b[0m`); }

(async () => {
  let mgr, cashier, barista, branchId, variantId, productName;

  section('AUTH');
  await check('Đăng nhập Quản lý (manager01)', async () => { mgr = await login('manager01', 'manager123'); return 'token ok'; });
  await check('Đăng nhập Thu ngân (cashier01)', async () => { cashier = await login('cashier01', 'cashier123'); });
  await check('Đăng nhập Pha chế (barista01)', async () => { barista = await login('barista01', 'barista123'); });
  await check('GET /auth/me', async () => { const me = await api(mgr, 'GET', '/auth/me'); branchId = me.branchId; return `branch ${branchId?.slice(0, 8)}`; });

  section('THU NGÂN · Thực đơn');
  await check('GET /pos/menu', async () => {
    const m = await api(cashier, 'GET', '/pos/menu');
    const prod = m.products?.find(p => p.variants?.length) || m.products?.[0];
    variantId = prod?.variants?.[0]?.id; productName = prod?.name;
    return `${m.products?.length} món · ${m.categories?.length} danh mục`;
  });

  section('THU NGÂN · Ca làm việc');
  let shiftId;
  await check('GET /pos/shifts/current', async () => {
    const s = await api(cashier, 'GET', '/pos/shifts/current');
    if (s && s.id) { shiftId = s.id; return `đang mở ${s.shiftCode}`; }
    return 'chưa mở ca';
  });
  if (!shiftId) {
    await check('POST /pos/shifts/open (mở ca để thu tiền)', async () => {
      const s = await api(cashier, 'POST', '/pos/shifts/open', { openingCash: 500000 });
      shiftId = s.id; return s.shiftCode;
    });
  }

  section('THU NGÂN · Bán hàng (vòng đời hoá đơn)');
  let billId, billCode;
  await check('POST /pos/bills (tạo đơn mang đi + món)', async () => {
    const b = await api(cashier, 'POST', '/pos/bills', { serviceType: 'TAKE_AWAY', items: [{ variantId, quantity: 2 }], idempotencyKey: 'e2e-' + Date.now() });
    billId = b.id; billCode = b.billCode; return `${billCode} · ${b.grandTotal}đ`;
  });
  await check('POST /pos/bills/:id/send-to-bar (Gửi Bar → KDS)', async () => { await api(cashier, 'POST', `/pos/bills/${billId}/send-to-bar`); });
  await check('POST /pos/bills/:id/payments/cash (thu tiền mặt)', async () => {
    const r = await api(cashier, 'POST', `/pos/bills/${billId}/payments/cash`, { received: 100000, idempotencyKey: 'e2e-pay-' + Date.now() });
    return 'đã thu';
  });
  await check('GET /pos/bills/:id (xác nhận PAID)', async () => { const b = await api(cashier, 'GET', `/pos/bills/${billId}`); if (b.status !== 'PAID') throw new Error('status=' + b.status); return 'PAID'; });
  await check('GET /pos/bills (lịch sử đơn)', async () => { const l = await api(cashier, 'GET', '/pos/bills'); const n = Array.isArray(l) ? l.length : (l.items?.length ?? 0); return `${n} đơn`; });
  await check('GET /pos/bills/unpaid (đơn chưa trả)', async () => { const l = await api(cashier, 'GET', '/pos/bills/unpaid'); const n = Array.isArray(l) ? l.length : (l.items?.length ?? 0); return `${n} đơn`; });

  section('THU NGÂN · QR + Voucher');
  let qrBillId;
  await check('POST /pos/bills (đơn cho QR)', async () => { const b = await api(cashier, 'POST', '/pos/bills', { serviceType: 'TAKE_AWAY', items: [{ variantId, quantity: 1 }], idempotencyKey: 'e2e-qr-' + Date.now() }); qrBillId = b.id; });
  await check('POST /pos/bills/:id/payments/qr (tạo QR động)', async () => { const q = await api(cashier, 'POST', `/pos/bills/${qrBillId}/payments/qr`, {}); return `ref ${q.referenceCode}`; });
  // voucher apply/remove on a fresh draft
  let vBill, voucherCode;
  await check('Lấy 1 voucher đang chạy', async () => { const vs = await api(mgr, 'GET', '/admin/vouchers'); voucherCode = (vs.find(v => v.status === 'ACTIVE') || vs[0])?.code; return voucherCode || 'không có'; });
  await check('POST /pos/bills (đơn cho voucher)', async () => { const b = await api(cashier, 'POST', '/pos/bills', { serviceType: 'TAKE_AWAY', items: [{ variantId, quantity: 3 }], idempotencyKey: 'e2e-v-' + Date.now() }); vBill = b.id; });
  if (voucherCode) {
    await check('POST /pos/bills/:id/apply-voucher', async () => { const b = await api(cashier, 'POST', `/pos/bills/${vBill}/apply-voucher`, { code: voucherCode }); return `giảm ${b.discountTotal}đ`; });
    await check('DELETE /pos/bills/:id/voucher (gỡ mã)', async () => { await api(cashier, 'DELETE', `/pos/bills/${vBill}/voucher`); });
  }

  section('THU NGÂN · Huỷ / Hoàn (gửi yêu cầu)');
  await check('POST /pos/bills/:id/void-request (yêu cầu huỷ)', async () => { await api(cashier, 'POST', `/pos/bills/${vBill}/void-request`, { reason: 'E2E test huỷ' }); });
  await check('POST /pos/bills/:id/refund-request (yêu cầu hoàn — đơn đã trả)', async () => { await api(cashier, 'POST', `/pos/bills/${billId}/refund-request`, { amount: 1000, reason: 'E2E test hoàn' }); });

  section('THU NGÂN · Bàn (dine-in, gộp/tách)');
  let areaTables = [], sid, dineBillId;
  await check('GET /pos/table-map (sơ đồ bàn)', async () => { const areas = await api(cashier, 'GET', '/pos/table-map'); areaTables = areas.flatMap(a => a.tables || []); return `${areas.length} khu · ${areaTables.length} bàn`; });
  const emptyTable = () => areaTables.find(t => t.status === 'EMPTY');
  await check('POST /pos/tables/:id/open (mở bàn)', async () => {
    const t = emptyTable(); if (!t) throw new Error('không có bàn trống');
    const r = await api(cashier, 'POST', `/pos/tables/${t.id}/open`, { guestCount: 2 });
    sid = (r.session?.id) || r.id; return `bàn ${t.code}`;
  });
  await check('GET /pos/table-sessions/:id (chi tiết phiên)', async () => { const d = await api(cashier, 'GET', `/pos/table-sessions/${sid}`); dineBillId = d.bills?.[0]?.id; return `${d.bills?.length} bill`; });
  await check('POST /pos/table-sessions/:id/add-items (gọi món)', async () => { await api(cashier, 'POST', `/pos/table-sessions/${sid}/add-items`, { items: [{ variantId, quantity: 2 }] }); });
  await check('POST /pos/table-sessions/:id/split-bill (tách bill)', async () => {
    const d = await api(cashier, 'GET', `/pos/table-sessions/${sid}`);
    const bill = d.bills.find(b => b.items?.length); const it = bill.items[0];
    await api(cashier, 'POST', `/pos/table-sessions/${sid}/split-bill`, { billId: bill.id, items: [{ billItemId: it.id, quantity: 1 }] });
    return 'đã tách 1 món';
  });
  await check('POST /pos/table-sessions/:id/merge-bills (gộp bill)', async () => {
    const d = await api(cashier, 'GET', `/pos/table-sessions/${sid}`);
    const active = d.bills.filter(b => ['DRAFT', 'SENT_TO_BAR_UNPAID', 'PENDING_PAYMENT'].includes(b.status));
    if (active.length < 2) return 'bỏ qua (chưa đủ 2 bill)';
    await api(cashier, 'POST', `/pos/table-sessions/${sid}/merge-bills`, { billIds: active.map(b => b.id) });
    return `gộp ${active.length} bill`;
  });
  await check('Chuyển bàn (transfer) tới bàn trống', async () => {
    const dest = areaTables.filter(t => t.status === 'EMPTY')[1] || emptyTable();
    if (!dest) return 'bỏ qua (không có bàn trống khác)';
    await api(cashier, 'POST', `/pos/table-sessions/${sid}/transfer`, { toTableId: dest.id }); return 'đã chuyển';
  });
  await check('POST /pos/table-sessions/:id/close (đóng bàn)', async () => {
    try { await api(cashier, 'POST', `/pos/table-sessions/${sid}/close`); return 'đã đóng'; }
    catch (e) { if (/chưa thanh toán|unpaid|settle/i.test(e.message)) return 'còn bill chưa trả (đúng nghiệp vụ)'; throw e; }
  });

  section('KDS / BAR (barista)');
  await check('GET /kds/tickets (hàng chờ)', async () => { const t = await api(barista, 'GET', '/kds/tickets'); return `${t.length} ticket`; });
  await check('GET /kds/stats', async () => { const s = await api(barista, 'GET', '/kds/stats'); return `chờ ${s.waiting} · pha ${s.preparing} · xong ${s.completed}`; });
  await check('GET /kds/tickets?status=SERVED (đã hoàn thành)', async () => { const t = await api(barista, 'GET', '/kds/tickets?status=SERVED'); return `${t.length} đơn`; });
  await check('Bắt đầu làm + Hoàn thành 1 ticket', async () => {
    const t = await api(barista, 'GET', '/kds/tickets');
    const w = t.find(x => x.status === 'WAITING'); if (!w) return 'không có ticket chờ';
    await api(barista, 'POST', `/kds/tickets/${w.id}/start`);
    await api(barista, 'POST', `/kds/tickets/${w.id}/complete`);
    return `${w.ticketCode} WAITING→hoàn thành`;
  });

  section('ADMIN · Báo cáo');
  await check('GET /admin/reports/sales-summary', async () => { await api(mgr, 'GET', '/admin/reports/sales-summary?range=today'); return 'ok'; });
  await check('GET /admin/reports/shift-summary', async () => { const s = await api(mgr, 'GET', '/admin/reports/shift-summary?from=2026-06-01T00:00:00&to=2026-06-30T23:59:59'); return `${s.length} ca`; });

  section('ADMIN · Duyệt huỷ / hoàn');
  await check('GET /admin/void-refund-requests', async () => { const l = await api(mgr, 'GET', '/admin/void-refund-requests'); return `${l.length} yêu cầu (${l.filter(x => x.status === 'PENDING').length} chờ)`; });
  await check('POST approve/reject 1 yêu cầu PENDING', async () => {
    const l = await api(mgr, 'GET', '/admin/void-refund-requests');
    const p = l.find(x => x.status === 'PENDING'); if (!p) return 'không có pending';
    await api(mgr, 'POST', `/admin/void-refund-requests/${p.id}/reject`, { reason: 'E2E reject' });
    return `đã từ chối ${p.bill?.billCode || p.id.slice(0, 6)}`;
  });

  section('ADMIN · Voucher (CRUD)');
  let vId;
  await check('POST /admin/vouchers (tạo)', async () => { const v = await api(mgr, 'POST', '/admin/vouchers', { code: 'E2E' + Date.now().toString().slice(-6), name: 'E2E voucher', discountType: 'PERCENTAGE', discountValue: 5, minOrderAmount: 0 }); vId = v.id; return v.code; });
  await check('PATCH /admin/vouchers/:id (sửa → Tạm tắt)', async () => { await api(mgr, 'PATCH', `/admin/vouchers/${vId}`, { status: 'INACTIVE' }); });
  await check('GET /admin/vouchers', async () => { const l = await api(mgr, 'GET', '/admin/vouchers'); return `${l.length} mã`; });
  await check('DELETE /admin/vouchers/:id (dọn)', async () => { await api(mgr, 'DELETE', `/admin/vouchers/${vId}`); });

  section('ADMIN · Khu vực & Bàn (CRUD)');
  let aId, tId;
  await check('POST /admin/branches/:b/floor-areas (tạo khu vực)', async () => { const a = await api(mgr, 'POST', `/admin/branches/${branchId}/floor-areas`, { name: 'E2E khu', level: 9 }); aId = a.id; });
  await check('PATCH /admin/floor-areas/:id (sửa)', async () => { await api(mgr, 'PATCH', `/admin/floor-areas/${aId}`, { name: 'E2E khu sửa' }); });
  await check('POST /admin/floor-areas/:id/tables (tạo bàn)', async () => { const t = await api(mgr, 'POST', `/admin/floor-areas/${aId}/tables`, { code: 'E2E1', seats: 4 }); tId = t.id; });
  await check('PATCH /admin/tables/:id (sửa bàn)', async () => { await api(mgr, 'PATCH', `/admin/tables/${tId}`, { seats: 6 }); });
  await check('DELETE bàn + khu vực (dọn)', async () => { await api(mgr, 'DELETE', `/admin/tables/${tId}`); await api(mgr, 'DELETE', `/admin/floor-areas/${aId}`); });

  section('ADMIN · Sổ quỹ ca');
  await check('GET /admin/cash-movements', async () => { const l = await api(mgr, 'GET', '/admin/cash-movements'); return `${l.length} giao dịch (${l.filter(x => x.status === 'PENDING').length} chờ duyệt)`; });

  section('ADMIN · Đơn hàng');
  let someBillId;
  await check('GET /admin/bills (list + summary)', async () => { const r = await api(mgr, 'GET', '/admin/bills?page=1&limit=5'); someBillId = r.items?.[0]?.id; return `${r.summary?.totalBills} đơn · thu ${r.summary?.paidRevenue}đ`; });
  await check('GET /admin/bills/:id (chi tiết)', async () => { const b = await api(mgr, 'GET', `/admin/bills/${someBillId}`); return `${b.items?.length} món`; });
  await check('GET /admin/bills?status=VOIDED (lọc)', async () => { const r = await api(mgr, 'GET', '/admin/bills?status=VOIDED&page=1&limit=5'); return `${r.summary?.totalBills ?? '?'} đơn huỷ`; });

  section('ADMIN · Cấu hình Menu (CRUD)');
  let catId, sizeId, topId;
  await check('Danh mục: tạo → sửa → xoá', async () => { const c = await api(mgr, 'POST', '/admin/product-categories', { name: 'E2E cat', branchId }); catId = c.id; await api(mgr, 'PATCH', `/admin/product-categories/${catId}`, { name: 'E2E cat 2' }); await api(mgr, 'DELETE', `/admin/product-categories/${catId}`); return 'CRUD ok'; });
  await check('Size: tạo → sửa → xoá', async () => { const s = await api(mgr, 'POST', '/admin/sizes', { code: 'E2', name: 'E2E size' }); sizeId = s.id; await api(mgr, 'PATCH', `/admin/sizes/${sizeId}`, { name: 'E2E size 2' }); await api(mgr, 'DELETE', `/admin/sizes/${sizeId}`); return 'CRUD ok'; });
  await check('Topping: tạo → sửa → xoá', async () => { const t = await api(mgr, 'POST', '/admin/toppings', { name: 'E2E top', price: 5000 }); topId = t.id; await api(mgr, 'PATCH', `/admin/toppings/${topId}`, { price: 7000 }); await api(mgr, 'DELETE', `/admin/toppings/${topId}`); return 'CRUD ok'; });

  section('ADMIN · Ca làm việc (đối soát)');
  await check('GET shift-summary + confirm 1 ca PENDING (nếu có)', async () => {
    const ss = await api(mgr, 'GET', '/admin/reports/shift-summary?from=2026-06-01T00:00:00&to=2026-06-30T23:59:59');
    const pc = ss.find(s => s.status === 'PENDING_CONFIRMATION');
    if (!pc) return `${ss.length} ca · không có ca chờ xác nhận`;
    await api(mgr, 'POST', `/admin/shifts/${pc.id}/confirm`); return `xác nhận ${pc.shiftCode}`;
  });

  section('ADMIN · Chi nhánh');
  await check('GET /admin/branches', async () => { const b = await api(mgr, 'GET', '/admin/branches'); return `${b.length} chi nhánh: ${b[0]?.name}`; });
  await check('PATCH /admin/branches/:id (sửa SĐT — round-trip)', async () => { const b = (await api(mgr, 'GET', '/admin/branches'))[0]; const old = b.phone; await api(mgr, 'PATCH', `/admin/branches/${b.id}`, { phone: '0900000000' }); await api(mgr, 'PATCH', `/admin/branches/${b.id}`, { phone: old || '' }); return 'sửa + khôi phục'; });

  section('ADMIN · Thiết bị & Máy in');
  let devId, routeId;
  await check('GET /admin/hardware-devices', async () => { const d = await api(mgr, 'GET', `/admin/hardware-devices?branchId=${branchId}`); return `${d.length} thiết bị`; });
  await check('POST tạo máy in', async () => { const d = await api(mgr, 'POST', '/admin/hardware-devices', { branchId, name: 'E2E máy in', type: 'BILL_PRINTER', connectionType: 'AGENT', config: { printerName: 'XP-80C' } }); devId = d.id; });
  await check('PATCH sửa máy in', async () => { await api(mgr, 'PATCH', `/admin/hardware-devices/${devId}`, { name: 'E2E máy in 2' }); });
  await check('POST test-print (kết quả ok/agent)', async () => { const r = await api(mgr, 'POST', `/admin/hardware-devices/${devId}/test-print`); return r.ok ? 'in OK' : `agent: ${r.status}/${r.error || ''}`.slice(0, 40); });
  await check('GET /admin/print-routes', async () => { const r = await api(mgr, 'GET', `/admin/print-routes?branchId=${branchId}`); return `${r.length} route`; });
  await check('POST tạo route → DELETE', async () => { const r = await api(mgr, 'POST', '/admin/print-routes', { branchId, jobType: 'BILL', hardwareId: devId, isDefault: false }); routeId = r.id; await api(mgr, 'DELETE', `/admin/print-routes/${routeId}`); return 'CRUD ok'; });
  await check('DELETE máy in (dọn)', async () => { await api(mgr, 'DELETE', `/admin/hardware-devices/${devId}`); });
  await check('GET /admin/cash-drawer-events', async () => { const e = await api(mgr, 'GET', `/admin/cash-drawer-events?branchId=${branchId}`); return `${e.length} sự kiện`; });

  section('ADMIN · Audit log + Giám sát đồng bộ');
  await check('GET /admin/audit-logs', async () => { const l = await api(mgr, 'GET', '/admin/audit-logs'); return `${l.length} bản ghi`; });
  await check('GET /admin/sync/devices', async () => { const d = await api(mgr, 'GET', '/admin/sync/devices'); return `${d.length} thiết bị`; });
  await check('GET /admin/sync/conflicts', async () => { const c = await api(mgr, 'GET', '/admin/sync/conflicts'); return `${c.length} conflict`; });

  section('ADMIN · Nhân viên & Kho (đọc/ghi sẵn có)');
  await check('GET /admin/users (nhân viên)', async () => { const u = await api(mgr, 'GET', '/admin/users'); return `${u.length} người`; });
  await check('GET /admin/inventory/balances (tồn kho)', async () => { const b = await api(mgr, 'GET', '/admin/inventory/balances'); return `${b.length} nguyên liệu`; });
  await check('GET /admin/products (sản phẩm)', async () => { const p = await api(mgr, 'GET', '/admin/products'); const n = Array.isArray(p) ? p.length : (p.items?.length ?? 0); return `${n} sản phẩm`; });

  console.log(`\n\x1b[1m================ KẾT QUẢ ================\x1b[0m`);
  console.log(`\x1b[32m✓ PASS: ${pass}\x1b[0m   \x1b[${fail ? 31 : 32}m✗ FAIL: ${fail}\x1b[0m   (tổng ${pass + fail})`);
  if (fails.length) { console.log('\n\x1b[31mCác mục lỗi:\x1b[0m'); fails.forEach(f => console.log('  - ' + f)); }
  process.exit(fail ? 1 : 0);
})().catch(e => { console.error('\x1b[31mFATAL:', e.message, '\x1b[0m'); process.exit(2); });
