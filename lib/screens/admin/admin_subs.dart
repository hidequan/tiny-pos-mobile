import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/admin_data_controller.dart';
import '../../models/admin.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_widgets.dart';
import 'staff_form.dart';

/// Nhân viên & RBAC.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  static const _roles = [
    ['admin', 'Quản trị'],
    ['cashier', 'Thu ngân'],
    ['barista', 'Pha chế'],
  ];

  @override
  void initState() {
    super.initState();
    final a = context.read<AdminDataController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => a.ensureStaff());
  }

  BadgeColor _badge(String staffRole) => switch (staffRole) {
        'CASHIER' => BadgeColor.blue,
        'BARISTA' => BadgeColor.green,
        _ => BadgeColor.red,
      };

  void _staffActions(BuildContext context, AdminDataController a, StaffMember s) {
    context.shell.showSheet((_) => AppSheet(
          title: s.fullName.trim().isEmpty ? s.username : s.fullName,
          headerExtra: [AppBadge(s.roleLabel, color: _badge(s.staffRole))],
          body: Builder(builder: (context) {
            final p = context.palette;
            return CardBox(
              radius: 14,
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                KvRow('Tên đăng nhập', Text('@${s.username}', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
                KvRow('Vai trò', Text(s.roleLabel, style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
                KvRow('Trạng thái', Text(s.active ? 'Đang hoạt động' : 'Đã khoá',
                    style: AppType.body(size: 14, weight: FontWeight.w800, color: s.active ? p.greenD : p.muted)), last: true),
              ]),
            );
          }),
          footer: s.active
              ? Builder(builder: (context) {
                  final p = context.palette;
                  return AppButton('Khoá tài khoản', icon: 'logout', large: true, block: true,
                      variant: BtnVariant.soft, textColor: p.red, onTap: () async {
                    context.shell.closeSheet();
                    final err = await a.deactivateStaff(s.id);
                    if (!context.mounted) return;
                    context.shell.toast(err ?? 'Đã khoá tài khoản ${s.username}', err == null ? 'check' : 'edit');
                  });
                })
              : AppButton('Mở khoá tài khoản', icon: 'check', large: true, block: true,
                  variant: BtnVariant.ghost, onTap: () async {
                  context.shell.closeSheet();
                  final err = await a.reactivateStaff(s.id);
                  if (!context.mounted) return;
                  context.shell.toast(err ?? 'Đã mở khoá ${s.username}', err == null ? 'check' : 'edit');
                }),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    return Column(children: [
      BackBar(title: 'Nhân viên', sub: a.staffLoaded ? 'RBAC · ${a.staff.length} người' : 'Đang tải…'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            SectionHeader('Danh sách nhân viên', action: '+ Thêm', onAction: () => openStaffForm(context)),
            if (a.staffLoading && !a.staffLoaded)
              Padding(padding: const EdgeInsets.all(28), child: Center(child: CircularProgressIndicator(color: p.terracotta)))
            else if (a.staffError != null && !a.staffLoaded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(children: [
                  Text(a.staffError!, style: AppType.body(size: 13, color: p.muted)),
                  const SizedBox(height: 12),
                  AppButton('Thử lại', icon: 'history', onTap: () => a.loadStaff()),
                ]),
              )
            else
              CardBox(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                clip: true,
                padding: EdgeInsets.zero,
                child: RowList([
                  for (final s in a.staff)
                    ListRow(
                      onTap: () => _staffActions(context, a, s),
                      leading: Avatar(s.initials),
                      title: s.fullName.trim().isEmpty ? s.username : s.fullName,
                      subtitle: '@${s.username}',
                      trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                        AppBadge(s.roleLabel, color: _badge(s.staffRole)),
                        const SizedBox(height: 6),
                        AppBadge(s.active ? 'Hoạt động' : 'Đã khóa', color: s.active ? BadgeColor.green : BadgeColor.gray),
                      ]),
                    ),
                ]),
              ),
            const SectionHeader('Phân quyền theo vai trò'),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: _matrix(context),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton('Tùy chỉnh vai trò', icon: 'settings', block: true, variant: BtnVariant.ghost,
                  onTap: () => context.shell.toast('Tùy chỉnh vai trò & quyền', 'settings')),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _matrix(BuildContext context) {
    final p = context.palette;
    Widget headerCell(String t) => SizedBox(
        width: 46, child: Text(t, textAlign: TextAlign.center, style: AppType.body(size: 10, weight: FontWeight.w800, color: p.ink2, height: 1.1)));
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line2, width: 2))),
        child: Row(children: [
          Expanded(child: Text('QUYỀN HẠN', style: AppType.body(size: 11.5, weight: FontWeight.w700, color: p.ink2, letterSpacing: 0.3))),
          for (final r in _roles) headerCell(r[1]),
        ]),
      ),
      for (final perm in Seed.perms)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
          child: Row(children: [
            Expanded(child: Text(perm[0] as String, style: AppType.body(size: 12.5, weight: FontWeight.w700, color: p.ink))),
            for (final r in _roles)
              SizedBox(
                width: 46,
                child: Center(
                  child: (perm[1] as List).contains(r[0])
                      ? Text('✓', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.greenD))
                      : Text('–', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.faint)),
                ),
              ),
          ]),
        ),
    ]);
  }
}

