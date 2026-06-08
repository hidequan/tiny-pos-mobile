import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../theme/app_icons.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_widgets.dart';
import 'admin_sheets.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    final b = state.curBranch;
    const orders = 142, guests = 168, sold = 312;
    final aov = (b.rev / orders).round();
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final acts = [
      ['receipt', const Color(0xFFFCE8DF), p.terracotta, 'Đơn #1043 · 87.000đ', '2 phút trước'],
      ['box', p.amberBg, p.amber, 'Sữa tươi sắp hết (4/40)', '15 phút trước'],
      ['user', p.greenBg, p.greenD, 'Lê Minh Châu mở ca chiều', '1 giờ trước'],
      ['gift', const Color(0xFFEFE6F7), const Color(0xFF7A4FB0), 'Giờ vàng 14h–16h bắt đầu', '2 giờ trước'],
    ];

    return Column(children: [
      TopBar(
        title: 'Tổng quan',
        subtitle: GestureDetector(
          onTap: () => openBranchPick(context),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(AppIcons.get('store'), size: 13, color: p.ink2),
            const SizedBox(width: 4),
            Text('${state.adminBranch} ▾', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
          ]),
        ),
        actions: [
          IconBtn('bell', onTap: () => context.shell.toast('Không có thông báo mới', 'bell')),
          Avatar('AN', onTap: () => openAdminProfile(context)),
        ],
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            HeroCard(
              label: 'Doanh thu hôm nay',
              value: vnd(b.rev),
              footer: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.trending_up_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text('+12% so với hôm qua', style: AppType.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 118,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(icon: 'receipt', bg: const Color(0xFFFCE8DF), fg: p.terracotta, value: '$orders', label: 'Đơn hàng', delta: '+8%'),
                  StatCard(icon: 'users', bg: p.greenBg, fg: p.greenD, value: '$guests', label: 'Lượt khách', delta: '+5%'),
                  StatCard(icon: 'wallet', bg: p.cream2, fg: p.espresso, value: kShort(aov), label: 'TB/đơn (AOV)', delta: '+3%'),
                  StatCard(icon: 'coffee', bg: const Color(0xFFEFE6F7), fg: const Color(0xFF7A4FB0), value: '$sold', label: 'Ly đã bán', delta: '−2%', up: false),
                ],
              ),
            ),
            CardBox(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 14, 2, 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(child: Text('Doanh thu 7 ngày', style: AppType.display(size: 17, color: p.ink))),
                    Text('đỉnh ${Seed.report7.reduce((a, c) => a > c ? a : c)}tr',
                        style: AppType.body(size: 12, weight: FontWeight.w700, color: p.muted)),
                  ]),
                ),
                const BarChart(values: Seed.report7, labels: days),
              ]),
            ),
            SectionHeader('Bán chạy hôm nay', action: 'Báo cáo →', onAction: () => state.setAdminTab('reports')),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                for (var i = 0; i < 4; i++)
                  _topSellRow(context, i, Seed.topSell[i][0] as String, Seed.topSell[i][1] as int, Seed.topSell[i][2] as int),
              ]),
            ),
            const SectionHeader('Hoạt động gần đây'),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                for (final a in acts)
                  ListRow(
                    leading: LeadIcon(icon: a[0] as String, bg: a[1] as Color, fg: a[2] as Color),
                    title: a[3] as String,
                    subtitle: a[4] as String,
                    titleWeight: FontWeight.w600,
                  ),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _topSellRow(BuildContext context, int i, String name, int qty, int price) {
    final p = context.palette;
    return Container(
      color: p.paper,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        SizedBox(
          width: 20,
          child: Text('${i + 1}', style: AppType.display(size: 14, weight: FontWeight.w800, color: i == 0 ? p.terracotta : p.muted)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(name, style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 2),
            Text('$qty ly bán ra', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
          ]),
        ),
        Text(kShort(qty * price), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
      ]),
    );
  }
}
