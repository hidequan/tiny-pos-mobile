import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/admin_data_controller.dart';
import '../../state/session.dart';
import '../../models/admin.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';

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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _stockInSheet(context, item),
      child: Container(
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
    ),
    );
  }

  void _stockInSheet(BuildContext context, StockBalance item) {
    final qty = TextEditingController();
    bool busy = false;
    context.shell.showSheet((_) => StatefulBuilder(builder: (context, setInner) {
          final p = context.palette;
          Future<void> submit() async {
              final n = num.tryParse(qty.text.trim());
              if (n == null || n <= 0) {
                context.shell.toast('Nhập số lượng hợp lệ', 'edit');
                return;
              }
              final branchId = context.read<SessionState>().user?.branchId;
              if (branchId == null) {
                context.shell.toast('Thiếu chi nhánh', 'edit');
                return;
              }
              setInner(() => busy = true);
              final err = await context.read<AdminDataController>()
                  .stockIn(branchId: branchId, ingredientId: item.ingredientId, quantity: n, reason: 'Nhập kho (app)');
              if (!context.mounted) return;
              if (err == null) {
                context.shell.closeSheet();
                context.shell.toast('Đã nhập ${_fmt(n.toDouble())} ${item.unit} · ${item.name}', 'check');
              } else {
                setInner(() => busy = false);
                context.shell.toast(err, 'edit');
              }
            }

            return AppSheet(
              title: 'Nhập kho · ${item.name}',
              headerExtra: [AppBadge('Tồn ${_fmt(item.onHand)} ${item.unit}', color: BadgeColor.gray)],
              body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Text('Số lượng nhập thêm (${item.unit})', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
                const SizedBox(height: 10),
                TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: AppType.body(size: 16, weight: FontWeight.w700, color: p.ink),
                  decoration: InputDecoration(
                    hintText: 'VD: 500',
                    hintStyle: AppType.body(size: 15, weight: FontWeight.w500, color: p.faint),
                    filled: true,
                    fillColor: p.paper,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
                  ),
                ),
              ]),
              footer: AppButton(busy ? 'Đang nhập...' : 'Xác nhận nhập kho',
                  icon: 'check', large: true, block: true, enabled: !busy, onTap: submit),
            );
        }));
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
