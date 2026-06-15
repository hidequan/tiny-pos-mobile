import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/bills_controller.dart';
import '../../api/api_client.dart';
import '../../api/bill_repository.dart';
import '../../models/bill.dart';
import '../../services/receipt.dart';
import '../../data/seed.dart' show vnd;
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';

/// Cashier "Đơn hàng" — real bills for the branch (GET /pos/bills).
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const _stMeta = {
    'PAID': [BadgeColor.green, 'Đã thanh toán'],
    'COMPLETED': [BadgeColor.green, 'Hoàn tất'],
    'SENT_TO_BAR_UNPAID': [BadgeColor.amber, 'Gửi bar · chưa TT'],
    'PENDING_PAYMENT': [BadgeColor.amber, 'Chờ thanh toán'],
    'DRAFT': [BadgeColor.gray, 'Nháp'],
    'VOIDED': [BadgeColor.red, 'Đã hủy'],
    'REFUNDED': [BadgeColor.red, 'Hoàn tiền'],
    'PARTIALLY_REFUNDED': [BadgeColor.red, 'Hoàn một phần'],
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ctl = context.watch<BillsController>();
    final p = context.palette;

    if (!ctl.loaded && !ctl.loading && ctl.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ctl.load());
    }

    return Column(children: [
      TopBar(
        title: 'Đơn hàng',
        subtitle: Text('Hôm nay · ${ctl.paidCount} đơn',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [IconBtn('history', onTap: () => ctl.load(force: true))],
      ),
      SearchField(hint: 'Tìm theo mã đơn...', value: state.orderSearch, onChanged: state.setOrderSearch),
      Expanded(child: _body(context, state, ctl)),
    ]);
  }

  Widget _body(BuildContext context, AppState state, BillsController ctl) {
    final p = context.palette;
    if (ctl.loading && !ctl.loaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (ctl.error != null && !ctl.loaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(ctl.error!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => ctl.load(force: true)),
        ]),
      );
    }

    final q = state.orderSearch.trim().toLowerCase();
    final shown = q.isEmpty
        ? ctl.bills
        : ctl.bills.where((b) => b.billCode.toLowerCase().contains(q)).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        HeroCard(
          label: 'Doanh thu (đã thu)',
          value: vnd(ctl.paidRevenue),
          footer: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.trending_up_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text('${ctl.paidCount} đơn hoàn tất', style: AppType.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 6),
        if (shown.isEmpty)
          const EmptyState(emoji: '🧾', title: 'Chưa có đơn', sub: 'Đơn mới sẽ hiện ở đây')
        else ...[
          CardBox(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            clip: true,
            padding: EdgeInsets.zero,
            child: RowList([for (final b in shown) _row(context, b)]),
          ),
          if (q.isEmpty && ctl.hasMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: AppButton(ctl.loadingMore ? 'Đang tải…' : 'Tải thêm', icon: 'history', block: true,
                  variant: BtnVariant.ghost, enabled: !ctl.loadingMore, onTap: () => ctl.loadMore()),
            ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, Bill b) {
    final p = context.palette;
    final meta = _stMeta[b.status] ?? [BadgeColor.gray, b.status];
    return ListRow(
      onTap: () => openBillActions(context, b),
      leading: LeadIcon(
        icon: b.isDineIn ? 'table' : 'coffee',
        bg: b.isDineIn ? p.blueBg : p.cream2,
      ),
      title: b.billCode,
      subtitle: '${b.itemCount} món · ${b.isDineIn ? 'Tại bàn' : 'Mang đi'} · ${_ago(b.createdAt)}',
      trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
        Text(vnd(b.grandTotal),
            style: AppType.body(
              size: 15, weight: FontWeight.w800,
              color: b.status == 'VOIDED' ? p.muted : p.ink,
            ).copyWith(decoration: b.status == 'VOIDED' ? TextDecoration.lineThrough : null)),
        const SizedBox(height: 5),
        AppBadge(meta[1] as String, color: meta[0] as BadgeColor),
      ]),
    );
  }

  String _ago(DateTime? t) {
    if (t == null) return '';
    final mins = DateTime.now().difference(t).inMinutes;
    if (mins < 1) return 'vừa xong';
    if (mins < 60) return '${mins}p trước';
    final h = mins ~/ 60;
    if (h < 24) return '${h}h trước';
    return '${h ~/ 24} ngày trước';
  }
}

// Mirrors order-history-modal.tsx: unpaid bills can be VOID-requested, paid bills
// can be REFUND-requested. Both create a request a Manager approves.
const _kVoidable = ['DRAFT', 'SENT_TO_BAR_UNPAID', 'PENDING_PAYMENT'];
const _kRefundable = ['PAID', 'COMPLETED'];

/// Bill detail + "yêu cầu huỷ / hoàn tiền" sheet (ported from the web order
/// history modal). Cashier submits a request; a Manager approves it later.
void openBillActions(BuildContext context, Bill b) {
  context.shell.showSheet((_) => _BillActionSheet(bill: b));
}

class _BillActionSheet extends StatefulWidget {
  final Bill bill;
  const _BillActionSheet({required this.bill});
  @override
  State<_BillActionSheet> createState() => _BillActionSheetState();
}

