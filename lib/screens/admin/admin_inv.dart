import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';

class AdminInvScreen extends StatelessWidget {
  const AdminInvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    final low = state.inventory.where((i) => i.qty / i.max < 0.4).toList();

    return Column(children: [
      TopBar(
        title: 'Kho hàng',
        subtitle: Text('${state.inventory.length} nguyên liệu · ${low.length} cảnh báo',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [
          IconBtn('plus', iconSize: 22, onTap: () => context.shell.toast('Tạo phiếu nhập kho', 'plus')),
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
        child: state.invTab == 'stock' ? _stock(context, state, low) : _bom(context),
      ),
    ]);
  }

  Widget _stock(BuildContext context, AppState state, List low) {
    final p = context.palette;
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
            for (var k = 0; k < state.inventory.length; k++) _stockRow(context, state.inventory[k], k > 0),
          ]),
        ),
      ],
    );
  }

  Widget _stockRow(BuildContext context, item, bool border) {
    final p = context.palette;
    final pct = (item.qty / item.max * 100).round();
    final col = pct < 20 ? p.red : (pct < 40 ? p.amber : p.greenD);
    final barCol = pct < 20 ? p.red : (pct < 40 ? p.amber : p.green);
    return Container(
      color: p.paper,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(border: border ? Border(top: BorderSide(color: p.line)) : null),
      child: Column(children: [
        Row(children: [
          LeadIcon(emoji: item.emoji, size: 38),
          const SizedBox(width: 11),
          Expanded(child: Text(item.name, style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink))),
          Text(_fmtQty(item.qty), style: AppType.body(size: 14, weight: FontWeight.w800, color: col)),
          Text('/${_fmtQty(item.max)} ${item.unit}', style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted)),
        ]),
        const SizedBox(height: 8),
        Container(
          height: 7,
          decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (pct / 100).clamp(0, 1).toDouble(),
            child: Container(decoration: BoxDecoration(color: barCol, borderRadius: BorderRadius.circular(4))),
          ),
        ),
      ]),
    );
  }

  String _fmtQty(num n) => n % 1 == 0 ? n.toInt().toString() : n.toString();

  Widget _bom(BuildContext context) {
    final p = context.palette;
    final bom = Seed.bom();
    return ListView(
      padding: const EdgeInsets.only(top: 6, bottom: 22),
      children: [
        for (final r in bom) ...[
          SectionHeader(r.product, titleSize: 15.5),
          CardBox(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            clip: true,
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final it in r.items)
                KvRow(it[0], Text(it[1], style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)),
                    last: r.items.last == it, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11)),
            ]),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppButton('Thêm công thức', icon: 'plus', block: true, variant: BtnVariant.ghost,
              onTap: () => context.shell.toast('Thêm công thức định lượng', 'plus')),
        ),
      ],
    );
  }
}
