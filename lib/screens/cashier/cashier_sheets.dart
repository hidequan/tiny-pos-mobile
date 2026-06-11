import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../state/app_state.dart';
import '../../state/session.dart';
import '../../state/tables_controller.dart';
import '../../api/bill_repository.dart';
import '../../api/api_client.dart';
import '../../models/bill.dart';
import '../../data/models.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../theme/app_icons.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'option_pill.dart';

/// Tap a product: directly add (no options) or open the options sheet.
void tapProduct(BuildContext context, Product p) {
  final state = context.read<AppState>();
  if (!p.opt) {
    state.addSimple(p);
    context.shell.toast('${p.name} đã thêm', 'check');
    return;
  }
  state.startDraft(p.id);
  context.shell.showSheet((_) => const _ProductSheet());
}

/// Product options sheet (size / sugar / ice / topping / note + qty).
class _ProductSheet extends StatefulWidget {
  const _ProductSheet();
  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final p = context.palette;
        final product = state.products.firstWhere((x) => x.id == state.draftPid);
        final unit = state.draftUnitPrice();

        Widget group(String label, {Widget? trailing, required Widget child}) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(children: [
                      Text(label, style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink)),
                      if (trailing != null) ...[const SizedBox(width: 8), trailing],
                    ]),
                  ),
                  child,
                ],
              ),
            );

        return AppSheet(
          title: product.name,
          headerExtra: const [],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(13)),
                  alignment: Alignment.center,
                  child: Text(product.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ]),
              group(
                'Kích cỡ',
                trailing: Text('Bắt buộc', style: AppType.body(size: 11, weight: FontWeight.w700, color: p.terracotta)),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < Seed.sizeOpts.length; i++)
                    OptionPill(
                      label: Seed.sizeOpts[i].name,
                      price: Seed.sizeOpts[i].price,
                      on: state.draftSize == i,
                      onTap: () => state.draftSet('size', i),
                    ),
                ]),
              ),
              group('Đường',
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    for (var i = 0; i < Seed.sugarOpts.length; i++)
                      OptionPill(label: Seed.sugarOpts[i].name, on: state.draftSugar == i, onTap: () => state.draftSet('sugar', i)),
                  ])),
              group('Đá',
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    for (var i = 0; i < Seed.iceOpts.length; i++)
                      OptionPill(label: Seed.iceOpts[i].name, on: state.draftIce == i, onTap: () => state.draftSet('ice', i)),
                  ])),
              group(
                'Topping',
                trailing: Text('chọn nhiều', style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted)),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < Seed.topOpts.length; i++)
                    OptionPill(
                      label: Seed.topOpts[i].name,
                      price: Seed.topOpts[i].price,
                      on: state.draftTops.contains(i),
                      onTap: () => state.draftToggleTop(i),
                    ),
                ]),
              ),
              group(
                'Ghi chú',
                child: TextField(
                  controller: _note,
                  onChanged: (v) => state.draftNote = v,
                  maxLines: 2,
                  style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink),
                  decoration: InputDecoration(
                    hintText: 'VD: ít ngọt, mang theo ống hút...',
                    hintStyle: AppType.body(size: 14.5, weight: FontWeight.w500, color: p.faint),
                    filled: true,
                    fillColor: p.paper,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
                  ),
                ),
              ),
            ],
          ),
          footer: Row(
            children: [
              QtyStepper(value: state.draftQty, onChange: state.draftSetQty),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  'Thêm · ${vnd(unit * state.draftQty)}',
                  variant: BtnVariant.pri,
                  onTap: () {
                    state.confirmDraft();
                    context.shell.closeSheet();
                    context.shell.toast('${product.name} đã thêm vào đơn', 'check');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Current order (cart) sheet.
void openCart(BuildContext context) {
  final state = context.read<AppState>();
  if (state.cartCount == 0) return;
  context.shell.showSheet((_) => const _CartSheet());
}

class _CartSheet extends StatelessWidget {
  const _CartSheet();
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final p = context.palette;
        final sub = state.cartSubtotal;
        final tot = state.cartSubtotal;
        final tables = context.watch<TablesController>();
        final dineIn = tables.hasActiveSession;

        if (state.cart.isEmpty) {
          // Auto-close when emptied.
          WidgetsBinding.instance.addPostFrameCallback((_) => context.shell.closeSheet());
        }

        return AppSheet(
          title: dineIn ? 'Gọi món · Bàn ${tables.activeTableLabel}' : 'Đơn hàng hiện tại',
          headerExtra: [
            GestureDetector(
              onTap: () {
                state.clearCart();
                context.shell.closeSheet();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: p.redBg, borderRadius: BorderRadius.circular(10)),
                child: Text('Xóa', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.red)),
              ),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dineIn) ...[
                CardBox(
                  radius: 14,
                  padding: const EdgeInsets.all(13),
                  child: Row(children: [
                    LeadIcon(icon: 'table'),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text('Phục vụ tại Bàn ${tables.activeTableLabel}',
                            style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
                        const SizedBox(height: 2),
                        Text('Món sẽ được gửi thẳng xuống Bar',
                            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () {
                        tables.clearActive();
                        context.shell.toast('Đã rời bàn — chuyển sang mang đi', 'coffee');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(10)),
                        child: Text('Rời', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
                      ),
                    ),
                  ]),
                ),
              ] else
                Segmented(
                  labels: ['Mang đi', 'Tại bàn${state.table != null ? ' · ${state.table}' : ''}'],
                  icons: const ['coffee', 'table'],
                  active: state.otype == 'takeaway' ? 0 : 1,
                  onTap: (i) {
                    if (i == 1) {
                      context.shell.closeSheet();
                      state.setCashTab('tables');
                      context.shell.toast('Chọn bàn cho đơn tại chỗ', 'table');
                    } else {
                      state.setOtype('takeaway');
                    }
                  },
                ),
              const SizedBox(height: 8),
              for (final c in state.cart) _cartLine(context, state, c, p),
              const SizedBox(height: 14),
              if (!dineIn)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('Mã giảm giá áp dụng ở bước thanh toán.',
                      style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.muted)),
                ),
              _totRow(context, 'Tạm tính', vnd(sub)),
              _totRowBig(context, 'Tổng cộng', vnd(tot)),
            ],
          ),
          footer: dineIn
              ? AppButton(
                  state.checkoutBusy ? 'Đang gửi...' : 'Gửi món vào bàn · ${vnd(tot)}',
                  icon: 'table',
                  large: true,
                  block: true,
                  enabled: !state.checkoutBusy,
                  onTap: () => _sendToTable(context, state, tables),
                )
              : AppButton(
                  state.checkoutBusy ? 'Đang mở...' : 'Thanh toán · ${vnd(tot)}',
                  icon: 'card',
                  large: true,
                  block: true,
                  enabled: !state.checkoutBusy,
                  onTap: () => openPay(context, tot),
                ),
        );
      },
    );
  }

  Future<void> _sendToTable(BuildContext context, AppState state, TablesController tables) async {
    final sessionId = tables.activeSessionId;
    if (sessionId == null) return;
    final items = state.cartAsBillItems();
    if (items.isEmpty) {
      context.shell.toast('Không gửi được (món thiếu mã)', 'edit');
      return;
    }
    final label = tables.activeTableLabel;
    state.setCheckoutBusy(true);
    try {
      await tables.addItems(sessionId, items);
      if (!context.mounted) return;
      state.clearAfterCheckout();
      tables.clearActive();
      context.shell.closeSheet();
      state.setCashTab('tables');
      context.shell.toast('Đã gửi món vào Bàn $label', 'check');
    } on ApiException catch (e) {
      if (!context.mounted) return;
      state.setCheckoutBusy(false);
      context.shell.toast(e.message, 'edit');
    } catch (_) {
      if (!context.mounted) return;
      state.setCheckoutBusy(false);
      context.shell.toast('Lỗi gửi món. Thử lại.', 'edit');
    }
  }

  Widget _cartLine(BuildContext context, AppState state, CartLine c, Palette p) {
    final mod = c.mods.text;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(c.emoji, style: const TextStyle(fontSize: 21)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(c.name, style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
              if (mod.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(mod, style: AppType.body(size: 12, weight: FontWeight.w500, color: p.ink2, height: 1.35)),
              ],
              const SizedBox(height: 6),
              Text(vnd(c.price * c.qty), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)),
            ]),
          ),
          QtyStepper(value: c.qty, small: true, onChange: (d) => state.cartQty(c.lid, d)),
        ],
      ),
    );
  }

  Widget _totRow(BuildContext context, String label, String value, {Color? color}) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppType.body(size: 14, weight: FontWeight.w600, color: color ?? p.ink2)),
        Text(value, style: AppType.body(size: 14, weight: FontWeight.w600, color: color ?? p.ink2)),
      ]),
    );
  }

  Widget _totRowBig(BuildContext context, String label, String value) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line2, style: BorderStyle.solid))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppType.body(size: 19, weight: FontWeight.w800, color: p.ink)),
        Text(value, style: AppType.display(size: 19, color: p.ink)),
      ]),
    );
  }
}

