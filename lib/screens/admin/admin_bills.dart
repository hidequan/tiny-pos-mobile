import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/admin_data_controller.dart';
import '../../models/admin.dart';
import '../../models/bill.dart';
import '../../data/seed.dart' show vnd;
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_widgets.dart';

const _billStatusLabel = {
  'DRAFT': 'Nháp',
  'SENT_TO_BAR_UNPAID': 'Gửi bar · chưa TT',
  'PENDING_PAYMENT': 'Chờ thu',
  'PAID': 'Đã thanh toán',
  'COMPLETED': 'Hoàn tất',
  'VOIDED': 'Đã huỷ',
  'REFUNDED': 'Đã hoàn',
  'PARTIALLY_REFUNDED': 'Hoàn một phần',
};
const _payLabel = {'cash': 'Tiền mặt', 'qr': 'QR/CK', 'transfer': 'Chuyển khoản', 'card': 'Thẻ', 'momo': 'MoMo'};

BadgeColor _billStatusColor(String s) => switch (s) {
      'PAID' || 'COMPLETED' => BadgeColor.green,
      'SENT_TO_BAR_UNPAID' || 'PENDING_PAYMENT' => BadgeColor.amber,
      'VOIDED' || 'REFUNDED' || 'PARTIALLY_REFUNDED' => BadgeColor.red,
      _ => BadgeColor.gray,
    };

String _fmtTime(DateTime? t) {
  if (t == null) return '';
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)} ${two(l.day)}/${two(l.month)}';
}

/// Đơn hàng (admin) — all bills with filters, summary, pagination + detail.
/// Ported from the web admin/bills page (the stats chart lives in Reports).
class AdminBillsScreen extends StatefulWidget {
  const AdminBillsScreen({super.key});
  @override
  State<AdminBillsScreen> createState() => _AdminBillsScreenState();
}

class _AdminBillsScreenState extends State<AdminBillsScreen> {
  final _searchCtl = TextEditingController();
  Timer? _debounce;

  static const _statusFilters = ['', 'PAID', 'SENT_TO_BAR_UNPAID', 'PENDING_PAYMENT', 'VOIDED', 'REFUNDED'];

  @override
  void initState() {
    super.initState();
    final a = context.read<AdminDataController>();
    _searchCtl.text = a.billSearch;
    WidgetsBinding.instance.addPostFrameCallback((_) => a.ensureBills());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtl.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) context.read<AdminDataController>().setBillSearch(v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    return Column(children: [
      BackBar(title: 'Đơn hàng', sub: a.billsLoaded ? '${a.billsSummary.totalBills} hoá đơn' : 'Đang tải…'),
      Expanded(child: _body(context, a, p)),
    ]);
  }

  Widget _body(BuildContext context, AdminDataController a, Palette p) {
    if (a.billsLoading && !a.billsLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (a.billsError != null && !a.billsLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(a.billsError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => a.loadBills()),
        ]),
      );
    }
    final s = a.billsSummary;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: HeroCard(
            label: 'Doanh thu đã thu',
            value: vnd(s.paidRevenue),
            footer: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.receipt_long_outlined, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text('${s.paidBills}/${s.totalBills} đơn đã thanh toán'
                  '${s.refundedTotal > 0 ? ' · hoàn ${vnd(s.refundedTotal)}' : ''}',
                  style: AppType.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
        ChipsRow(children: [
          for (final f in _statusFilters)
            PillChip(f.isEmpty ? 'Tất cả' : (_billStatusLabel[f] ?? f),
                on: a.billStatusFilter == f, onTap: () => a.setBillStatusFilter(f)),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(children: [
            for (final sv in const [['', 'Tất cả'], ['DINE_IN', 'Tại bàn'], ['TAKE_AWAY', 'Mang đi']]) ...[
              _serviceChip(a, p, sv[0], sv[1]),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        SearchField(hint: 'Tìm mã đơn / khách...', value: _searchCtl.text, onChanged: (v) {
          _searchCtl.text = v;
          _onSearch(v);
        }),
        if (a.bills.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: EmptyState(emoji: '🧾', title: 'Không có hoá đơn', sub: 'Thử đổi bộ lọc hoặc từ khóa'),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(children: [for (final b in a.bills) _row(context, p, b)]),
          ),
          if (a.billsHasMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: AppButton(a.billsLoadingMore ? 'Đang tải…' : 'Tải thêm', icon: 'history', block: true,
                  variant: BtnVariant.ghost, enabled: !a.billsLoadingMore, onTap: () => a.loadBills(reset: false)),
            ),
        ],
      ],
    );
  }

  Widget _serviceChip(AdminDataController a, Palette p, String key, String label) {
    final on = a.billServiceFilter == key;
    return GestureDetector(
      onTap: () => a.setBillServiceFilter(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: on ? p.espresso : p.cream2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: AppType.body(size: 12.5, weight: FontWeight.w800, color: on ? Colors.white : p.ink2)),
      ),
    );
  }

  Widget _row(BuildContext context, Palette p, AdminBill b) {
    final pays = b.paymentMethods.map((m) => _payLabel[m] ?? m).join(', ');
    return GestureDetector(
      onTap: () => _openDetail(context, b),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(b.billCode, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
            const SizedBox(width: 8),
            AppBadge(_billStatusLabel[b.status] ?? b.status, color: _billStatusColor(b.status)),
            const Spacer(),
            Text(vnd(b.grandTotal), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
          ]),
          const SizedBox(height: 4),
          Text(
            '${b.isDineIn ? 'Tại bàn ${b.tableCode ?? ''}' : 'Mang đi'} · ${b.itemCount} món'
            '${b.cashierName != null ? ' · ${b.cashierName}' : ''}'
            '${b.customerName != null ? ' · ${b.customerName}' : ''} · ${_fmtTime(b.createdAt)}'
            '${pays.isNotEmpty ? ' · $pays' : ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted),
          ),
        ]),
      ),
    );
  }

  void _openDetail(BuildContext context, AdminBill b) {
    context.shell.showSheet((_) => _BillDetailSheet(row: b));
  }
}

