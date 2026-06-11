import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/tables_controller.dart';
import '../../models/table.dart';
import '../../data/seed.dart' show vnd;
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';

/// Sơ đồ bàn — real floor map (areas + tables) from /pos/table-map.
class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});
  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  @override
  void initState() {
    super.initState();
    final ctl = context.read<TablesController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctl.loaded) ctl.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctl = context.watch<TablesController>();
    final p = context.palette;

    return Column(children: [
      TopBar(
        title: 'Sơ đồ bàn',
        subtitle: Text(
          ctl.loaded ? '${ctl.occupiedCount}/${ctl.tableCount} bàn đang dùng' : 'Đang tải…',
          style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2),
        ),
        actions: [IconBtn('history', onTap: () => ctl.load())],
      ),
      Expanded(child: _body(context, ctl)),
    ]);
  }

  Widget _body(BuildContext context, TablesController ctl) {
    final p = context.palette;
    if (ctl.loading && !ctl.loaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (ctl.error != null && !ctl.loaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🪑', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(ctl.error!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => ctl.load()),
        ]),
      );
    }
    if (ctl.areas.isEmpty) {
      return const EmptyState(emoji: '🪑', title: 'Chưa có bàn', sub: 'Khu vực/bàn được cấu hình ở phần Quản trị.');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        for (final area in ctl.areas) ...[
          _areaHeader(context, area),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 134,
            ),
            itemCount: area.tables.length,
            itemBuilder: (_, i) => _TableCard(table: area.tables[i]),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _areaHeader(BuildContext context, TableArea area) {
    final p = context.palette;
    final used = area.tables.where((t) => t.isOccupied).length;
    return Row(children: [
      Text(area.name, style: AppType.display(size: 17, weight: FontWeight.w700, color: p.ink)),
      const SizedBox(width: 8),
      AppBadge('$used/${area.tables.length}', color: used > 0 ? BadgeColor.blue : BadgeColor.gray),
    ]);
  }
}

class _TableCard extends StatelessWidget {
  final CafeTable table;
  const _TableCard({required this.table});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ctl = context.read<TablesController>();
    final busy = ctl.busy(table.id);

    late final BadgeColor badgeColor;
    late final String badgeText;
    if (table.isEmpty) {
      badgeColor = BadgeColor.green;
      badgeText = 'Trống';
    } else if (table.isDirty) {
      badgeColor = BadgeColor.amber;
      badgeText = 'Cần dọn';
    } else if (table.isLocked) {
      badgeColor = BadgeColor.gray;
      badgeText = 'Khoá';
    } else {
      badgeColor = BadgeColor.blue;
      badgeText = 'Phục vụ';
    }

    return Pressable(
      scale: 0.97,
      onTap: busy ? null : () => _tap(context, ctl),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: table.isEmpty ? p.line : p.line2),
          boxShadow: const [BoxShadow(color: Color(0x0F3C1E0A), blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(table.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.display(size: 20, weight: FontWeight.w700, color: p.ink)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: AppBadge(badgeText, color: badgeColor, pulse: table.isOccupied),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.person_outline_rounded, size: 13, color: p.muted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  table.session != null ? '${table.session!.guestCount}/${table.seats} khách' : '${table.seats} chỗ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body(size: 12, weight: FontWeight.w700, color: p.muted),
                ),
              ),
            ]),
            const Spacer(),
            if (busy)
              Row(children: [
                SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: p.muted)),
                const SizedBox(width: 8),
                Text('Đang xử lý…', style: AppType.body(size: 12.5, weight: FontWeight.w700, color: p.muted)),
              ])
            else if (table.isOccupied)
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line2))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${table.session?.billCount ?? 1} đơn',
                      maxLines: 1,
                      style: AppType.body(size: 12, weight: FontWeight.w700, color: p.muted)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(vnd(table.total),
                          style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
                    ),
                  ),
                ]),
              )
            else if (table.isDirty)
              Text('Chạm để dọn bàn', style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.amber))
            else
              Text('+ Mở bàn', style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.greenD)),
          ],
        ),
      ),
    );
  }

  void _tap(BuildContext context, TablesController ctl) {
    if (table.isEmpty) {
      _openTableSheet(context, ctl);
    } else if (table.isDirty) {
      _cleanSheet(context, ctl);
    } else if (table.isOccupied && table.session != null) {
      _detailSheet(context, ctl);
    }
  }

  void _openTableSheet(BuildContext context, TablesController ctl) {
    int guests = table.seats >= 2 ? 2 : 1;
    context.shell.showSheet((_) => StatefulBuilder(
          builder: (context, setSheet) {
            final p = context.palette;
            return AppSheet(
              title: 'Mở bàn ${table.label}',
              headerExtra: [AppBadge('${table.seats} chỗ', color: BadgeColor.gray)],
              body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Text('Số khách', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  QtyStepper(
                    value: guests,
                    onChange: (d) => setSheet(() => guests = (guests + d).clamp(1, table.seats)),
                  ),
                  const SizedBox(width: 14),
                  Text('khách', style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink2)),
                ]),
                const SizedBox(height: 8),
              ]),
              footer: AppButton(
                'Mở bàn & gọi món',
                icon: 'plus',
                large: true,
                block: true,
                onTap: () async {
                  context.shell.closeSheet();
                  final sid = await ctl.openTable(table, guestCount: guests);
                  if (!context.mounted) return;
                  if (sid != null) {
                    context.read<AppState>().setCashTab('sell');
                    context.shell.toast('Bàn ${table.label} đã mở — chọn món', 'check');
                  } else {
                    context.shell.toast(ctl.error ?? 'Không mở được bàn', 'edit');
                  }
                },
              ),
            );
          },
        ));
  }

  void _cleanSheet(BuildContext context, TablesController ctl) {
    context.shell.showSheet((_) => AppSheet(
          title: 'Dọn bàn ${table.label}',
          body: Builder(builder: (context) {
            final p = context.palette;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('Đánh dấu bàn ${table.label} đã dọn xong và sẵn sàng đón khách?',
                  style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink2, height: 1.4)),
            );
          }),
          footer: AppButton('Đã dọn xong', icon: 'check', large: true, block: true, onTap: () {
            context.shell.closeSheet();
            ctl.cleanTable(table);
            context.shell.toast('Bàn ${table.label} đã sẵn sàng', 'check');
          }),
        ));
  }

  void _detailSheet(BuildContext context, TablesController ctl) {
    final session = table.session!;
    context.shell.showSheet((_) => _SessionDetailSheet(table: table, sessionId: session.id));
  }
}

