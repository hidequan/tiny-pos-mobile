import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/admin_data_controller.dart';
import '../../models/admin.dart';
import '../../data/seed.dart' show vnd;
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_widgets.dart';

const _cmType = {
  'OPENING': 'Đầu ca',
  'CASH_SALE': 'Bán hàng',
  'CASH_IN': 'Nộp quỹ',
  'CASH_OUT': 'Rút quỹ',
  'CASH_REFUND': 'Hoàn tiền',
  'ADJUSTMENT': 'Điều chỉnh',
  'CLOSING': 'Cuối ca',
};

/// Sổ quỹ ca — cash drawer ledger + approve/reject over-limit cash-outs.
/// Ported from the web admin/cash-flow page.
class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key});
  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  String _type = '';
  String _search = '';

  static const _filters = ['', 'CASH_SALE', 'CASH_IN', 'CASH_OUT', 'CASH_REFUND', 'ADJUSTMENT'];

  @override
  void initState() {
    super.initState();
    final a = context.read<AdminDataController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => a.ensureCashMovements());
  }

  // money() mis-groups some negatives — format abs + an explicit sign.
  String _money(int n) => '${n < 0 ? '−' : ''}${vnd(n.abs())}';

  String _fmt(DateTime? t) {
    if (t == null) return '';
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)} ${two(l.day)}/${two(l.month)}';
  }

  Future<void> _decide(AdminDataController a, CashMovement m, bool approve) async {
    final err = await a.decideCashMovement(m.id, approve: approve);
    if (!mounted) return;
    context.shell.toast(err ?? (approve ? 'Đã duyệt' : 'Đã từ chối'), err == null ? 'check' : 'edit');
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    final q = _search.trim().toLowerCase();
    final rows = a.cashMovements.where((m) {
      if (_type.isNotEmpty && m.type != _type) return false;
      if (q.isEmpty) return true;
      return (_cmType[m.type] ?? m.type).toLowerCase().contains(q) ||
          (m.reason ?? '').toLowerCase().contains(q) ||
          (m.shiftCode ?? '').toLowerCase().contains(q) ||
          (m.cashierName ?? '').toLowerCase().contains(q);
    }).toList();

    return Column(children: [
      BackBar(title: 'Sổ quỹ ca', sub: a.cmLoaded ? '${a.cashMovements.length} giao dịch' : 'Đang tải…'),
      Expanded(child: _body(context, a, p, rows)),
    ]);
  }

  Widget _body(BuildContext context, AdminDataController a, Palette p, List<CashMovement> rows) {
    if (a.cmLoading && !a.cmLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (a.cmError != null && !a.cmLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(a.cmError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => a.loadCashMovements()),
        ]),
      );
    }
    final pending = a.cmPending;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (pending.isNotEmpty) ...[
          const SectionHeader('Chờ duyệt · rút quỹ vượt hạn mức'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [for (final m in pending) _pendingCard(context, a, p, m)]),
          ),
        ],
        const SectionHeader('Giao dịch quỹ'),
        ChipsRow(children: [
          for (final f in _filters)
            PillChip(f.isEmpty ? 'Tất cả' : (_cmType[f] ?? f), on: _type == f, onTap: () => setState(() => _type = f)),
        ]),
        SearchField(hint: 'Tìm loại / lý do / ca / thu ngân...', value: _search, onChanged: (v) => setState(() => _search = v)),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: EmptyState(emoji: '💵', title: 'Không có giao dịch', sub: 'Thử đổi bộ lọc hoặc từ khóa'),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(children: [for (final m in rows) _row(context, p, m)]),
          ),
      ],
    );
  }

  Widget _pendingCard(BuildContext context, AdminDataController a, Palette p, CashMovement m) {
    final busy = a.cmBusy(m.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: p.amberBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.amber.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_cmType[m.type] ?? m.type, style: AppType.body(size: 14.5, weight: FontWeight.w800, color: p.ink)),
          const Spacer(),
          Text(_money(m.amount), style: AppType.body(size: 14.5, weight: FontWeight.w800, color: p.red)),
        ]),
        const SizedBox(height: 4),
        Text('${m.reason ?? ''} · ${m.shiftCode ?? ''} · ${m.cashierName ?? ''} · ${_fmt(m.createdAt)}',
            style: AppType.body(size: 12, weight: FontWeight.w600, color: p.ink2)),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(
            child: AppButton(busy ? '...' : 'Từ chối', variant: BtnVariant.ghost, textColor: p.red, enabled: !busy,
                onTap: () => _decide(a, m, false)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(busy ? '...' : 'Duyệt', variant: BtnVariant.pri, enabled: !busy, onTap: () => _decide(a, m, true)),
          ),
        ]),
      ]),
    );
  }

  Widget _row(BuildContext context, Palette p, CashMovement m) {
    final positive = m.amount >= 0;
    final statusColor = switch (m.status) {
      'POSTED' || 'APPROVED' => BadgeColor.green,
      'PENDING' => BadgeColor.amber,
      'REJECTED' => BadgeColor.red,
      _ => BadgeColor.gray,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_cmType[m.type] ?? m.type, style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)),
          const SizedBox(width: 8),
          AppBadge(m.status, color: statusColor),
          const Spacer(),
          Text(_money(m.amount), style: AppType.body(size: 14, weight: FontWeight.w800, color: positive ? p.greenD : p.red)),
        ]),
        const SizedBox(height: 4),
        Text(
          '${m.shiftCode ?? '—'}${m.cashierName != null ? ' · ${m.cashierName}' : ''} · ${_fmt(m.createdAt)}'
          '${(m.reason ?? '').isNotEmpty ? ' · ${m.reason}' : ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted),
        ),
      ]),
    );
  }
}
