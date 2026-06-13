import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/admin_data_controller.dart';
import '../../models/admin.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_widgets.dart';

const _actLabel = {
  'CREATE': 'Tạo mới',
  'UPDATE': 'Cập nhật',
  'DELETE': 'Xoá',
  'LOGIN': 'Đăng nhập',
  'LOGOUT': 'Đăng xuất',
  'VOID': 'Huỷ đơn',
  'REFUND': 'Hoàn tiền',
  'APPROVE': 'Duyệt',
  'REJECT': 'Từ chối',
  'SHIFT_OPEN': 'Mở ca',
  'SHIFT_CLOSE': 'Đóng ca',
  'CASH_DRAWER_OPEN': 'Mở két',
  'PRICE_OVERRIDE': 'Sửa giá',
};
const _entLabel = {
  'vouchers': 'Voucher', 'products': 'Sản phẩm', 'product-categories': 'Danh mục', 'sizes': 'Size',
  'toppings': 'Topping', 'ingredients': 'Nguyên liệu', 'bom-recipes': 'BOM', 'bills': 'Hoá đơn',
  'payments': 'Thanh toán', 'users': 'Nhân viên', 'shifts': 'Ca làm việc', 'cash-movements': 'Quỹ tiền',
  'tables': 'Bàn', 'floor-areas': 'Khu vực', 'void-refund-requests': 'Huỷ/Hoàn', 'table-sessions': 'Phiên bàn',
  'kds': 'Bar/KDS', 'customers': 'Khách hàng', 'auth': 'Đăng nhập', 'hardware-devices': 'Thiết bị', 'branches': 'Chi nhánh',
};

BadgeColor _actColor(String a) => switch (a) {
      'CREATE' || 'APPROVE' => BadgeColor.green,
      'UPDATE' => BadgeColor.blue,
      'DELETE' || 'VOID' || 'REJECT' => BadgeColor.red,
      'REFUND' || 'PRICE_OVERRIDE' => BadgeColor.amber,
      _ => BadgeColor.gray,
    };

String _entityLabel(String t) {
  final parts = t.split('/').where((s) => s.isNotEmpty).toList();
  final seg = parts.isEmpty ? t : parts.last;
  return _entLabel[seg] ?? seg;
}

String _fmtTime(DateTime? t) {
  if (t == null) return '';
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)} ${two(l.day)}/${two(l.month)}';
}

/// Audit log — every data-change action across staff. Ported from web admin/audit-logs.
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});
  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _action = '';
  String _search = '';

  static const _filters = ['', 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'VOID', 'REFUND', 'APPROVE', 'SHIFT_OPEN', 'SHIFT_CLOSE'];

  @override
  void initState() {
    super.initState();
    final a = context.read<AdminDataController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => a.ensureAudit());
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    final q = _search.trim().toLowerCase();
    final rows = a.auditRows.where((r) {
      if (_action.isNotEmpty && r.action != _action) return false;
      if (q.isEmpty) return true;
      return (_actLabel[r.action] ?? r.action).toLowerCase().contains(q) ||
          r.action.toLowerCase().contains(q) ||
          r.entityType.toLowerCase().contains(q) ||
          (r.actorName ?? '').toLowerCase().contains(q) ||
          (r.actorUsername ?? '').toLowerCase().contains(q);
    }).toList();

    return Column(children: [
      BackBar(title: 'Audit log', sub: a.auditLoaded ? '${a.auditRows.length} bản ghi' : 'Đang tải…'),
      ChipsRow(children: [
        for (final f in _filters)
          PillChip(f.isEmpty ? 'Tất cả' : (_actLabel[f] ?? f), on: _action == f, onTap: () => setState(() => _action = f)),
      ]),
      SearchField(hint: 'Tìm người / hành động / đối tượng...', value: _search, onChanged: (v) => setState(() => _search = v)),
      Expanded(child: _body(context, a, p, rows)),
    ]);
  }

  Widget _body(BuildContext context, AdminDataController a, Palette p, List<AuditRow> rows) {
    if (a.auditLoading && !a.auditLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (a.auditError != null && !a.auditLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(a.auditError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => a.loadAudit()),
        ]),
      );
    }
    if (rows.isEmpty) {
      return const EmptyState(emoji: '📋', title: 'Không có log', sub: 'Thử đổi bộ lọc hoặc từ khóa');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _row(context, p, rows[i]),
    );
  }

  Widget _row(BuildContext context, Palette p, AuditRow r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              AppBadge(_actLabel[r.action] ?? r.action, color: _actColor(r.action)),
              const SizedBox(width: 8),
              Flexible(child: Text(_entityLabel(r.entityType), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppType.body(size: 13.5, weight: FontWeight.w800, color: p.ink2))),
            ]),
            const SizedBox(height: 4),
            Text('${r.actorName ?? '—'}${r.actorUsername != null ? ' · @${r.actorUsername}' : ''}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted)),
          ]),
        ),
        const SizedBox(width: 8),
        Text(_fmtTime(r.createdAt), style: AppType.body(size: 11.5, weight: FontWeight.w600, color: p.faint)),
      ]),
    );
  }
}

