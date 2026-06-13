import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session.dart';
import '../../state/admin_data_controller.dart';
import '../../models/admin.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_widgets.dart';

/// Khu vực & Bàn — admin config (CRUD floor areas + tables). Ported from the
/// web admin/tables page. Two-level: pick an area, manage its tables.
class TablesAdminScreen extends StatefulWidget {
  const TablesAdminScreen({super.key});
  @override
  State<TablesAdminScreen> createState() => _TablesAdminScreenState();
}

class _TablesAdminScreenState extends State<TablesAdminScreen> {
  String? get _branchId => context.read<SessionState>().user?.branchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = _branchId;
      if (!mounted || b == null) return;
      final a = context.read<AdminDataController>();
      if (!a.areasLoaded && !a.areasLoading) a.loadAreas(b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    final branchId = _branchId;

    return Column(children: [
      BackBar(title: 'Khu vực & Bàn', sub: a.areasLoaded ? '${a.areas.length} khu vực' : 'Đang tải…'),
      Expanded(child: branchId == null ? _noBranch(p) : _body(context, a, p, branchId)),
    ]);
  }

  Widget _noBranch(Palette p) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text('Tài khoản không thuộc chi nhánh nào.',
              textAlign: TextAlign.center, style: AppType.body(size: 14, color: p.muted)),
        ),
      );

  Widget _body(BuildContext context, AdminDataController a, Palette p, String branchId) {
    if (a.areasLoading && !a.areasLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (a.areasError != null && !a.areasLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🪑', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(a.areasError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => a.loadAreas(branchId)),
        ]),
      );
    }
    final selected = a.areas.where((x) => x.id == a.selectedAreaId).firstOrNull;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionHeader('Khu vực / Tầng', action: '+ Thêm', onAction: () => _openAreaForm(context, branchId)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final area in a.areas)
              PillChip('${area.name} · ${area.tableCount}',
                  on: area.id == a.selectedAreaId, onTap: () => a.selectArea(area.id)),
          ]),
        ),
        if (selected != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              Expanded(
                child: Text('Tầng ${selected.level} · ${selected.tableCount} bàn',
                    style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.muted)),
              ),
              GestureDetector(
                onTap: () => _openAreaForm(context, branchId, existing: selected),
                child: Text('Sửa khu vực', style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.terracotta)),
              ),
            ]),
          ),
          SectionHeader('Bàn trong khu vực', action: '+ Thêm', onAction: () => _openTableForm(context)),
          _tablesBody(context, a, p),
        ],
      ],
    );
  }

  Widget _tablesBody(BuildContext context, AdminDataController a, Palette p) {
    if (a.tablesLoading) {
      return const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()));
    }
    if (a.tablesError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(a.tablesError!, style: AppType.body(size: 13, color: p.muted)),
      );
    }
    if (a.areaTables.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: EmptyState(emoji: '🪑', title: 'Chưa có bàn', sub: 'Bấm "+ Thêm" để thêm bàn vào khu vực'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(spacing: 10, runSpacing: 10, children: [
        for (final tbl in a.areaTables) _tableCard(context, p, tbl),
      ]),
    );
  }

  Widget _tableCard(BuildContext context, Palette p, AdminTable t) {
    return GestureDetector(
      onTap: () => _openTableForm(context, existing: t),
      child: Container(
        width: (MediaQuery.of(context).size.width - 32 - 10) / 2,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(13), border: Border.all(color: p.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
              child: Text(t.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppType.display(size: 18, weight: FontWeight.w700, color: p.ink)),
            ),
            Icon(Icons.edit_outlined, size: 15, color: p.faint),
          ]),
          const SizedBox(height: 4),
          Text('${t.seats} chỗ', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.muted)),
        ]),
      ),
    );
  }

  void _openAreaForm(BuildContext context, String branchId, {FloorArea? existing}) {
    context.shell.showSheet((_) => _AreaFormSheet(branchId: branchId, existing: existing));
  }

  void _openTableForm(BuildContext context, {AdminTable? existing}) {
    context.shell.showSheet((_) => _TableFormSheet(existing: existing));
  }
}

class _AreaFormSheet extends StatefulWidget {
  final String branchId;
  final FloorArea? existing;
  const _AreaFormSheet({required this.branchId, this.existing});
  @override
  State<_AreaFormSheet> createState() => _AreaFormSheetState();
}