/// Open payment: create the real DRAFT bill first (so vouchers can apply and
/// the sheet shows the server total), then show the pay sheet.
Future<void> openPay(BuildContext context, int total) async {
  final state = context.read<AppState>();
  final repo = context.read<BillRepository>();
  final items = state.cartAsBillItems();
  if (items.isEmpty) {
    context.shell.toast('Không tạo được hoá đơn (món thiếu mã)', 'edit');
    return;
  }
  state.openPay(total);
  state.setCheckoutBusy(true);
  try {
    final bill = await repo.createBill(serviceType: 'TAKE_AWAY', items: items);
    if (!context.mounted) return;
    state.setCheckoutBusy(false);
    state.setPayBill(bill);
    context.shell.showSheet((_) => const _PaySheet());
  } on ApiException catch (e) {
    if (!context.mounted) return;
    state.setCheckoutBusy(false);
    context.shell.toast(e.message, 'edit');
  } catch (_) {
    if (!context.mounted) return;
    state.setCheckoutBusy(false);
    context.shell.toast('Lỗi mở thanh toán. Thử lại.', 'edit');
  }
}

class _PaySheet extends StatefulWidget {
  const _PaySheet();
  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  final TextEditingController _voucher = TextEditingController();
  bool _voucherBusy = false;