/// Duyệt huỷ / hoàn tiền — Manager approves cashier void/refund requests.
class VoidRefundScreen extends StatefulWidget {
  const VoidRefundScreen({super.key});
  @override
  State<VoidRefundScreen> createState() => _VoidRefundScreenState();
}

class _VoidRefundScreenState extends State<VoidRefundScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    final a = context.read<AdminDataController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => a.ensureVoidRefund());
  }

  String _fmt(DateTime? t) {
    if (t == null) return '';
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)} ${two(l.day)}/${two(l.month)}';
  }

  Future<void> _decide(AdminDataController a, VoidRefundRequest r, bool approve) async {
    final err = await a.decideVoidRefund(r.id, approve: approve);
    if (!mounted) return;
    context.shell.toast(
        err ?? (approve ? 'Đã duyệt ${r.billCode}' : 'Đã từ chối ${r.billCode}'), err == null ? 'check' : 'edit');
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    final q = _search.trim().toLowerCase();
    final rows = q.isEmpty
        ? a.vrRequests
        : a.vrRequests
            .where((r) =>
                r.billCode.toLowerCase().contains(q) ||
                r.type.toLowerCase().contains(q) ||
                r.status.toLowerCase().contains(q) ||
                (r.reason ?? '').toLowerCase().contains(q))
            .toList();

    return Column(children: [
      BackBar(title: 'Duyệt huỷ / hoàn', sub: a.vrLoaded ? '${a.vrPendingCount} chờ duyệt' : 'Đang tải…'),
      SearchField(hint: 'Tìm mã HĐ / loại / lý do...', value: _search, onChanged: (v) => setState(() => _search = v)),
      Expanded(child: _body(context, a, p, rows)),
    ]);
  }

  Widget _body(BuildContext context, AdminDataController a, Palette p, List<VoidRefundRequest> rows) {
    if (a.vrLoading && !a.vrLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (a.vrError != null && !a.vrLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(a.vrError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => a.loadVoidRefund()),
        ]),
      );
    }
    if (rows.isEmpty) {
      return const EmptyState(emoji: '✅', title: 'Không có yêu cầu', sub: 'Yêu cầu huỷ/hoàn từ thu ngân sẽ hiện ở đây');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _card(context, a, p, rows[i]),
    );
  }

  Widget _card(BuildContext context, AdminDataController a, Palette p, VoidRefundRequest r) {
    final statusColor = switch (r.status) {
      'APPROVED' => BadgeColor.green,
      'REJECTED' => BadgeColor.red,
      _ => BadgeColor.gray,
    };
    final busy = a.vrBusy(r.id);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AppBadge(r.isVoid ? 'HUỶ' : 'HOÀN', color: r.isVoid ? BadgeColor.red : BadgeColor.amber),
          const SizedBox(width: 8),
          Flexible(child: Text(r.billCode, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppType.body(size: 14.5, weight: FontWeight.w800, color: p.ink))),
          const SizedBox(width: 8),
          Text(vnd(r.displayAmount), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
          const Spacer(),
          AppBadge(r.status, color: statusColor),
        ]),
        if ((r.reason ?? '').isNotEmpty || r.createdAt != null) ...[
          const SizedBox(height: 6),
          Text('${r.reason ?? ''}${r.reason != null && r.createdAt != null ? ' · ' : ''}${_fmt(r.createdAt)}',
              style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        ],
        if (r.isPending) ...[
          const SizedBox(height: 11),
          Row(children: [
            Expanded(
              child: AppButton(busy ? '...' : 'Từ chối', variant: BtnVariant.ghost, textColor: p.red, enabled: !busy,
                  onTap: () => _decide(a, r, false)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(busy ? '...' : 'Duyệt', variant: BtnVariant.pri, enabled: !busy,
                  onTap: () => _decide(a, r, true)),
            ),
          ]),
        ],
      ]),
    );
  }
}

