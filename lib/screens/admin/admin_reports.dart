import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/reports_controller.dart';
import '../../models/report.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_widgets.dart';
import 'admin_sheets.dart';

const _payColors = <String, int>{
  'CASH': 0xFF3F8F5B,
  'QR': 0xFF3B7CC4,
  'CARD': 0xFFD98A4E,
  'WALLET': 0xFF7A4FB0,
  'MOMO': 0xFFB83280,
};

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
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
        title: 'Báo cáo',
        subtitle: Text('${state.adminBranch} · ${r.range.label}',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [
          IconBtn('report', onTap: () => context.shell.toast('Xuất Excel — sắp có', 'report')),
          Avatar('AN', onTap: () => openAdminProfile(context)),
        ],
      ),
      ChipsRow(children: [
        for (final rg in ReportRange.values)
          PillChip(rg.label, on: r.range == rg, onTap: () => r.setRange(rg)),
      ]),
      Expanded(
        child: RefreshIndicator(
          color: p.terracotta,
          onRefresh: () => r.load(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              HeroCard(
                gradient: const [Color(0xFF3A1F12), Color(0xFF241008)],
                label: 'Tổng doanh thu · ${r.range.label}',
                value: vnd(s.revenue),
                footer: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.receipt_long_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('${s.billCount} đơn · TB ${kShort(s.avgBill)}',
                      style: AppType.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
              if (r.error != null && !r.loaded)
                _errorBox(context, r)
              else if (r.loading && !r.loaded)
                Padding(padding: const EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: p.terracotta)))
              else if (s.billCount == 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: CardBox(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text('Chưa có doanh thu trong kỳ "${r.range.label}".',
                          style: AppType.body(size: 13.5, weight: FontWeight.w600, color: p.muted)),
                    ),
                  ),
                )
              else ...[
                const SectionHeader('Cơ cấu thanh toán'),
                _payments(context, r),
                const SectionHeader('Bán chạy nhất'),
                if (r.bestSellers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text('Chưa có dữ liệu món.', style: AppType.body(size: 13.5, weight: FontWeight.w600, color: p.muted)),
                  )
                else
                  CardBox(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    clip: true,
                    padding: EdgeInsets.zero,
                    child: RowList([
                      for (var i = 0; i < r.bestSellers.length && i < 5; i++)
                        _row(context, i, r.bestSellers[i]),
                    ]),
                  ),
              ],
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _payments(BuildContext context, ReportsController r) {
    final p = context.palette;
    if (r.payments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text('Chưa ghi nhận thanh toán.', style: AppType.body(size: 13.5, weight: FontWeight.w600, color: p.muted)),
      );
    }
    final segments = [
      for (final m in r.payments) [m.label, r.sharePct(m), _payColors[m.method] ?? 0xFF8C7A6B],
    ];
    final totalCount = r.payments.fold(0, (a, m) => a + m.count);
    return CardBox(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Donut(segments: segments, center: '100%', centerSub: '$totalCount đơn'),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: [
              for (final m in r.payments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.5),
                  child: Row(children: [
                    Container(width: 11, height: 11,
                        decoration: BoxDecoration(color: Color(_payColors[m.method] ?? 0xFF8C7A6B), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 9),
                    Expanded(child: Text(m.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: AppType.body(size: 13, weight: FontWeight.w700, color: p.ink))),
                    Text('${r.sharePct(m)}%', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
                  ]),
                ),
            ],
          ),
        ),
      ]),
    );
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

  Widget _row(BuildContext context, int i, BestSeller b) {
    final p = context.palette;
    return Container(
      color: p.paper,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        SizedBox(width: 20, child: Text('${i + 1}', style: AppType.display(size: 14, weight: FontWeight.w800, color: i == 0 ? p.terracotta : p.muted))),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(b.productName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 2),
            Text('${b.quantity} ly · ${vnd(b.revenue)}', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
          ]),
        ),
        const SizedBox(width: 8),
        Text(kShort(b.revenue), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
      ]),
    );
  }
}
