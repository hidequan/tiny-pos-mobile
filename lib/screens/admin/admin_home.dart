import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/reports_controller.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../theme/app_icons.dart';
import '../../widgets/common.dart';
import 'admin_widgets.dart';
import 'admin_sheets.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    final r = context.read<ReportsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!r.loaded) r.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final r = context.watch<ReportsController>();
    final p = context.palette;
    final s = r.summary;

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
          IconBtn('bell', dot: r.error != null, onTap: () => r.load()),
          Avatar('AN', onTap: () => openAdminProfile(context)),
        ],
      ),
      Expanded(
        child: RefreshIndicator(
          color: p.terracotta,
          onRefresh: () => r.load(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              HeroCard(
                label: 'Doanh thu hôm nay',
                value: vnd(s.revenue),
                footer: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.receipt_long_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(r.loaded ? '${s.billCount} đơn · ${s.itemsSold} ly hôm nay' : 'Đang tải…',
                      style: AppType.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
              if (r.error != null && !r.loaded)
                _errorBox(context, r)
              else ...[
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
                      StatCard(icon: 'receipt', bg: const Color(0xFFFCE8DF), fg: p.terracotta, value: '${s.billCount}', label: 'Đơn hàng'),
                      StatCard(icon: 'coffee', bg: const Color(0xFFEFE6F7), fg: const Color(0xFF7A4FB0), value: '${s.itemsSold}', label: 'Ly đã bán'),
                      StatCard(icon: 'wallet', bg: p.cream2, fg: p.espresso, value: kShort(s.avgBill), label: 'TB/đơn (AOV)'),
                      StatCard(icon: 'tag', bg: p.greenBg, fg: p.greenD, value: kShort(s.discountTotal), label: 'Giảm giá'),
                    ],
                  ),
                ),
                CardBox(
                  margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    _svcStat(context, '🥡', 'Mang đi', s.takeAway),
                    Container(width: 1, height: 38, color: p.line2),
                    _svcStat(context, '🪑', 'Tại bàn', s.dineIn),
                  ]),
                ),
                SectionHeader('Bán chạy hôm nay', action: 'Báo cáo →', onAction: () => state.setAdminTab('reports')),
                if (r.loading && !r.loaded)
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator(color: p.terracotta)),
                  )
                else if (r.bestSellers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text('Chưa có dữ liệu bán hàng hôm nay.',
                        style: AppType.body(size: 13.5, weight: FontWeight.w600, color: p.muted)),
                  )
                else
                  CardBox(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    clip: true,
                    padding: EdgeInsets.zero,
                    child: RowList([
                      for (var i = 0; i < r.bestSellers.length && i < 5; i++)
                        _topSellRow(context, i, r.bestSellers[i].productName, r.bestSellers[i].quantity, r.bestSellers[i].revenue),
                    ]),
                  ),
              ],
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _errorBox(BuildContext context, ReportsController r) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(children: [
        const Text('📉', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 10),
        Text(r.error!, textAlign: TextAlign.center, style: AppType.body(size: 13, color: p.muted)),
        const SizedBox(height: 14),
        AppButton('Thử lại', icon: 'history', onTap: () => r.load()),
      ]),
    );
  }

  Widget _svcStat(BuildContext context, String emoji, String label, int count) {
    final p = context.palette;
    return Expanded(
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text('$count', style: AppType.display(size: 20, color: p.ink)),
        const SizedBox(height: 2),
        Text(label, style: AppType.body(size: 12, weight: FontWeight.w700, color: p.ink2)),
      ]),
    );
  }

  Widget _topSellRow(BuildContext context, int i, String name, int qty, int revenue) {
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
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 2),
            Text('$qty ly bán ra', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
          ]),
        ),
        const SizedBox(width: 8),
        Text(kShort(revenue), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
      ]),
    );
  }
}