String _vStatusLabel(String s) => switch (s) {
      'ACTIVE' => 'Đang chạy',
      'INACTIVE' => 'Tạm tắt',
      'EXPIRED' => 'Hết hạn',
      'USED_UP' => 'Hết lượt',
      _ => s,
    };
BadgeColor _vStatusColor(String s) => switch (s) {
      'ACTIVE' => BadgeColor.green,
      'EXPIRED' => BadgeColor.red,
      'USED_UP' => BadgeColor.amber,
      _ => BadgeColor.gray,
    };
String _vDmy(DateTime? d) => d == null
    ? '—'
    : '${d.toLocal().day.toString().padLeft(2, '0')}/${d.toLocal().month.toString().padLeft(2, '0')}/${d.toLocal().year}';

/// Voucher / Khuyến mãi — real CRUD against /admin/vouchers.
class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});
  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    final a = context.read<AdminDataController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => a.ensureVouchers());
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    final q = _search.trim().toLowerCase();
    final rows = q.isEmpty
        ? a.vouchers
        : a.vouchers
            .where((v) =>
                v.code.toLowerCase().contains(q) ||
                v.name.toLowerCase().contains(q) ||
                _vStatusLabel(v.status).toLowerCase().contains(q))
            .toList();
    final active = a.vouchers.where((v) => v.isActive).length;

    return Column(children: [
      BackBar(title: 'Voucher / Khuyến mãi', sub: a.vouchersLoaded ? '$active đang chạy · ${a.vouchers.length} mã' : 'Đang tải…'),
      SectionHeader('Mã giảm giá', action: '+ Tạo', onAction: () => openVoucherForm(context)),
      SearchField(hint: 'Tìm mã / tên / trạng thái...', value: _search, onChanged: (v) => setState(() => _search = v)),
      Expanded(child: _body(context, a, p, rows)),
    ]);
  }

  Widget _body(BuildContext context, AdminDataController a, Palette p, List<Voucher> rows) {
    if (a.vouchersLoading && !a.vouchersLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (a.vouchersError != null && !a.vouchersLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(a.vouchersError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => a.loadVouchers()),
        ]),
      );
    }
    if (rows.isEmpty) {
      return const EmptyState(emoji: '🎟️', title: 'Chưa có voucher', sub: 'Bấm "+ Tạo" để thêm mã giảm giá');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _card(context, p, rows[i]),
    );
  }

  Widget _card(BuildContext context, Palette p, Voucher v) {
    final discount = v.isPercent
        ? '${v.discountValue}%${v.maxDiscount != null && v.maxDiscount! > 0 ? ' (≤${vnd(v.maxDiscount!)})' : ''}'
        : vnd(v.discountValue);
    final validity = (v.startsAt != null || v.endsAt != null)
        ? '${_vDmy(v.startsAt)} → ${_vDmy(v.endsAt)}'
        : 'Không giới hạn thời gian';
    return GestureDetector(
      onTap: () => openVoucherForm(context, existing: v),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(v.code, style: AppType.body(size: 14.5, weight: FontWeight.w800, color: p.ink)),
            const SizedBox(width: 8),
            AppBadge(_vStatusLabel(v.status), color: _vStatusColor(v.status)),
            const Spacer(),
            Text(discount, style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
          ]),
          const SizedBox(height: 4),
          Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppType.body(size: 13.5, weight: FontWeight.w600, color: p.ink2)),
          const SizedBox(height: 3),
          Text('Đã dùng ${v.usageCount}${v.usageLimit != null ? '/${v.usageLimit}' : ''} · $validity',
              style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted)),
        ]),
      ),
    );
  }
}