  @override
  void dispose() {
    _voucher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final p = context.palette;
        final t = state.payBill?.grandTotal ?? state.payTotal;
        final discount = state.payBill?.discountTotal ?? 0;
        final methods = [
          ['cash', 'Tiền mặt', 'cash'],
          ['qr', 'Chuyển khoản / QR', 'qr'],
          ['card', 'Thẻ ngân hàng', 'card'],
          ['momo', 'Ví MoMo', 'wallet'],
        ];
        final quick = <int>{t, ((t / 50000).ceil()) * 50000, ((t / 100000).ceil()) * 100000, 500000}.toList();
        final change = state.received - t;

        return AppSheet(
          title: 'Thanh toán',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
                  child: Column(children: [
                    Text('Tổng cần thu', style: AppType.body(size: 13, weight: FontWeight.w700, color: p.muted)),
                    Text(vnd(t), style: AppType.display(size: 38, color: p.terracotta)),
                    if (discount > 0)
                      Text('Đã giảm ${vnd(discount)}${state.appliedVoucher != null ? ' · ${state.appliedVoucher}' : ''}',
                          style: AppType.body(size: 12.5, weight: FontWeight.w700, color: p.greenD)),
                  ]),
                ),
              ),
              _voucherSection(context, state),
              const SizedBox(height: 14),
              Text('Phương thức', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
              const SizedBox(height: 7),
              for (final m in methods) ...[
                _payMethod(context, state, m[0], m[1], m[2]),
                const SizedBox(height: 8),
              ],
              if (state.payMethod == 'cash') ...[
                const SizedBox(height: 6),
                Text('Tiền khách đưa', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final v in quick)
                    OptionPill(label: vnd(v), on: state.received == v, onTap: () => state.setReceived(v)),
                ]),
                if (state.received > 0) ...[
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Tiền thối lại', style: AppType.body(size: 19, weight: FontWeight.w800, color: p.ink)),
                    Text(vnd(change < 0 ? 0 : change),
                        style: AppType.display(size: 19, color: change >= 0 ? p.greenD : p.red)),
                  ]),
                ],
              ] else if (state.payMethod == 'qr') ...[
                const SizedBox(height: 14),
                Center(
                  child: Column(children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: p.paper,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.line),
                      ),
                      child: Icon(AppIcons.get('qr'), size: 92, color: p.ink),
                    ),
                    const SizedBox(height: 10),
                    Text('Khách quét mã VietQR để chuyển khoản',
                        style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.muted)),
                  ]),
                ),
              ] else ...[
                EmptyState(
                  emoji: state.payMethod == 'card' ? '💳' : '📱',
                  title: 'Chờ xác nhận giao dịch',
                  sub: 'Quẹt thẻ / quét mã trên thiết bị',
                ),
              ],
            ],
          ),
          footer: AppButton(
            state.checkoutBusy ? 'Đang xử lý...' : 'Hoàn tất đơn hàng',
            icon: 'check',
            large: true,
            block: true,
            enabled: !state.checkoutBusy && !(state.payMethod == 'cash' && state.received < t),
            onTap: () => _complete(context, state),
          ),
        );
      },
    );
  }

  Widget _voucherSection(BuildContext context, AppState state) {
    final p = context.palette;
    if (state.appliedVoucher != null) {
      return CardBox(
        radius: 14,
        color: p.greenBg,
        borderColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(children: [
          const Text('🎟️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Đã áp mã ${state.appliedVoucher}',
                style: AppType.body(size: 14, weight: FontWeight.w800, color: p.greenD)),
          ),
          GestureDetector(
            onTap: _voucherBusy ? null : () => _removeVoucher(context, state),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(9)),
              child: Text(_voucherBusy ? '...' : 'Gỡ', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
            ),
          ),
        ]),
      );
    }
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _voucher,
          textCapitalization: TextCapitalization.characters,
          style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink),
          decoration: InputDecoration(
            hintText: 'Mã giảm giá',
            hintStyle: AppType.body(size: 14.5, weight: FontWeight.w500, color: p.faint),
            filled: true,
            fillColor: p.paper,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      AppButton(_voucherBusy ? '...' : 'Áp dụng', variant: BtnVariant.dark,
          onTap: _voucherBusy ? null : () => _applyVoucher(context, state)),
    ]);
  }

  Future<void> _applyVoucher(BuildContext context, AppState state) async {
    final code = _voucher.text.trim().toUpperCase();
    final bill = state.payBill;
    if (code.isEmpty || bill == null) return;
    setState(() => _voucherBusy = true);
    final repo = context.read<BillRepository>();
    try {
      final updated = await repo.applyVoucher(bill.id, code);
      if (!context.mounted) return;
      state.setPayBill(updated, voucher: code);
      _voucher.clear();
      context.shell.toast('Đã áp mã $code', 'tag');
    } on ApiException catch (e) {
      if (context.mounted) context.shell.toast(e.message, 'edit');
    } catch (_) {
      if (context.mounted) context.shell.toast('Mã không hợp lệ', 'edit');
    }
    if (mounted) setState(() => _voucherBusy = false);
  }

  Future<void> _removeVoucher(BuildContext context, AppState state) async {
    final bill = state.payBill;
    if (bill == null) return;
    setState(() => _voucherBusy = true);
    final repo = context.read<BillRepository>();
    try {
      final updated = await repo.removeVoucher(bill.id);
      if (!context.mounted) return;
      state.setPayBill(updated, voucher: null);
    } on ApiException catch (e) {
      if (context.mounted) context.shell.toast(e.message, 'edit');
    } catch (_) {/* ignore */}
    if (mounted) setState(() => _voucherBusy = false);
  }

  Widget _payMethod(BuildContext context, AppState state, String key, String label, String icon) {
    final p = context.palette;
    final on = state.payMethod == key;
    return GestureDetector(
      onTap: () => state.setPay(key),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: on ? (p.isDark ? const Color(0x1FC75B39) : const Color(0xFFFDF1EC)) : p.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? p.terracotta : p.line),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: on ? p.terracotta : p.cream2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(AppIcons.get(icon), size: 20, color: on ? Colors.white : p.ink),
          ),
          const SizedBox(width: 13),
          Expanded(child: Text(label, style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink))),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: on ? p.terracotta : p.line2, width: 2),
            ),
            child: on ? Icon(Icons.check_rounded, size: 13, color: p.terracotta) : null,
          ),
        ]),
      ),
    );
  }

  void _complete(BuildContext context, AppState state) {
    // Cash + QR go through the REAL shared backend. Card/MoMo keep the local
    // flow until their gateway endpoints are wired.
    if (state.payMethod == 'cash') {
      _completeCash(context, state);
      return;
    }
    if (state.payMethod == 'qr') {
      _completeQr(context, state);
      return;
    }
    final tot = state.cartTotal;
    final method = state.payMethod;
    final received = state.received;
    final otype = state.otype;
    final table = state.table;
    final code = state.completeOrder();
    context.shell.showSheet((_) => _SuccessSheet(
          code: code, total: tot, method: method, received: received, otype: otype, table: table));
  }

  Future<void> _completeCash(BuildContext context, AppState state) async {
    final repo = context.read<BillRepository>();
    final received = state.received;
    final bill = state.payBill;
    if (bill == null) {
      context.shell.toast('Chưa có hoá đơn. Thử lại.', 'edit');
      return;
    }
    state.setCheckoutBusy(true);
    try {
      final paid = await repo.payCash(bill.id, received: received);
      if (!context.mounted) return;
      state.clearAfterCheckout();
      context.shell.showSheet((_) => _SuccessSheet(
            code: paid.billCode,
            total: paid.grandTotal,
            method: 'cash',
            received: received,
            otype: 'takeaway',
            table: null,
          ));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      state.setCheckoutBusy(false);
      context.shell.toast(e.message, 'edit');
    } catch (_) {
      if (!context.mounted) return;
      state.setCheckoutBusy(false);
      context.shell.toast('Lỗi thanh toán. Thử lại.', 'edit');
    }
  }

  Future<void> _completeQr(BuildContext context, AppState state) async {
    final repo = context.read<BillRepository>();
    final bill = state.payBill;
    if (bill == null) {
      context.shell.toast('Chưa có hoá đơn. Thử lại.', 'edit');
      return;
    }
    state.setCheckoutBusy(true);
    try {
      final qr = await repo.createQr(bill.id);
      if (!context.mounted) return;
      state.setCheckoutBusy(false);
      context.shell.showSheet((_) => _QrPaySheet(qr: qr, billCode: bill.billCode));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      state.setCheckoutBusy(false);
      context.shell.toast(e.message, 'edit');
    } catch (_) {
      if (!context.mounted) return;
      state.setCheckoutBusy(false);
      context.shell.toast('Lỗi tạo mã QR. Thử lại.', 'edit');
    }
  }
}