/// Occupied-table detail: loads the full session (bills + items) and offers
/// "Thêm món" (route Sell into this session) and "Đóng bàn".
class _SessionDetailSheet extends StatefulWidget {
  final CafeTable table;
  final String sessionId;
  const _SessionDetailSheet({required this.table, required this.sessionId});
  @override
  State<_SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends State<_SessionDetailSheet> {
  TableSessionDetail? _detail;
  String? _error;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await context.read<TablesController>().sessionDetail(widget.sessionId);
      if (mounted) setState(() => _detail = d);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được chi tiết bàn');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final d = _detail;
    return AppSheet(
      title: 'Bàn ${widget.table.label}',
      headerExtra: [AppBadge('Đang phục vụ', color: BadgeColor.blue)],
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(_error!, textAlign: TextAlign.center, style: AppType.body(size: 13.5, color: p.muted)),
          )
        else if (d == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator(color: p.terracotta)),
          )
        else ...[
          CardBox(
            radius: 14,
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              KvRow('Số khách', Text('${d.guestCount} khách', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
              KvRow('Số đơn', Text('${d.bills.where((b) => b.status != 'VOIDED').length}',
                  style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
              KvRow('Tổng tạm tính', Text(vnd(d.grandTotal),
                  style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)), last: true),
            ]),
          ),
          const SizedBox(height: 14),
          if (d.itemCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Bàn vừa mở — chưa gọi món nào.',
                  style: AppType.body(size: 13.5, weight: FontWeight.w600, color: p.muted)),
            )
          else
            for (final b in d.bills.where((b) => b.status != 'VOIDED' && b.items.isNotEmpty)) ...[
              for (final it in b.items) _line(context, it.productName, it.variantName, it.quantity, it.lineTotal),
            ],
          const SizedBox(height: 4),
        ],
      ]),
      footer: d == null
          ? null
          : Row(children: [
              Expanded(
                child: AppButton('Thêm món', icon: 'plus', large: true, variant: BtnVariant.ghost, onTap: () {
                  context.read<TablesController>().setActive(widget.sessionId, widget.table.label);
                  context.read<AppState>().setCashTab('sell');
                  context.shell.closeSheet();
                  context.shell.toast('Gọi thêm món cho Bàn ${widget.table.label}', 'table');
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(_closing ? 'Đang đóng…' : 'Đóng bàn', large: true, enabled: !_closing, onTap: () async {
                  setState(() => _closing = true);
                  final err = await context.read<TablesController>().closeSession(widget.sessionId);
                  if (!context.mounted) return;
                  if (err == null) {
                    context.shell.closeSheet();
                    context.shell.toast('Đã đóng Bàn ${widget.table.label}', 'check');
                  } else {
                    setState(() => _closing = false);
                    context.shell.toast(err, 'edit');
                  }
                }),
              ),
            ]),
    );
  }

  Widget _line(BuildContext context, String name, String? variant, int qty, int total) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
      child: Row(children: [
        Container(
          constraints: const BoxConstraints(minWidth: 26),
          height: 26,
          decoration: BoxDecoration(color: p.espresso, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('$qty', style: AppType.body(size: 13, weight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            (variant != null && variant.isNotEmpty) ? '$name ($variant)' : name,
            style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink),
          ),
        ),
        const SizedBox(width: 8),
        Text(vnd(total), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)),
      ]),
    );
  }
}