/// Create / edit a voucher.
void openVoucherForm(BuildContext context, {Voucher? existing}) {
  context.shell.showSheet((_) => _VoucherFormSheet(existing: existing));
}

class _VoucherFormSheet extends StatefulWidget {
  final Voucher? existing;
  const _VoucherFormSheet({this.existing});
  @override
  State<_VoucherFormSheet> createState() => _VoucherFormSheetState();
}

class _VoucherFormSheetState extends State<_VoucherFormSheet> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _value;
  late final TextEditingController _maxDiscount;
  late final TextEditingController _minOrder;
  late final TextEditingController _usageLimit;
  late String _type; // PERCENTAGE | FIXED_AMOUNT
  late String _status;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _code = TextEditingController(text: v?.code ?? '');
    _name = TextEditingController(text: v?.name ?? '');
    _value = TextEditingController(text: v != null ? '${v.discountValue}' : '');
    _maxDiscount = TextEditingController(text: (v?.maxDiscount ?? 0) > 0 ? '${v!.maxDiscount}' : '');
    _minOrder = TextEditingController(text: (v?.minOrderAmount ?? 0) > 0 ? '${v!.minOrderAmount}' : '');
    _usageLimit = TextEditingController(text: v?.usageLimit != null ? '${v!.usageLimit}' : '');
    _type = v?.discountType ?? 'PERCENTAGE';
    _status = v?.status ?? 'ACTIVE';
    _startsAt = v?.startsAt;
    _endsAt = v?.endsAt;
  }

  @override
  void dispose() {
    for (final c in [_code, _name, _value, _maxDiscount, _minOrder, _usageLimit]) {
      c.dispose();
    }
    super.dispose();
  }

  int _i(TextEditingController c) => int.tryParse(c.text.trim().replaceAll('.', '')) ?? 0;
  String? _iso(DateTime? d, {bool end = false}) =>
      d == null ? null : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${end ? '23:59:59' : '00:00:00'}';

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: (start ? _startsAt : _endsAt) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (d != null && mounted) setState(() => start ? _startsAt = d : _endsAt = d);
  }

  Future<void> _submit() async {
    final a = context.read<AdminDataController>();
    final code = _code.text.trim().toUpperCase();
    final name = _name.text.trim();
    final value = _i(_value);
    if (!_isEdit && (code.length < 2 || name.isEmpty)) {
      context.shell.toast('Nhập mã (≥2 ký tự) và tên', 'edit');
      return;
    }
    setState(() => _busy = true);
    final maxD = _type == 'PERCENTAGE' && _i(_maxDiscount) > 0 ? _i(_maxDiscount) : null;
    final usage = _i(_usageLimit) > 0 ? _i(_usageLimit) : null;
    String? err;
    if (_isEdit) {
      err = await a.updateVoucher(widget.existing!.id,
          name: name, discountValue: value, minOrderAmount: _i(_minOrder),
          maxDiscount: maxD, usageLimit: usage, status: _status,
          startsAt: _iso(_startsAt), endsAt: _iso(_endsAt, end: true));
    } else {
      err = await a.createVoucher(
          code: code, name: name, discountType: _type, discountValue: value,
          minOrderAmount: _i(_minOrder), maxDiscount: maxD, usageLimit: usage,
          startsAt: _iso(_startsAt), endsAt: _iso(_endsAt, end: true));
    }
    if (!mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast(_isEdit ? 'Đã lưu voucher' : 'Đã tạo voucher $code', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }

  Future<void> _delete() async {
    final a = context.read<AdminDataController>();
    setState(() => _busy = true);
    final err = await a.deleteVoucher(widget.existing!.id);
    if (!mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast('Đã xoá voucher ${widget.existing!.code}', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppSheet(
      title: _isEdit ? 'Sửa voucher' : 'Tạo voucher',
      headerExtra: _isEdit ? [AppBadge(widget.existing!.code, color: BadgeColor.gray)] : const [],
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!_isEdit) ...[
          _label(p, 'Mã voucher'),
          _input(p, _code, hint: 'VD: WELCOME10', caps: true),
          const SizedBox(height: 12),
        ],
        _label(p, 'Tên chương trình'),
        _input(p, _name, hint: 'VD: Giảm 10% đơn đầu'),
        const SizedBox(height: 12),
        if (!_isEdit) ...[
          _label(p, 'Loại giảm'),
          Segmented(
            labels: const ['% Phần trăm', 'Số tiền'],
            active: _type == 'PERCENTAGE' ? 0 : 1,
            onTap: (i) => setState(() => _type = i == 0 ? 'PERCENTAGE' : 'FIXED_AMOUNT'),
          ),
          const SizedBox(height: 12),
        ],
        _label(p, _type == 'PERCENTAGE' ? 'Phần trăm giảm (%)' : 'Số tiền giảm (đ)'),
        _input(p, _value, hint: _type == 'PERCENTAGE' ? 'VD: 10' : 'VD: 20000', number: true),
        if (_type == 'PERCENTAGE') ...[
          const SizedBox(height: 12),
          _label(p, 'Giảm tối đa (đ) — để trống nếu không giới hạn'),
          _input(p, _maxDiscount, hint: 'VD: 30000', number: true),
        ],
        const SizedBox(height: 12),
        _label(p, 'Đơn tối thiểu (đ)'),
        _input(p, _minOrder, hint: '0', number: true),
        const SizedBox(height: 12),
        _label(p, 'Giới hạn lượt dùng — để trống nếu không giới hạn'),
        _input(p, _usageLimit, hint: 'VD: 100', number: true),
        const SizedBox(height: 12),
        _label(p, 'Hiệu lực (tuỳ chọn)'),
        Row(children: [
          Expanded(child: _dateBtn(p, 'Từ: ${_vDmy(_startsAt)}', () => _pickDate(true), _startsAt != null, () => setState(() => _startsAt = null))),
          const SizedBox(width: 10),
          Expanded(child: _dateBtn(p, 'Đến: ${_vDmy(_endsAt)}', () => _pickDate(false), _endsAt != null, () => setState(() => _endsAt = null))),
        ]),
        if (_isEdit) ...[
          const SizedBox(height: 12),
          _label(p, 'Trạng thái'),
          Segmented(
            labels: const ['Đang chạy', 'Tạm tắt'],
            active: _status == 'ACTIVE' ? 0 : 1,
            onTap: (i) => setState(() => _status = i == 0 ? 'ACTIVE' : 'INACTIVE'),
          ),
        ],
      ]),
      footer: _isEdit
          ? Row(children: [
              AppButton('Xoá', large: true, variant: BtnVariant.soft, textColor: p.red, onTap: _busy ? null : _delete),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(_busy ? 'Đang lưu…' : 'Lưu', icon: 'check', large: true, block: true,
                    enabled: !_busy, onTap: _submit),
              ),
            ])
          : AppButton(_busy ? 'Đang tạo…' : 'Tạo voucher', icon: 'check', large: true, block: true,
              enabled: !_busy, onTap: _submit),
    );
  }

  Widget _label(Palette p, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(t, style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.ink2)),
      );

  Widget _input(Palette p, TextEditingController c, {String? hint, bool number = false, bool caps = false}) => TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.none,
        style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppType.body(size: 14.5, weight: FontWeight.w500, color: p.faint),
          filled: true,
          fillColor: p.paper,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
        ),
      );

  Widget _dateBtn(Palette p, String label, VoidCallback onPick, bool hasValue, VoidCallback onClear) => GestureDetector(
        onTap: onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(13), border: Border.all(color: p.line2, width: 1.5)),
          child: Row(children: [
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppType.body(size: 13, weight: FontWeight.w700, color: hasValue ? p.ink : p.muted)),
            ),
            if (hasValue)
              GestureDetector(onTap: onClear, child: Icon(Icons.close_rounded, size: 16, color: p.muted)),
          ]),
        ),
      );
}