/// Real dynamic-QR sheet: shows the VietQR payload + reference, then confirms
/// the transfer manually (cashier saw the money land) via the shared backend.
class _QrPaySheet extends StatefulWidget {
  final QrPayment qr;
  final String billCode;
  const _QrPaySheet({required this.qr, required this.billCode});
  @override
  State<_QrPaySheet> createState() => _QrPaySheetState();
}

class _QrPaySheetState extends State<_QrPaySheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final qr = widget.qr;
    return AppSheet(
      title: 'Chuyển khoản / QR',
      headerExtra: [AppBadge('Chờ thu', color: BadgeColor.amber)],
      body: Column(children: [
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.line),
          ),
          child: SizedBox(
            width: 190,
            height: 190,
            child: QrImageView(
              data: qr.qrPayload.isNotEmpty ? qr.qrPayload : qr.referenceCode,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(vnd(qr.amount), style: AppType.display(size: 30, color: p.terracotta)),
        const SizedBox(height: 4),
        Text('Khách quét mã VietQR để chuyển khoản',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.muted)),
        const SizedBox(height: 12),
        CardBox(
          radius: 14,
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            KvRow('Mã đơn', Text(widget.billCode, style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
            KvRow('Nội dung CK', Text(qr.referenceCode, style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)), last: true),
          ]),
        ),
      ]),
      footer: AppButton(
        _busy ? 'Đang xác nhận...' : 'Khách đã chuyển khoản',
        icon: 'check',
        large: true,
        block: true,
        enabled: !_busy,
        onTap: () => _confirm(context),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    setState(() => _busy = true);
    final repo = context.read<BillRepository>();
    final state = context.read<AppState>();
    try {
      final paid = await repo.confirmPayment(widget.qr.paymentId);
      if (!context.mounted) return;
      state.clearAfterCheckout();
      context.shell.showSheet((_) => _SuccessSheet(
            code: paid.billCode,
            total: paid.grandTotal,
            method: 'qr',
            received: 0,
            otype: 'takeaway',
            table: null,
          ));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      setState(() => _busy = false);
      context.shell.toast(e.message, 'edit');
    } catch (_) {
      if (!context.mounted) return;
      setState(() => _busy = false);
      context.shell.toast('Chưa xác nhận được. Thử lại.', 'edit');
    }
  }
}

