import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    const stMeta = {
      'done': [BadgeColor.green, 'Hoàn tất'],
      'void': [BadgeColor.red, 'Đã hủy'],
      'pending': [BadgeColor.amber, 'Đang xử lý'],
    };
    const payLabels = {'cash': 'Tiền mặt', 'qr': 'Chuyển khoản', 'card': 'Thẻ', 'momo': 'MoMo'};
    final done = state.orders.where((o) => o.status == 'done').toList();
    final today = done.fold(0, (a, o) => a + o.total);
    final oq = state.orderSearch.trim().toLowerCase();
    final shown = oq.isEmpty
        ? state.orders
        : state.orders
            .where((o) =>
                o.code.toLowerCase().contains(oq) ||
                (o.table ?? '').toLowerCase().contains(oq))
            .toList();

    return Column(children: [
      TopBar(
        title: 'Đơn hàng',
        subtitle: Text('Hôm nay · ${done.length} đơn', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
      ),
      SearchField(
        hint: 'Tìm theo mã đơn / bàn...',
        value: state.orderSearch,
        onChanged: state.setOrderSearch,
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            HeroCard(
              label: 'Doanh thu ca này',
              value: vnd(today),
              footer: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.trending_up_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text('${done.length} đơn hoàn tất', style: AppType.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 6),
            if (shown.isEmpty)
              const EmptyState(emoji: '🔍', title: 'Không tìm thấy đơn', sub: 'Thử mã đơn hoặc số bàn khác')
            else
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                for (final o in shown)
                  ListRow(
                    onTap: () => context.shell.toast('Chi tiết đơn ${o.code}', 'receipt'),
                    leading: LeadIcon(
                      icon: o.type == 'dinein' ? 'table' : 'coffee',
                      bg: o.type == 'dinein' ? p.blueBg : p.cream2,
                    ),
                    title: '${o.code}${o.table != null ? ' · Bàn ${o.table}' : ''}',
                    subtitle: '${o.items} món · ${payLabels[o.pay]} · ${o.min}p trước',
                    trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                      Text(vnd(o.total),
                          style: AppType.body(
                            size: 15,
                            weight: FontWeight.w800,
                            color: o.status == 'void' ? p.muted : p.ink,
                          ).copyWith(decoration: o.status == 'void' ? TextDecoration.lineThrough : null)),
                      const SizedBox(height: 5),
                      AppBadge(stMeta[o.status]![1] as String, color: stMeta[o.status]![0] as BadgeColor),
                    ]),
                  ),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }
}