/// Chi nhánh — real branches (GET /admin/branches). Manager sees only their
/// own branch and can edit its details + cash thresholds (PATCH).
class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});
  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  @override
  void initState() {
    super.initState();
    final a = context.read<AdminDataController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => a.ensureBranches());
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    return Column(children: [
      BackBar(title: 'Chi nhánh', sub: a.branchesLoaded ? '${a.branches.length} cửa hàng' : 'Đang tải…'),
      Expanded(child: _body(context, a, p)),
    ]);
  }

  Widget _body(BuildContext context, AdminDataController a, Palette p) {
    if (a.branchesLoading && !a.branchesLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (a.branchesError != null && !a.branchesLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🏪', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(a.branchesError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => a.loadBranches()),
        ]),
      );
    }
    if (a.branches.isEmpty) {
      return const EmptyState(emoji: '🏪', title: 'Không có chi nhánh', sub: '');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: [for (final b in a.branches) _card(context, p, b)],
    );
  }

  Widget _card(BuildContext context, Palette p, Branch b) {
    return GestureDetector(
      onTap: () => openBranchForm(context, b),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            LeadIcon(icon: 'store', bg: p.greenBg, fg: p.greenD),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppType.body(size: 15.5, weight: FontWeight.w800, color: p.ink)),
                const SizedBox(height: 2),
                Text(b.code, style: AppType.body(size: 12, weight: FontWeight.w700, color: p.muted)),
              ]),
            ),
            Icon(Icons.edit_outlined, size: 16, color: p.faint),
          ]),
          if ((b.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(b.address!, style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2, height: 1.35)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _kv(p, 'Hạn mức rút quỹ', vnd(b.cashOutLimit))),
            Expanded(child: _kv(p, 'Ngưỡng lệch quỹ', vnd(b.cashDiffThreshold))),
            if ((b.phone ?? '').isNotEmpty) Expanded(child: _kv(p, 'SĐT', b.phone!)),
          ]),
        ]),
      ),
    );
  }

  Widget _kv(Palette p, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppType.body(size: 10.5, weight: FontWeight.w700, color: p.muted)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink)),
        ],
      );
}

