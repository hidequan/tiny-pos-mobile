import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../data/models.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'cashier_sheets.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  static const _stMeta = {
    'free': [BadgeColor.green, 'Trống'],
    'busy': [BadgeColor.blue, 'Đang phục vụ'],
    'bill': [BadgeColor.amber, 'Chờ thanh toán'],
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    final busy = state.tables.where((t) => t.st != 'free').length;

    return Column(children: [
      TopBar(
        title: 'Sơ đồ bàn',
        subtitle: Text('$busy/${state.tables.length} bàn đang dùng · Tầng 1',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [IconBtn('layers', onTap: () => context.shell.toast('Gộp / chuyển bàn', 'layers'))],
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 132,
          ),
          itemCount: state.tables.length,
          itemBuilder: (_, i) => _TableCard(table: state.tables[i]),
        ),
      ),
    ]);
  }
}

class _TableCard extends StatelessWidget {
  final TableModel table;
  const _TableCard({required this.table});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final meta = TablesScreen._stMeta[table.st]!;
    return Pressable(
      scale: 0.97,
      onTap: () => _tap(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: table.st != 'free' ? p.line2 : p.line),
          boxShadow: const [BoxShadow(color: Color(0x0F3C1E0A), blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(table.id, style: AppType.display(size: 20, weight: FontWeight.w700, color: p.ink)),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: AppBadge(meta[1] as String, color: meta[0] as BadgeColor, pulse: table.st == 'busy'),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.person_outline_rounded, size: 13, color: p.muted),
              const SizedBox(width: 4),
              Text('${table.seats} chỗ', style: AppType.body(size: 12, weight: FontWeight.w700, color: p.muted)),
            ]),
            const Spacer(),
            if (table.st != 'free')
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line2))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${table.min}p', style: AppType.body(size: 12, weight: FontWeight.w700, color: p.muted)),
                  Text(vnd(table.total), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
                ]),
              )
            else
              Text('+ Mở đơn mới', style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.greenD)),
          ],
        ),
      ),
    );
  }

  void _tap(BuildContext context) {
    final state = context.read<AppState>();
    if (table.st == 'free') {
      state.openTableForSale(table.id);
      context.shell.toast('Mở đơn cho bàn ${table.id}', 'table');
      return;
    }
    context.shell.showSheet((_) => AppSheet(
          title: 'Bàn ${table.id}',
          headerExtra: [
            AppBadge(table.st == 'bill' ? 'Chờ thanh toán' : 'Đang phục vụ',
                color: table.st == 'bill' ? BadgeColor.amber : BadgeColor.blue),
          ],
          body: Builder(builder: (context) {
            final p = context.palette;
            return CardBox(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                KvRow('Thời gian', Text('${table.min} phút', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
                KvRow('Số khách', Text('${table.seats} chỗ', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
                KvRow('Tạm tính', Text(vnd(table.total), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
                    last: true),
              ]),
            );
          }),
          footer: Row(children: [
            Expanded(
              child: AppButton('Thêm món', icon: 'plus', large: true, variant: BtnVariant.ghost, onTap: () {
                context.shell.closeSheet();
                state.openTableForSale(table.id);
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton('Thanh toán', large: true, onTap: () => openPay(context, table.total)),
            ),
          ]),
        ));
  }
}
