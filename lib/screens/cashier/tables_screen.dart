import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/tables_controller.dart';
import '../../api/api_client.dart';
import '../../api/bill_repository.dart';
import '../../models/table.dart';
import '../../models/bill.dart';
import '../../data/seed.dart' show vnd;
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'cashier_sheets.dart' show openPayForBill;

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

const _kBillStatusLabel = {
  'DRAFT': 'Mới',
  'SENT_TO_BAR_UNPAID': 'Đã gửi Bar',
  'PENDING_PAYMENT': 'Chờ thu',
  'PAID': 'Đã trả',
  'COMPLETED': 'Hoàn tất',
  'VOIDED': 'Đã huỷ',
  'REFUNDED': 'Đã hoàn',
};
const _kBillActive = ['DRAFT', 'SENT_TO_BAR_UNPAID', 'PENDING_PAYMENT'];

/// Occupied-table detail: full session with per-bill cards. Each bill can be
/// Gửi Bar / Thanh toán (riêng từng bill) / Tách bill / Yêu cầu huỷ; the session
/// can Gộp bill, Chuyển bàn, Ghép bàn, Thêm món, Đóng bàn. Ported from the web
/// /pos/tables/[sessionId] page — all in ONE sheet via internal "modes" since
/// the app shell shows a single sheet at a time.
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
  bool _busy = false;
  String _mode = 'list'; // list | split | mergeBills | transfer | merge | void | refund
  Bill? _bill; // target bill for split / void / refund
  final TextEditingController _reason = TextEditingController();
  final Map<String, int> _split = {}; // billItemId -> qty to move
  final Set<String> _mergePick = {}; // billIds to merge
  bool _alsoMergeBills = false;

  TablesController get _ctl => context.read<TablesController>();
  BillRepository get _bills => context.read<BillRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await _ctl.sessionDetail(widget.sessionId);
      if (mounted) setState(() => _detail = d);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được chi tiết bàn');
    }
  }

  void _toList() => setState(() {
        _mode = 'list';
        _bill = null;
        _reason.clear();
        _split.clear();
        _mergePick.clear();
        _alsoMergeBills = false;
      });

  bool _hasDraft(Bill b) => b.items.any((i) => i.status == 'DRAFT');

  Future<void> _run(Future<String?> Function() op, String okMsg) async {
    setState(() => _busy = true);
    final err = await op();
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    setState(() => _busy = false);
    _toList();
    context.shell.toast(err ?? okMsg, err == null ? 'check' : 'edit');
  }

  // ---- per-bill actions ----------------------------------------------------
  Future<void> _sendBar(Bill b) async {
    setState(() => _busy = true);
    String? err;
    try {
      await _bills.sendToBar(b.id);
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = 'Lỗi gửi Bar';
    }
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    setState(() => _busy = false);
    context.shell.toast(err ?? 'Đã gửi Bar', err == null ? 'check' : 'edit');
  }

  void _pay(Bill b) {
    // Reuse the full pay sheet (voucher + cash/QR). openPayForBill captures the
    // shell up front and its showSheet REPLACES this session sheet — don't close
    // first (closing unmounts the context and the pay sheet never opened: #6).
    // Dine-in items are sent to the bar via "Gửi Bar" → suppress re-send (sent:true).
    openPayForBill(context, b, sent: true);
  }

  Future<void> _submitReason() async {
    final b = _bill;
    final reason = _reason.text.trim();
    if (b == null || reason.length < 2) return;
    await _run(() async {
      try {
        if (_mode == 'void') {
          await _bills.voidRequest(b.id, reason);
        } else {
          await _bills.refundRequest(b.id, amount: b.grandTotal, reason: reason);
        }
        return null;
      } on ApiException catch (e) {
        return e.message;
      } catch (_) {
        return 'Gửi yêu cầu thất bại';
      }
    }, 'Đã gửi yêu cầu cho quản lý duyệt');
  }

  Future<void> _doSplit() async {
    final b = _bill;
    if (b == null) return;
    final items = _split.entries
        .where((e) => e.value > 0)
        .map((e) => {'billItemId': e.key, 'quantity': e.value})
        .toList();
    if (items.isEmpty) return;
    await _run(() => _ctl.splitBill(widget.sessionId, b.id, items), 'Đã tách bill');
  }

  Future<void> _doMergeBills() async {
    if (_mergePick.length < 2) return;
    await _run(() => _ctl.mergeBillsOp(widget.sessionId, _mergePick.toList()), 'Đã gộp bill');
  }

  Future<void> _doTransfer(String toTableId) async =>
      _run(() => _ctl.transferTable(widget.sessionId, toTableId), 'Đã chuyển bàn');

  Future<void> _doMerge(String sourceSessionId) async =>
      _run(() => _ctl.mergeTable(widget.sessionId, sourceSessionId, mergeBills: _alsoMergeBills), 'Đã ghép bàn');

  // ---- build ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final d = _detail;
    if (_error != null) {
      return AppSheet(
        title: 'Bàn ${widget.table.label}',
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(_error!, textAlign: TextAlign.center, style: AppType.body(size: 13.5, color: p.muted)),
        ),
      );
    }
    if (d == null) {
      return AppSheet(
        title: 'Bàn ${widget.table.label}',
        body: const Padding(padding: EdgeInsets.symmetric(vertical: 36), child: Center(child: CircularProgressIndicator())),
      );
    }
    return switch (_mode) {
      'split' => _splitSheet(p, d),
      'mergeBills' => _mergeBillsSheet(p, d),
      'transfer' => _pickTableSheet(p, transfer: true),
      'merge' => _pickTableSheet(p, transfer: false),
      'void' || 'refund' => _reasonSheet(p),
      _ => _listSheet(p, d),
    };
  }

  // ===== list mode =====
  Widget _listSheet(Palette p, TableSessionDetail d) {
    final visible = d.bills.where((b) => b.status != 'VOIDED').toList();
    final activeBills = d.bills.where((b) => _kBillActive.contains(b.status)).toList();
    return AppSheet(
      title: 'Bàn ${widget.table.label}',
      headerExtra: [AppBadge('${d.guestCount} khách', color: BadgeColor.blue)],
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Bàn vừa mở — chưa gọi món nào.',
                style: AppType.body(size: 13.5, weight: FontWeight.w600, color: p.muted)),
          )
        else
          for (final b in visible) _billCard(p, b),
        const SizedBox(height: 6),
        // Session-level operations.
        Text('Thao tác bàn', style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.ink2)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (activeBills.length >= 2)
            _opChip(p, 'Gộp bill (${activeBills.length})', 'layers', () {
              _mergePick
                ..clear()
                ..addAll(activeBills.map((b) => b.id));
              setState(() => _mode = 'mergeBills');
            }),
          _opChip(p, 'Chuyển bàn', 'forward', () => setState(() => _mode = 'transfer')),
          _opChip(p, 'Ghép bàn', 'plus', () => setState(() => _mode = 'merge')),
        ]),
      ]),
      footer: Row(children: [
        Expanded(
          child: AppButton('Thêm món', icon: 'plus', large: true, variant: BtnVariant.ghost, onTap: () {
            _ctl.setActive(widget.sessionId, widget.table.label);
            context.read<AppState>().setCashTab('sell');
            context.shell.closeSheet();
            context.shell.toast('Gọi thêm món cho Bàn ${widget.table.label}', 'table');
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(_busy ? 'Đang đóng…' : 'Đóng bàn', large: true, enabled: !_busy, onTap: () async {
            setState(() => _busy = true);
            final err = await _ctl.closeSession(widget.sessionId);
            if (!mounted) return;
            if (err == null) {
              context.shell.closeSheet();
              context.shell.toast('Đã đóng Bàn ${widget.table.label}', 'check');
            } else {
              setState(() => _busy = false);
              context.shell.toast(err, 'edit');
            }
          }),
        ),
      ]),
    );
  }

  Widget _billCard(Palette p, Bill b) {
    final active = _kBillActive.contains(b.status);
    final paid = b.status == 'PAID' || b.status == 'COMPLETED';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 9),
          child: Row(children: [
            Flexible(
              child: Text(b.billCode,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppType.body(size: 14.5, weight: FontWeight.w800, color: p.ink)),
            ),
            const SizedBox(width: 8),
            AppBadge(_kBillStatusLabel[b.status] ?? b.status, color: paid ? BadgeColor.green : BadgeColor.amber),
            const SizedBox(width: 8),
            Text(vnd(b.grandTotal), style: AppType.body(size: 15, weight: FontWeight.w800, color: p.terracotta)),
          ]),
        ),
        if (b.items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Text('Chưa có món', textAlign: TextAlign.center, style: AppType.body(size: 13, color: p.muted)),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Column(children: [
              for (final it in b.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${it.quantity}×', style: AppType.body(size: 13.5, weight: FontWeight.w800, color: p.ink2)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(it.productName, style: AppType.body(size: 13.5, weight: FontWeight.w600, color: p.ink))),
                    Text(vnd(it.lineTotal), style: AppType.body(size: 13, weight: FontWeight.w700, color: p.ink2)),
                  ]),
                ),
            ]),
          ),
        if (active || paid)
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 8, 11, 11),
            child: Wrap(spacing: 7, runSpacing: 7, children: [
              if (active && _hasDraft(b)) _act(p, 'Gửi Bar', BtnVariant.dark, () => _sendBar(b)),
              if (active && b.grandTotal > 0) _act(p, 'Thanh toán', BtnVariant.pri, () => _pay(b)),
              if (active && b.items.isNotEmpty)
                _act(p, 'Tách bill', BtnVariant.soft, () {
                  _split.clear();
                  setState(() {
                    _bill = b;
                    _mode = 'split';
                  });
                }),
              if (active)
                _act(p, 'Yêu cầu huỷ', BtnVariant.ghost, () {
                  _reason.clear();
                  setState(() {
                    _bill = b;
                    _mode = 'void';
                  });
                }, danger: true),
              if (paid)
                _act(p, 'Yêu cầu hoàn tiền', BtnVariant.ghost, () {
                  _reason.clear();
                  setState(() {
                    _bill = b;
                    _mode = 'refund';
                  });
                }, danger: true),
            ]),
          ),
      ]),
    );
  }

  Widget _act(Palette p, String label, BtnVariant variant, VoidCallback onTap, {bool danger = false}) {
    return AppButton(label, variant: variant, enabled: !_busy, textColor: danger ? p.red : null, onTap: onTap);
  }

  Widget _opChip(Palette p, String label, String icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: p.cream2,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: p.line2),
        ),
        child: Text(label, style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
      ),
    );
  }

  // ===== split mode =====
  Widget _splitSheet(Palette p, TableSessionDetail d) {
    final b = _bill!;
    final moved = b.items.fold<int>(0, (s, it) => s + it.unitPrice * (_split[it.id] ?? 0));
    final any = _split.values.any((q) => q > 0);
    return AppSheet(
      title: 'Tách bill',
      headerExtra: [AppBadge(b.billCode, color: BadgeColor.gray)],
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Chọn món/số lượng tách sang bill mới',
              style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.muted)),
        ),
        for (final it in b.items)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(it.productName, style: AppType.body(size: 14, weight: FontWeight.w700, color: p.ink)),
                  Text('${it.quantity}× · ${vnd(it.unitPrice)}', style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted)),
                ]),
              ),
              const SizedBox(width: 10),
              QtyStepper(
                value: _split[it.id] ?? 0,
                small: true,
                onChange: (delta) => setState(() {
                  final next = ((_split[it.id] ?? 0) + delta).clamp(0, it.quantity);
                  _split[it.id] = next;
                }),
              ),
            ]),
          ),
      ]),
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Tách sang bill mới', style: AppType.body(size: 14, weight: FontWeight.w700, color: p.ink2)),
            Text(vnd(moved), style: AppType.body(size: 16, weight: FontWeight.w800, color: p.terracotta)),
          ]),
        ),
        Row(children: [
          AppButton('Quay lại', large: true, variant: BtnVariant.soft, onTap: _busy ? null : _toList),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(_busy ? 'Đang tách…' : 'Tách bill', icon: 'check', large: true, block: true,
                enabled: any && !_busy, onTap: _doSplit),
          ),
        ]),
      ]),
    );
  }

  // ===== merge-bills mode =====
  Widget _mergeBillsSheet(Palette p, TableSessionDetail d) {
    final active = d.bills.where((b) => _kBillActive.contains(b.status)).toList();
    final selected = active.where((b) => _mergePick.contains(b.id)).toList();
    final total = selected.fold<int>(0, (s, b) => s + b.grandTotal);
    return AppSheet(
      title: 'Gộp bill',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Chọn các bill (≥2) để gộp thành 1',
              style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.muted)),
        ),
        for (final b in active)
          GestureDetector(
            onTap: () => setState(() => _mergePick.contains(b.id) ? _mergePick.remove(b.id) : _mergePick.add(b.id)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: _mergePick.contains(b.id) ? p.greenBg : p.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _mergePick.contains(b.id) ? p.greenD : p.line),
              ),
              child: Row(children: [
                Icon(_mergePick.contains(b.id) ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 20, color: _mergePick.contains(b.id) ? p.greenD : p.line2),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(b.billCode, style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)),
                    Text('${b.itemCount} món · ${_kBillStatusLabel[b.status] ?? b.status}',
                        style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted)),
                  ]),
                ),
                Text(vnd(b.grandTotal), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)),
              ]),
            ),
          ),
      ]),
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Bill gộp (${selected.length})', style: AppType.body(size: 14, weight: FontWeight.w700, color: p.ink2)),
            Text(vnd(total), style: AppType.body(size: 16, weight: FontWeight.w800, color: p.terracotta)),
          ]),
        ),
        Row(children: [
          AppButton('Quay lại', large: true, variant: BtnVariant.soft, onTap: _busy ? null : _toList),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
                _busy ? 'Đang gộp…' : (selected.length < 2 ? 'Chọn ≥2 bill' : 'Gộp ${selected.length} bill'),
                icon: 'check', large: true, block: true,
                enabled: selected.length >= 2 && !_busy, onTap: _doMergeBills),
          ),
        ]),
      ]),
    );
  }

  // ===== transfer / merge: pick a table =====
  Widget _pickTableSheet(Palette p, {required bool transfer}) {
    final options = transfer ? _ctl.emptyTables() : _ctl.otherOpenTables(widget.sessionId);
    return AppSheet(
      title: transfer ? 'Chuyển sang bàn trống' : 'Ghép bàn khác vào bàn này',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!transfer)
          GestureDetector(
            onTap: () => setState(() => _alsoMergeBills = !_alsoMergeBills),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(_alsoMergeBills ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 20, color: _alsoMergeBills ? p.terracotta : p.line2),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Gộp luôn bill thành 1 (khách trả chung)',
                      style: AppType.body(size: 13.5, weight: FontWeight.w700, color: p.ink2)),
                ),
              ]),
            ),
          ),
        if (options.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(transfer ? 'Không có bàn trống' : 'Không có bàn khác đang mở',
                textAlign: TextAlign.center, style: AppType.body(size: 13.5, color: p.muted)),
          )
        else
          for (final t in options)
            GestureDetector(
              onTap: _busy
                  ? null
                  : () => transfer ? _doTransfer(t.id) : _doMerge(t.session!.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
                child: Row(children: [
                  LeadIcon(icon: 'table'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      transfer ? '${t.label} · ${t.seats} chỗ' : '${t.label} · ${t.session!.billCount} bill',
                      style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: p.faint),
                ]),
              ),
            ),
      ]),
      footer: AppButton('Quay lại', large: true, block: true, variant: BtnVariant.soft, onTap: _busy ? null : _toList),
    );
  }

  // ===== void / refund reason =====
  Widget _reasonSheet(Palette p) {
    final b = _bill!;
    final isVoid = _mode == 'void';
    final ok = _reason.text.trim().length >= 2;
    return AppSheet(
      title: isVoid ? 'Yêu cầu huỷ bill' : 'Yêu cầu hoàn tiền',
      headerExtra: [AppBadge(b.billCode, color: BadgeColor.gray)],
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 0, 10),
          child: Text(
            isVoid ? 'Lý do huỷ đơn' : 'Lý do hoàn tiền (${vnd(b.grandTotal)})',
            style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2),
          ),
        ),
        TextField(
          controller: _reason,
          onChanged: (_) => setState(() {}),
          maxLines: 2,
          style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink),
          decoration: InputDecoration(
            hintText: 'VD: khách đổi ý, pha sai, đồ lỗi…',
            hintStyle: AppType.body(size: 14.5, weight: FontWeight.w500, color: p.faint),
            filled: true,
            fillColor: p.paper,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
          ),
        ),
      ]),
      footer: Row(children: [
        AppButton('Quay lại', large: true, variant: BtnVariant.soft, onTap: _busy ? null : _toList),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(_busy ? 'Đang gửi…' : 'Gửi yêu cầu', icon: 'check', large: true, block: true,
              enabled: ok && !_busy, onTap: _submitReason),
        ),
      ]),
    );
  }
}