class _BillActionSheetState extends State<_BillActionSheet> {
  final TextEditingController _reason = TextEditingController();
  String _mode = 'none'; // none | void | refund
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final b = widget.bill;
    final canVoid = _kVoidable.contains(b.status);
    final canRefund = _kRefundable.contains(b.status);
    final meta = OrdersScreen._stMeta[b.status] ?? [BadgeColor.gray, b.status];
    final canAct = canVoid || canRefund;
    final reasonOk = _reason.text.trim().length >= 2;

    return AppSheet(
      title: b.billCode,
      headerExtra: [AppBadge(meta[1] as String, color: meta[0] as BadgeColor)],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 10),
            child: Text(
              '${b.isDineIn ? 'Tại bàn' : 'Mang đi'} · ${_fmtTime(b.createdAt)}',
              style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.muted),
            ),
          ),
          CardBox(
            radius: 14,
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              for (final it in b.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${it.quantity}×', style: AppType.body(size: 13.5, weight: FontWeight.w800, color: p.terracotta)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(it.productName, style: AppType.body(size: 14, weight: FontWeight.w600, color: p.ink)),
                    ),
                    Text(vnd(it.lineTotal), style: AppType.body(size: 13.5, weight: FontWeight.w700, color: p.ink2)),
                  ]),
                ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line2))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Tổng cộng', style: AppType.body(size: 15, weight: FontWeight.w800, color: p.ink)),
                  Text(vnd(b.grandTotal), style: AppType.display(size: 18, color: p.ink)),
                ]),
              ),
            ]),
          ),
          if (b.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AppButton('In lại bill', icon: 'print', block: true, variant: BtnVariant.ghost,
                  onTap: () => _printBill(context, b)),
            ),
          if (!canAct)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text('Đơn này không thể huỷ hoặc hoàn tiền.',
                  style: AppType.body(size: 13, weight: FontWeight.w600, color: p.muted)),
            ),
          if (_mode != 'none') ...[
            const SizedBox(height: 14),
            Text(_mode == 'void' ? 'Lý do huỷ đơn' : 'Lý do hoàn tiền (${vnd(b.grandTotal)})',
                style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              onChanged: (_) => setState(() {}),
              maxLines: 2,
              style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink),
              decoration: InputDecoration(
                hintText: 'VD: khách đổi ý, pha sai, đồ lỗi…',
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
          ],
        ],
      ),
      footer: _footer(context, p, canVoid, canRefund, canAct, reasonOk),
    );
  }

  Widget? _footer(BuildContext context, Palette p, bool canVoid, bool canRefund, bool canAct, bool reasonOk) {
    if (!canAct) return null;
    if (_mode == 'none') {
      final buttons = <Widget>[
        if (canVoid)
          Expanded(
            child: AppButton('Yêu cầu huỷ', icon: 'edit', large: true, block: true,
                variant: BtnVariant.ghost, textColor: p.red,
                onTap: () => setState(() => _mode = 'void')),
          ),
        if (canRefund)
          Expanded(
            child: AppButton('Yêu cầu hoàn tiền', icon: 'history', large: true, block: true,
                variant: BtnVariant.ghost, textColor: p.amber,
                onTap: () => setState(() => _mode = 'refund')),
          ),
      ];
      return Row(children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          buttons[i],
        ],
      ]);
    }
    return Row(children: [
      AppButton('Quay lại', large: true, variant: BtnVariant.soft,
          onTap: _busy ? null : () => setState(() => _mode = 'none')),
      const SizedBox(width: 10),
      Expanded(
        child: AppButton(
          _busy ? 'Đang gửi...' : 'Gửi yêu cầu',
          icon: 'check',
          large: true,
          block: true,
          enabled: reasonOk && !_busy,
          onTap: () => _submit(context),
        ),
      ),
    ]);
  }

  Future<void> _submit(BuildContext context) async {
    final reason = _reason.text.trim();
    if (reason.length < 2) return;
    final b = widget.bill;
    final repo = context.read<BillRepository>();
    setState(() => _busy = true);
    try {
      if (_mode == 'void') {
        await repo.voidRequest(b.id, reason);
      } else {
        await repo.refundRequest(b.id, amount: b.grandTotal, reason: reason);
      }
      if (!context.mounted) return;
      context.shell.closeSheet();
      context.read<BillsController>().load(force: true);
      context.shell.toast(
          'Đã gửi yêu cầu ${_mode == 'void' ? 'huỷ' : 'hoàn tiền'} đơn ${b.billCode} — chờ quản lý duyệt',
          'check');
    } on ApiException catch (e) {
      if (!context.mounted) return;
      setState(() => _busy = false);
      context.shell.toast(e.message, 'edit');
    } catch (_) {
      if (!context.mounted) return;
      setState(() => _busy = false);
      context.shell.toast('Gửi yêu cầu thất bại. Thử lại.', 'edit');
    }
  }

  Future<void> _printBill(BuildContext context, Bill b) async {
    try {
      await ReceiptService.printReceipt(b, method: b.isPaid ? 'cash' : '', received: 0);
    } catch (_) {
      if (context.mounted) context.shell.toast('Không mở được bản in', 'edit');
    }
  }

  String _fmtTime(DateTime? t) {
    if (t == null) return '';
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)} ${two(l.day)}/${two(l.month)}';
  }
}