class _BillDetailSheet extends StatefulWidget {
  final AdminBill row;
  const _BillDetailSheet({required this.row});
  @override
  State<_BillDetailSheet> createState() => _BillDetailSheetState();
}

class _BillDetailSheetState extends State<_BillDetailSheet> {
  Bill? _bill;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await context.read<AdminDataController>().repo.adminBillDetail(widget.row.id);
      if (mounted) setState(() => _bill = b);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được chi tiết');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = widget.row;
    final b = _bill;
    return AppSheet(
      title: r.billCode,
      headerExtra: [AppBadge(_billStatusLabel[r.status] ?? r.status, color: _billStatusColor(r.status))],
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 10),
          child: Text(
            '${r.isDineIn ? 'Tại bàn ${r.tableCode ?? ''}' : 'Mang đi'} · ${_fmtTime(r.createdAt)}'
            '${r.cashierName != null ? '\nThu ngân: ${r.cashierName}' : ''}'
            '${r.customerName != null ? '\nKhách: ${r.customerName}' : ''}',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.muted, height: 1.5),
          ),
        ),
        if (_error != null)
          Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(_error!, style: AppType.body(size: 13, color: p.muted)))
        else if (b == null)
          const Padding(padding: EdgeInsets.symmetric(vertical: 26), child: Center(child: CircularProgressIndicator()))
        else ...[
          CardBox(
            radius: 14,
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              for (final it in b.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${it.quantity}×', style: AppType.body(size: 13.5, weight: FontWeight.w800, color: p.terracotta)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                        it.variantName != null && it.variantName!.isNotEmpty ? '${it.productName} (${it.variantName})' : it.productName,
                        style: AppType.body(size: 14, weight: FontWeight.w600, color: p.ink))),
                    Text(vnd(it.lineTotal), style: AppType.body(size: 13.5, weight: FontWeight.w700, color: p.ink2)),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          _kv(p, 'Tạm tính', vnd(b.subtotal)),
          if (b.discountTotal > 0) _kv(p, 'Giảm giá', '− ${vnd(b.discountTotal)}', color: p.greenD),
          if (r.refundedTotal > 0) _kv(p, 'Đã hoàn', '− ${vnd(r.refundedTotal)}', color: p.red),
          _kv(p, 'Tổng cộng', vnd(b.grandTotal), big: true),
          if (r.paymentMethods.isNotEmpty)
            _kv(p, 'Thanh toán', r.paymentMethods.map((m) => _payLabel[m] ?? m).join(', ')),
        ],
      ]),
    );
  }

  Widget _kv(Palette p, String k, String v, {Color? color, bool big = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: AppType.body(size: big ? 15 : 13.5, weight: big ? FontWeight.w800 : FontWeight.w600, color: big ? p.ink : p.ink2)),
          Text(v, style: AppType.body(size: big ? 16 : 13.5, weight: FontWeight.w800, color: color ?? (big ? p.ink : p.ink2))),
        ]),
      );
}