class _SuccessSheet extends StatelessWidget {
  final String code;
  final int total;
  final String method;
  final int received;
  final String otype;
  final String? table;
  const _SuccessSheet({
    required this.code,
    required this.total,
    required this.method,
    required this.received,
    required this.otype,
    this.table,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const payLabels = {'cash': 'Tiền mặt', 'qr': 'Chuyển khoản', 'card': 'Thẻ', 'momo': 'MoMo'};
    return AppSheet(
      showClose: false,
      body: Column(
        children: [
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(color: p.greenBg, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, size: 46, color: p.greenD),
            ),
          ),
          const SizedBox(height: 18),
          Text('Thanh toán thành công', style: AppType.display(size: 23, color: p.ink)),
          const SizedBox(height: 6),
          Text('Đơn $code · ${vnd(total)}', style: AppType.body(size: 14, weight: FontWeight.w600, color: p.muted)),
          const SizedBox(height: 18),
          CardBox(
            radius: 14,
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              KvRow('Mã đơn', Text(code, style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
              KvRow('Loại', Text(otype == 'dinein' ? 'Tại bàn ${table ?? ''}' : 'Mang đi',
                  style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
              KvRow('Thanh toán', Text(payLabels[method] ?? '',
                  style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
              if (method == 'cash' && received > 0)
                KvRow('Tiền thối', Text(vnd(received - total),
                    style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
              KvRow('Gửi pha chế',
                  Text('✓ Đã đẩy lên KDS', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.greenD)),
                  last: true),
            ]),
          ),
          const SizedBox(height: 8),
        ],
      ),
      footer: Row(children: [
        Expanded(
          child: AppButton('In bill', icon: 'print', large: true, variant: BtnVariant.ghost, onTap: () {
            context.shell.closeSheet();
            context.read<AppState>().afterPay();
            context.shell.toast('Đang in hóa đơn...', 'print');
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: AppButton('Đơn mới', large: true, onTap: () {
            context.shell.closeSheet();
            context.read<AppState>().afterPay();
          }),
        ),
      ]),
    );
  }
}

/// Cashier account sheet.
void openProfile(BuildContext context) {
  final p0 = context.palette;
  context.shell.showSheet((_) => AppSheet(
        title: 'Tài khoản',
        body: Builder(builder: (context) {
          final p = context.palette;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
              child: Row(children: [
                Avatar('TB', size: 56),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('Trần Thị Bình', style: AppType.body(size: 17, weight: FontWeight.w800, color: p.ink)),
                  const SizedBox(height: 5),
                  const AppBadge('🧾 Thu ngân', color: BadgeColor.blue),
                ]),
              ]),
            ),
            CardBox(
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                ListRow(leading: LeadIcon(icon: 'store'), title: 'Chi nhánh Cầu Giấy', subtitle: '144 Xuân Thủy'),
                ListRow(leading: LeadIcon(icon: 'clock'), title: 'Ca chiều', subtitle: '13:00 – 21:00'),
                Container(
                  color: p.paper,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(children: [
                    LeadIcon(icon: 'settings'),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text('Chế độ tối', style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
                    ),
                    Consumer<AppState>(
                      builder: (_, s, _) => SwitchDot(on: s.userDark, onTap: s.toggleDarkMode),
                    ),
                  ]),
                ),
              ]),
            ),
          ]);
        }),
        footer: AppButton('Đăng xuất / đổi vai trò',
            icon: 'logout', large: true, block: true, variant: BtnVariant.soft, textColor: p0.red, onTap: () {
          context.shell.closeSheet();
          context.read<SessionState>().logout();
        }),
      ));
}