void openBranchForm(BuildContext context, Branch b) {
  context.shell.showSheet((_) => _BranchFormSheet(branch: b));
}

class _BranchFormSheet extends StatefulWidget {
  final Branch branch;
  const _BranchFormSheet({required this.branch});
  @override
  State<_BranchFormSheet> createState() => _BranchFormSheetState();
}

class _BranchFormSheetState extends State<_BranchFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _cashOut;
  late final TextEditingController _cashDiff;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _name = TextEditingController(text: b.name);
    _address = TextEditingController(text: b.address ?? '');
    _phone = TextEditingController(text: b.phone ?? '');
    _cashOut = TextEditingController(text: '${b.cashOutLimit}');
    _cashDiff = TextEditingController(text: '${b.cashDiffThreshold}');
  }

  @override
  void dispose() {
    for (final c in [_name, _address, _phone, _cashOut, _cashDiff]) {
      c.dispose();
    }
    super.dispose();
  }

  int _i(TextEditingController c) => int.tryParse(c.text.trim().replaceAll('.', '')) ?? 0;

  Future<void> _submit() async {
    final a = context.read<AdminDataController>();
    final name = _name.text.trim();
    if (name.isEmpty) {
      context.shell.toast('Nhập tên chi nhánh', 'edit');
      return;
    }
    setState(() => _busy = true);
    final err = await a.updateBranch(widget.branch.id,
        name: name,
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        cashOutLimit: _i(_cashOut),
        cashDiffThreshold: _i(_cashDiff));
    if (!mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast('Đã lưu chi nhánh', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppSheet(
      title: 'Sửa chi nhánh',
      headerExtra: [AppBadge(widget.branch.code, color: BadgeColor.gray)],
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _l(p, 'Tên chi nhánh'),
        _f(p, _name, hint: 'VD: Coffee Mỹ Nhân'),
        const SizedBox(height: 12),
        _l(p, 'Địa chỉ'),
        _f(p, _address, hint: 'Số nhà, đường, phường...'),
        const SizedBox(height: 12),
        _l(p, 'Số điện thoại'),
        _f(p, _phone, hint: '09xxxxxxxx', number: true),
        const SizedBox(height: 12),
        _l(p, 'Hạn mức rút quỹ (đ) — vượt phải Manager duyệt'),
        _f(p, _cashOut, hint: 'VD: 500000', number: true),
        const SizedBox(height: 12),
        _l(p, 'Ngưỡng cảnh báo lệch quỹ (đ)'),
        _f(p, _cashDiff, hint: 'VD: 20000', number: true),
      ]),
      footer: AppButton(_busy ? 'Đang lưu…' : 'Lưu chi nhánh', icon: 'check', large: true, block: true,
          enabled: !_busy, onTap: _submit),
    );
  }

  Widget _l(Palette p, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(t, style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.ink2)),
      );

  Widget _f(Palette p, TextEditingController c, {String? hint, bool number = false}) => TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppType.body(size: 14.5, weight: FontWeight.w500, color: p.faint),
          filled: true,
          fillColor: p.paper,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
        ),
      );
}

