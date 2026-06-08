import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_widgets.dart';
import 'admin_sheets.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    const ranges = ['Hôm nay', '7 ngày', 'Tháng này'];
    final total = Seed.report7.fold(0.0, (a, v) => a + v);
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final worst = Seed.topSell.last;

    return Column(children: [
      TopBar(
        title: 'Báo cáo',
        subtitle: Text('${state.adminBranch} · ${state.repRange}',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [
          IconBtn('report', onTap: () => context.shell.toast('Đang xuất Excel...', 'report')),
          Avatar('AN', onTap: () => openAdminProfile(context)),
        ],
      ),
      ChipsRow(children: [
        for (final r in ranges) PillChip(r, on: state.repRange == r, onTap: () => state.setRepRange(r)),
      ]),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            HeroCard(
              gradient: const [Color(0xFF3A1F12), Color(0xFF241008)],
              label: 'Tổng doanh thu · ${state.repRange}',
              value: '${total.toStringAsFixed(1)}tr',
              footer: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.trending_up_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text('+14% so với kỳ trước · 980 đơn', style: AppType.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
            CardBox(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 14, 2, 4),
                  child: Text('Doanh thu theo ngày', style: AppType.display(size: 17, color: p.ink)),
                ),
                const BarChart(values: Seed.report7, labels: days),
              ]),
            ),
            const SectionHeader('Cơ cấu thanh toán'),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Donut(segments: Seed.payMix, center: '100%', centerSub: '980 đơn'),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(children: [
                    for (final m in Seed.payMix)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.5),
                        child: Row(children: [
                          Container(width: 11, height: 11, decoration: BoxDecoration(color: Color(m[2] as int), borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 9),
                          Expanded(child: Text(m[0] as String, style: AppType.body(size: 13, weight: FontWeight.w700, color: p.ink))),
                          Text('${m[1]}%', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
                        ]),
                      ),
                  ]),
                ),
              ]),
            ),
            const SectionHeader('Bán chạy nhất'),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                for (var i = 0; i < 3; i++)
                  _row(context, i, Seed.topSell[i][0] as String, Seed.topSell[i][1] as int, Seed.topSell[i][2] as int),
              ]),
            ),
            const SectionHeader('Cần chú ý'),
            CardBox(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                const Text('🐌', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 11),
                Expanded(
                  child: Text('"${worst[0]}" bán chậm nhất tuần — chỉ ${worst[1]} ly. Cân nhắc khuyến mãi.',
                      style: AppType.body(size: 13.5, weight: FontWeight.w700, color: p.ink)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: AppButton('Xuất báo cáo Excel', icon: 'report', block: true, variant: BtnVariant.dark,
                  onTap: () => context.shell.toast('Đã xuất báo cáo Excel', 'report')),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _row(BuildContext context, int i, String name, int qty, int price) {
    final p = context.palette;
    return Container(
      color: p.paper,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        SizedBox(width: 20, child: Text('${i + 1}', style: AppType.display(size: 14, weight: FontWeight.w800, color: i == 0 ? p.terracotta : p.muted))),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(name, style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 2),
            Text('$qty ly · ${vnd(price)}', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
          ]),
        ),
        Text(kShort(qty * price), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
      ]),
    );
  }
}
