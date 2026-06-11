import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/admin_data_controller.dart';
import '../../models/admin.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';

class AdminInvScreen extends StatefulWidget {
  const AdminInvScreen({super.key});
  @override
  State<AdminInvScreen> createState() => _AdminInvScreenState();
}

class _AdminInvScreenState extends State<AdminInvScreen> {
  @override
  void initState() {
    super.initState();
    final a = context.read<AdminDataController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => a.ensureInventory());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final a = context.watch<AdminDataController>();
    final p = context.palette;

    return Column(children: [
      TopBar(
        title: 'Kho hàng',
        subtitle: Text(
          a.invLoaded ? '${a.balances.length} nguyên liệu · ${a.lowStockCount} cảnh báo' : 'Đang tải…',
          style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2),
        ),
        actions: [
          IconBtn('history', iconSize: 20, onTap: () => a.loadInventory()),
          Avatar('AN'),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
        child: Segmented(
          labels: const ['Nguyên liệu', 'Định lượng (BOM)'],
          active: state.invTab == 'stock' ? 0 : 1,
          onTap: (i) => state.setInvTab(i == 0 ? 'stock' : 'bom'),
        ),
      ),
      Expanded(
        child: a.invLoading && !a.invLoaded
            ? Center(child: CircularProgressIndicator(color: p.terracotta))
            : (a.invError != null && !a.invLoaded)
                ? _error(context, a)
                : state.invTab == 'stock'
                    ? _stock(context, a)
                    : _bom(context, a),
      ),
    ]);
  }

  Widget _error(BuildContext context, AdminDataController a) {
    final p = context.palette;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📦', style: TextStyle(fontSize: 42)),
        const SizedBox(height: 10),
        Text(a.invError!, style: AppType.body(size: 13, color: p.muted)),
        const SizedBox(height: 16),
        AppButton('Thử lại', icon: 'history', onTap: () => a.loadInventory()),
      ]),
    );
  }

  Widget _stock(BuildContext context, AdminDataController a) {
    final p = context.palette;
    final low = a.balances.where((b) => b.low).toList();
    if (a.balances.isEmpty) {
      return const EmptyState(emoji: '📦', title: 'Chưa có nguyên liệu', sub: 'Thêm nguyên liệu để theo dõi tồn kho.');
    }
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 22),
      children: [
        if (low.isNotEmpty)
          CardBox(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: p.amberBg,
            borderColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(children: [
              const Text('⚠️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 11),
              Expanded(
                child: Text('${low.length} nguyên liệu dưới ngưỡng an toàn — nên nhập thêm sớm.',
                    style: AppType.body(size: 13, weight: FontWeight.w700, color: p.amber)),
              ),
            ]),
          ),
        const SizedBox(height: 8),
        CardBox(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          clip: true,
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var k = 0; k < a.balances.length; k++) _stockRow(context, a.balances[k], k > 0),
          ]),
        ),
      ],
    );
  }

  Widget _stockRow(BuildContext context, StockBalance item, bool border) {
    final p = context.palette;
    final col = item.low ? p.red : (item.ratio < 0.4 ? p.amber : p.greenD);
    final barCol = item.low ? p.red : (item.ratio < 0.4 ? p.amber : p.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: p.paper,
        border: border ? Border(top: BorderSide(color: p.line)) : null,
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
              const SizedBox(height: 2),
              Text(item.code, style: AppType.body(size: 11.5, weight: FontWeight.w600, color: p.muted)),
            ]),
          ),
          const SizedBox(width: 8),
          Text(_fmt(item.onHand), style: AppType.body(size: 14, weight: FontWeight.w800, color: col)),
          Text(' ${item.unit}', style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted)),
          if (item.low) ...[
            const SizedBox(width: 8),
            const AppBadge('Sắp hết', color: BadgeColor.red),
          ],
        ]),
        const SizedBox(height: 8),
        Container(
          height: 7,
          decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: item.ratio == 0 ? 0.02 : item.ratio,
            child: Container(decoration: BoxDecoration(color: barCol, borderRadius: BorderRadius.circular(4))),
          ),
        ),
        if (item.minStock > 0)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Ngưỡng an toàn: ${_fmt(item.minStock)} ${item.unit}',
                  style: AppType.body(size: 10.5, weight: FontWeight.w600, color: p.muted)),
            ),
          ),
      ]),
    );
  }

  String _fmt(double n) => n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);

  Widget _bom(BuildContext context, AdminDataController a) {
    final p = context.palette;
    if (a.boms.isEmpty) {
      return const EmptyState(emoji: '📐', title: 'Chưa có công thức', sub: 'Định lượng (BOM) cho món/topping sẽ hiện ở đây.');
    }
    return ListView(
      padding: const EdgeInsets.only(top: 6, bottom: 22),
      children: [
        for (final r in a.boms) ...[
          SectionHeader(r.name, titleSize: 15.5),
          CardBox(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            clip: true,
            padding: EdgeInsets.zero,
            child: r.items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text('Chưa có nguyên liệu trong công thức.',
                        style: AppType.body(size: 13, weight: FontWeight.w600, color: p.muted)),
                  )
                : Column(children: [
                    for (var i = 0; i < r.items.length; i++)
                      KvRow(
                        r.items[i].ingredientName,
                        Text('${_fmt(r.items[i].quantity)} ${r.items[i].unit}',
                            style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)),
                        last: i == r.items.length - 1,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                      ),
                  ]),
          ),
        ],
      ],
    );
  }
}