/// Giám sát đồng bộ — synced devices + conflicts. Ported from web admin/sync-monitor.
class SyncMonitorScreen extends StatefulWidget {
  const SyncMonitorScreen({super.key});
  @override
  State<SyncMonitorScreen> createState() => _SyncMonitorScreenState();
}

class _SyncMonitorScreenState extends State<SyncMonitorScreen> {
  @override
  void initState() {
    super.initState();
    final a = context.read<AdminDataController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => a.ensureSync());
  }

  Future<void> _resolve(AdminDataController a, SyncConflict c, String resolution) async {
    final err = await a.resolveConflict(c.id, resolution);
    if (!mounted) return;
    context.shell.toast(err ?? 'Đã xử lý conflict', err == null ? 'check' : 'edit');
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    return Column(children: [
      BackBar(title: 'Giám sát đồng bộ', sub: a.syncLoaded ? '${a.syncDevices.length} thiết bị · ${a.syncConflicts.length} conflict' : 'Đang tải…'),
      Expanded(child: _body(context, a, p)),
    ]);
  }

  Widget _body(BuildContext context, AdminDataController a, Palette p) {
    if (a.syncLoading && !a.syncLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (a.syncError != null && !a.syncLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(a.syncError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => a.loadSync()),
        ]),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SectionHeader('Thiết bị đồng bộ'),
        if (a.syncDevices.isEmpty)
          const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 8), child: EmptyState(emoji: '📲', title: 'Chưa có thiết bị', sub: 'Thiết bị đăng nhập sẽ hiện ở đây'))
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [for (final d in a.syncDevices) _deviceRow(p, d)]),
          ),
        SectionHeader('Conflict (${a.syncConflicts.length})'),
        if (a.syncConflicts.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('✓ Không có conflict nào.', style: AppType.body(size: 13.5, weight: FontWeight.w700, color: p.greenD)),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [for (final c in a.syncConflicts) _conflictCard(context, a, p, c)]),
          ),
      ],
    );
  }

  Widget _deviceRow(Palette p, SyncDevice d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: d.isOnline ? p.greenD : p.line2)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(d.deviceId, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppType.body(size: 13.5, weight: FontWeight.w800, color: p.ink)),
            const SizedBox(height: 2),
            Text('Đồng bộ: ${d.lastSyncedAt != null ? _fmtTime(d.lastSyncedAt) : '—'}',
                style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted)),
          ]),
        ),
        const SizedBox(width: 8),
        if (d.pendingCount > 0) ...[
          AppBadge('chờ ${d.pendingCount}', color: BadgeColor.amber),
          const SizedBox(width: 6),
        ],
        AppBadge(d.isOnline ? 'online' : 'offline', color: d.isOnline ? BadgeColor.green : BadgeColor.gray),
      ]),
    );
  }

  Widget _conflictCard(BuildContext context, AdminDataController a, Palette p, SyncConflict c) {
    final busy = a.conflictBusy(c.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${c.entityType} · ${c.status}', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)),
        const SizedBox(height: 3),
        Text('${c.resolution ?? ''} · ${_fmtTime(c.createdAt)}',
            style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted)),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(
            child: AppButton(busy ? '...' : 'Server thắng', variant: BtnVariant.dark, enabled: !busy,
                onTap: () => _resolve(a, c, 'server_wins')),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(busy ? '...' : 'Client thắng', variant: BtnVariant.ghost, enabled: !busy,
                onTap: () => _resolve(a, c, 'client_wins')),
          ),
        ]),
      ]),
    );
  }
}
