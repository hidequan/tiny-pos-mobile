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

const _slotLabel = {'CA_SANG': 'Ca sáng', 'CA_CHIEU': 'Ca chiều', 'CA_TOI': 'Ca tối'};
const _slotWin = {'CA_SANG': '07–12', 'CA_CHIEU': '12–17', 'CA_TOI': '17–22'};
const _statusLabel = {
  'OPEN': 'Đang mở',
  'REOPENED': 'Mở lại',
  'CLOSING': 'Đang đóng',
  'PENDING_CONFIRMATION': 'Chờ xác nhận',
  'CONFIRMED': 'Đã xác nhận',
  'CLOSED': 'Đã đóng',
};

String _two(int n) => n.toString().padLeft(2, '0');

/// Ca / Két tiền — admin shift reconciliation. Ported from the web admin/shifts.
class AdminShiftsScreen extends StatefulWidget {
  const AdminShiftsScreen({super.key});
  @override
  State<AdminShiftsScreen> createState() => _AdminShiftsScreenState();
}

class _AdminShiftsScreenState extends State<AdminShiftsScreen> {
  String _period = 'month'; // day | week | month
  late DateTime _anchor;
  String _slot = '';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _anchor = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  ({DateTime from, DateTime to}) _range() {
    final a = DateTime(_anchor.year, _anchor.month, _anchor.day);
    switch (_period) {
      case 'day':
        return (from: a, to: a);
      case 'week':
        final dow = (a.weekday + 6) % 7; // Monday = 0
        final f = a.subtract(Duration(days: dow));
        return (from: f, to: f.add(const Duration(days: 6)));
      default:
        return (from: DateTime(a.year, a.month, 1), to: DateTime(a.year, a.month + 1, 0));
    }
  }

  void _reload() {
    final r = _range();
    final from = '${r.from.year}-${_two(r.from.month)}-${_two(r.from.day)}T00:00:00';
    final to = '${r.to.year}-${_two(r.to.month)}-${_two(r.to.day)}T23:59:59';
    context.read<AdminDataController>().loadAdminShifts(from: from, to: to);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime(_anchor.year - 2),
      lastDate: DateTime(_anchor.year + 1),
    );
    if (d != null && mounted) {
      setState(() => _anchor = d);
      _reload();
    }
  }

  Future<void> _confirm(AdminDataController a, AdminShift s) async {
    final err = await a.confirmShift(s.id);
    if (!mounted) return;
    context.shell.toast(err ?? 'Đã xác nhận ca ${s.shiftCode}', err == null ? 'check' : 'edit');
  }

  String _dmy(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    final q = _search.trim().toLowerCase();
    final rows = a.adminShifts.where((s) {
      if (_slot.isNotEmpty && s.slot != _slot) return false;
      if (q.isEmpty) return true;
      return s.shiftCode.toLowerCase().contains(q) ||
          (s.cashier ?? '').toLowerCase().contains(q) ||
          s.status.toLowerCase().contains(q);
    }).toList();
    final totalDiff = rows.fold<int>(0, (acc, s) => acc + (s.difference ?? 0));
    final r = _range();

    return Column(children: [
      BackBar(title: 'Ca / Két tiền', sub: a.adminShiftsLoaded ? '${rows.length} ca · lệch ${vnd(totalDiff)}' : 'Đang tải…'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: Row(children: [
          Expanded(
            child: Segmented(
              labels: const ['Ngày', 'Tuần', 'Tháng'],
              active: _period == 'day' ? 0 : (_period == 'week' ? 1 : 2),
              onTap: (i) {
                setState(() => _period = ['day', 'week', 'month'][i]);
                _reload();
              },
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(11)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: p.ink2),
                const SizedBox(width: 7),
                Text(_dmy(_anchor), style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.ink2)),
              ]),
            ),
          ),
        ]),
      ),
      ChipsRow(children: [
        for (final s in const ['', 'CA_SANG', 'CA_CHIEU', 'CA_TOI'])
          PillChip(s.isEmpty ? 'Tất cả ca' : '${_slotLabel[s]} (${_slotWin[s]})', on: _slot == s, onTap: () => setState(() => _slot = s)),
      ]),
      SearchField(hint: 'Tìm mã ca / thu ngân...', value: _search, onChanged: (v) => setState(() => _search = v)),
      Expanded(child: _body(context, a, p, rows, r)),
    ]);
  }

  Widget _body(BuildContext context, AdminDataController a, Palette p, List<AdminShift> rows, ({DateTime from, DateTime to}) r) {
    if (a.adminShiftsLoading && !a.adminShiftsLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (a.adminShiftsError != null && !a.adminShiftsLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(a.adminShiftsError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: _reload),
        ]),
      );
    }
    if (rows.isEmpty) {
      return EmptyState(emoji: '🗓️', title: 'Không có ca nào', sub: '${_dmy(r.from)} → ${_dmy(r.to)}');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _card(context, a, p, rows[i]),
    );
  }

  Widget _card(BuildContext context, AdminDataController a, Palette p, AdminShift s) {
    final statusColor = switch (s.status) {
      'CONFIRMED' => BadgeColor.green,
      'PENDING_CONFIRMATION' => BadgeColor.amber,
      'OPEN' || 'REOPENED' => BadgeColor.blue,
      _ => BadgeColor.gray,
    };
    final diff = s.difference ?? 0;
    final diffColor = diff < 0 ? p.red : (diff > 0 ? p.amber : p.muted);
    final busy = a.shiftBusy(s.id);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(child: Text(s.shiftCode, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppType.body(size: 14.5, weight: FontWeight.w800, color: p.ink))),
          const SizedBox(width: 8),
          AppBadge(_slotLabel[s.slot] ?? '—', color: BadgeColor.amber),
          const Spacer(),
          AppBadge(_statusLabel[s.status] ?? s.status, color: statusColor),
        ]),
        const SizedBox(height: 3),
        Text(
          '${s.cashier ?? ''}${s.openedAt != null ? ' · ${_dmy(s.openedAt!.toLocal())} ${_two(s.openedAt!.toLocal().hour)}:${_two(s.openedAt!.toLocal().minute)}' : ''}',
          style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _stat(p, 'Đầu ca', vnd(s.openingCash), p.ink2),
          _stat(p, 'Dự kiến', s.expectedCash != null ? vnd(s.expectedCash!) : '—', p.ink2),
          _stat(p, 'Thực', s.actualCash != null ? vnd(s.actualCash!) : '—', p.ink2),
          _stat(p, 'Lệch', s.difference != null ? vnd(s.difference!) : '—', diffColor),
        ]),
        if (s.isPending) ...[
          const SizedBox(height: 11),
          AppButton(busy ? 'Đang xác nhận…' : 'Xác nhận ca', icon: 'check', block: true,
              enabled: !busy, onTap: () => _confirm(a, s)),
        ],
      ]),
    );
  }

  Widget _stat(Palette p, String label, String value, Color valueColor) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: AppType.body(size: 10.5, weight: FontWeight.w700, color: p.muted)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppType.body(size: 12.5, weight: FontWeight.w800, color: valueColor)),
        ]),
      );
}
