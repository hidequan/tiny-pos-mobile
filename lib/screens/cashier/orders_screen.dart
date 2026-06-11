import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/bills_controller.dart';
import '../../models/bill.dart';
import '../../data/seed.dart' show vnd;
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';

/// Cashier "Đơn hàng" — real bills for the branch (GET /pos/bills).
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const _stMeta = {
    'PAID': [BadgeColor.green, 'Hoàn tất'],
    'SENT_TO_BAR_UNPAID': [BadgeColor.amber, 'Chờ thanh toán'],
    'DRAFT': [BadgeColor.gray, 'Nháp'],
    'VOIDED': [BadgeColor.red, 'Đã hủy'],
    'REFUNDED': [BadgeColor.red, 'Hoàn tiền'],
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
        else
          CardBox(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            clip: true,
            padding: EdgeInsets.zero,
            child: RowList([for (final b in shown) _row(context, b)]),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, Bill b) {
    final p = context.palette;
    final meta = _stMeta[b.status] ?? [BadgeColor.gray, b.status];
    return ListRow(
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