/// Ca làm việc (admin view).
class ShiftAdminScreen extends StatelessWidget {
  const ShiftAdminScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    return Column(children: [
      BackBar(title: 'Ca làm việc', sub: 'Hôm nay · ${state.adminBranch}'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                Expanded(child: StatCard(icon: 'clock', bg: p.greenBg, fg: p.greenD, value: '2', label: 'Ca đang mở')),
                const SizedBox(width: 10),
                Expanded(child: StatCard(icon: 'cash', bg: const Color(0xFFFCE8DF), fg: p.terracotta, value: kShort(4820000), label: 'Tiền mặt hiện có')),
              ]),
            ),
            const SectionHeader('Ca hôm nay'),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                ListRow(
                  leading: LeadIcon(emoji: '🟢', bg: p.greenBg),
                  title: 'Ca sáng · 06:00–14:00',
                  subtitle: 'Trần Thị Bình · đã đóng',
                  trailing: Text('2.1tr', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
                ),
                ListRow(
                  leading: LeadIcon(emoji: '🟢', bg: p.greenBg),
                  title: 'Ca chiều · 14:00–22:00',
                  subtitle: 'Lê Minh Châu · đang mở',
                  trailing: Text('2.7tr', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton('Lịch sử đối soát', icon: 'history', block: true, variant: BtnVariant.ghost,
                  onTap: () => context.shell.toast('Xem lịch sử đối soát ca', 'history')),
            ),
          ],
        ),
      ),
    ]);
  }
}