class _AreaFormSheetState extends State<_AreaFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _level;
  bool _busy = false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _level = TextEditingController(text: '${widget.existing?.level ?? 1}');
  }

  @override
  void dispose() {
    _name.dispose();
    _level.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final a = context.read<AdminDataController>();
    final name = _name.text.trim();
    if (name.isEmpty) {
      context.shell.toast('Nhập tên khu vực', 'edit');
      return;
    }
    final level = int.tryParse(_level.text.trim()) ?? 1;
    setState(() => _busy = true);
    final err = _isEdit
        ? await a.updateArea(widget.branchId, widget.existing!.id, name: name, level: level)
        : await a.createArea(widget.branchId, name: name, level: level);
    if (!mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast(_isEdit ? 'Đã lưu khu vực' : 'Đã thêm khu vực', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }

  Future<void> _delete() async {
    final a = context.read<AdminDataController>();
    setState(() => _busy = true);
    final err = await a.deleteArea(widget.branchId, widget.existing!.id);
    if (!mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast('Đã xoá khu vực', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppSheet(
      title: _isEdit ? 'Sửa khu vực' : 'Thêm khu vực',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel(p, 'Tên khu vực / tầng'),
        _field(p, _name, hint: 'VD: Tầng 1, Sân vườn'),
        const SizedBox(height: 12),
        _fieldLabel(p, 'Tầng (số)'),
        _field(p, _level, hint: '1', number: true),
      ]),
      footer: _isEdit
          ? Row(children: [
              AppButton('Xoá', large: true, variant: BtnVariant.soft, textColor: p.red, onTap: _busy ? null : _delete),
              const SizedBox(width: 10),
              Expanded(child: AppButton(_busy ? 'Đang lưu…' : 'Lưu', icon: 'check', large: true, block: true, enabled: !_busy, onTap: _submit)),
            ])
          : AppButton(_busy ? 'Đang thêm…' : 'Thêm khu vực', icon: 'check', large: true, block: true, enabled: !_busy, onTap: _submit),
    );
  }
}

class _TableFormSheet extends StatefulWidget {
  final AdminTable? existing;
  const _TableFormSheet({this.existing});
  @override
  State<_TableFormSheet> createState() => _TableFormSheetState();
}

class _TableFormSheetState extends State<_TableFormSheet> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _seats;
  bool _busy = false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.existing?.code ?? '');
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _seats = TextEditingController(text: '${widget.existing?.seats ?? 2}');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _seats.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final a = context.read<AdminDataController>();
    final code = _code.text.trim();
    if (code.isEmpty) {
      context.shell.toast('Nhập mã bàn', 'edit');
      return;
    }
    final seats = int.tryParse(_seats.text.trim()) ?? 2;
    final name = _name.text.trim();
    setState(() => _busy = true);
    final err = _isEdit
        ? await a.updateTable(widget.existing!.id, code: code, name: name.isEmpty ? null : name, seats: seats)
        : await a.createTable(code: code, name: name.isEmpty ? null : name, seats: seats);
    if (!mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast(_isEdit ? 'Đã lưu bàn' : 'Đã thêm bàn $code', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }

  Future<void> _delete() async {
    final a = context.read<AdminDataController>();
    setState(() => _busy = true);
    final err = await a.deleteTable(widget.existing!.id);
    if (!mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast('Đã xoá bàn ${widget.existing!.code}', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppSheet(
      title: _isEdit ? 'Sửa bàn' : 'Thêm bàn',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel(p, 'Mã bàn'),
        _field(p, _code, hint: 'VD: A01'),
        const SizedBox(height: 12),
        _fieldLabel(p, 'Tên hiển thị (tuỳ chọn)'),
        _field(p, _name, hint: 'VD: Bàn cửa sổ'),
        const SizedBox(height: 12),
        _fieldLabel(p, 'Số chỗ'),
        _field(p, _seats, hint: '2', number: true),
      ]),
      footer: _isEdit
          ? Row(children: [
              AppButton('Xoá', large: true, variant: BtnVariant.soft, textColor: p.red, onTap: _busy ? null : _delete),
              const SizedBox(width: 10),
              Expanded(child: AppButton(_busy ? 'Đang lưu…' : 'Lưu', icon: 'check', large: true, block: true, enabled: !_busy, onTap: _submit)),
            ])
          : AppButton(_busy ? 'Đang thêm…' : 'Thêm bàn', icon: 'check', large: true, block: true, enabled: !_busy, onTap: _submit),
    );
  }
}

// Shared field widgets.
Widget _fieldLabel(Palette p, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(t, style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.ink2)),
    );

Widget _field(Palette p, TextEditingController c, {String? hint, bool number = false}) => TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
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
