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

const _hwTypes = ['BILL_PRINTER', 'STICKER_PRINTER', 'CASH_DRAWER', 'KDS_SCREEN', 'POS_TERMINAL'];
const _hwTypeLabel = {
  'BILL_PRINTER': 'Máy in bill',
  'STICKER_PRINTER': 'Máy in tem',
  'CASH_DRAWER': 'Két tiền',
  'KDS_SCREEN': 'Màn bếp/bar',
  'POS_TERMINAL': 'Máy POS',
};
const _connTypes = ['AGENT', 'USB', 'NETWORK', 'BLUETOOTH', 'SERIAL'];
const _jobTypes = ['BILL', 'STICKER', 'KITCHEN_TICKET'];
const _jobLabel = {'BILL': 'Hoá đơn (BILL)', 'STICKER': 'Tem ly (STICKER)', 'KITCHEN_TICKET': 'Phiếu bếp (KITCHEN)'};
bool _isPrinter(String t) => t == 'BILL_PRINTER' || t == 'STICKER_PRINTER';
const _teal = Color(0xFF3E7C74);

/// Thiết bị & Máy in — devices, print routes, cash-drawer audit. Ported from the
/// web admin/hardware page (+ a read-only drawer-event log).
class HardwareScreen extends StatefulWidget {
  const HardwareScreen({super.key});
  @override
  State<HardwareScreen> createState() => _HardwareScreenState();
}

class _HardwareScreenState extends State<HardwareScreen> {
  int _tab = 0; // 0 devices, 1 routes, 2 drawer events
  String? get _branchId => context.read<SessionState>().user?.branchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = _branchId;
      if (mounted && b != null) context.read<AdminDataController>().ensureHardware(b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    final branchId = _branchId;
    return Column(children: [
      BackBar(
        title: 'Thiết bị & Máy in',
        sub: a.hwLoaded ? '${a.devices.length} thiết bị · ${a.printRoutes.length} route' : 'Đang tải…',
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: Segmented(
          labels: const ['Thiết bị', 'Định tuyến', 'Mở két'],
          active: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
      ),
      Expanded(child: branchId == null ? _noBranch(p) : _body(context, a, p, branchId)),
    ]);
  }

  Widget _noBranch(Palette p) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text('Tài khoản không thuộc chi nhánh nào.', textAlign: TextAlign.center, style: AppType.body(size: 14, color: p.muted)),
        ),
      );

  Widget _body(BuildContext context, AdminDataController a, Palette p, String branchId) {
    if (a.hwLoading && !a.hwLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (a.hwError != null && !a.hwLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🖨️', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(a.hwError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => a.loadHardware(branchId)),
        ]),
      );
    }
    return switch (_tab) {
      1 => _routesTab(context, a, p, branchId),
      2 => _drawerTab(context, a, p),
      _ => _devicesTab(context, a, p, branchId),
    };
  }

  // ===== Devices =====
  Widget _devicesTab(BuildContext context, AdminDataController a, Palette p, String branchId) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Text(
            'Máy in nhiệt 80mm (vd Xprinter XP-80C) cài qua POS Agent — đặt "Kết nối = AGENT" và nhập đúng Tên máy in Windows (vd XP-80C) để in/cắt giấy & mở két.',
            style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted, height: 1.4),
          ),
        ),
        SectionHeader('Thiết bị phần cứng', action: '+ Thêm', onAction: () => _openDeviceForm(context, branchId)),
        if (a.devices.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 8), child: EmptyState(emoji: '🖨️', title: 'Chưa có thiết bị', sub: 'Bấm "+ Thêm" để khai báo máy in / két'))
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [for (final d in a.devices) _deviceCard(context, a, p, branchId, d)]),
          ),
      ],
    );
  }

  Widget _deviceCard(BuildContext context, AdminDataController a, Palette p, String branchId, HwDevice d) {
    final busy = a.hwBusy(d.id);
    final detail = d.printerName != null && d.printerName!.isNotEmpty
        ? '🖨 ${d.printerName}'
        : (d.address != null && d.address!.isNotEmpty ? d.address! : '');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: d.isActive ? p.greenD : p.line2),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppType.body(size: 14.5, weight: FontWeight.w800, color: p.ink))),
          const SizedBox(width: 8),
          AppBadge(_hwTypeLabel[d.type] ?? d.type, color: _isPrinter(d.type) ? BadgeColor.amber : BadgeColor.blue),
        ]),
        const SizedBox(height: 5),
        Text('${d.connectionType}${detail.isNotEmpty ? ' · $detail' : ''}',
            style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (_isPrinter(d.type)) ...[
            _miniBtn(p, busy ? '...' : 'In thử', _teal, busy ? null : () => _testPrint(context, a, d)),
            const SizedBox(width: 14),
          ],
          _miniBtn(p, 'Sửa', p.caramel, () => _openDeviceForm(context, branchId, existing: d)),
          const SizedBox(width: 14),
          _miniBtn(p, 'Xoá', p.red, () => _confirmDelete(context, 'thiết bị "${d.name}"', () async {
            final err = await a.removeDevice(branchId, d.id);
            if (context.mounted) context.shell.toast(err ?? 'Đã xoá thiết bị', err == null ? 'check' : 'edit');
          })),
        ]),
      ]),
    );
  }

  Future<void> _testPrint(BuildContext context, AdminDataController a, HwDevice d) async {
    final r = await a.testPrint(d.id);
    if (!context.mounted || r.message.isEmpty) return;
    context.shell.toast(r.message, r.ok ? 'check' : 'edit');
  }

  // ===== Routes =====
  Widget _routesTab(BuildContext context, AdminDataController a, Palette p, String branchId) {
    final printers = a.devices.where((d) => _isPrinter(d.type)).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Text('Loại chứng từ nào in ra máy nào (BILL → máy in bill, tem ly → máy in tem…).',
              style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted, height: 1.4)),
        ),
        SectionHeader('Định tuyến in', action: '+ Thêm', onAction: printers.isEmpty
            ? () => context.shell.toast('Thêm máy in trước đã', 'edit')
            : () => _openRouteForm(context, branchId, printers)),
        if (a.printRoutes.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: EmptyState(emoji: '🧭', title: 'Chưa có route', sub: 'Hệ thống sẽ in ra máy mặc định của agent'),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              for (final route in a.printRoutes)
                Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                  decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
                  child: Row(children: [
                    AppBadge(route.jobType, color: BadgeColor.gray),
                    const SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded, size: 15, color: p.faint),
                    const SizedBox(width: 10),
                    Expanded(child: Text(route.hardwareName ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: AppType.body(size: 14, weight: FontWeight.w700, color: p.ink))),
                    _miniBtn(p, 'Xoá', p.red, () => _confirmDelete(context, 'route ${route.jobType}', () async {
                      final err = await a.removeRoute(branchId, route.id);
                      if (context.mounted) context.shell.toast(err ?? 'Đã xoá route', err == null ? 'check' : 'edit');
                    })),
                  ]),
                ),
            ]),
          ),
      ],
    );
  }

  // ===== Drawer events =====
  Widget _drawerTab(BuildContext context, AdminDataController a, Palette p) {
    if (a.drawerEvents.isEmpty) {
      return const EmptyState(emoji: '💵', title: 'Chưa có lần mở két', sub: 'Lịch sử mở két tiền sẽ hiện ở đây');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      itemCount: a.drawerEvents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = a.drawerEvents[i];
        final ok = e.type == 'OPENED' || e.type == 'SUCCESS' || e.type == 'OPEN';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
          child: Row(children: [
            Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded, size: 18, color: ok ? p.greenD : p.red),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(e.type, style: AppType.body(size: 13.5, weight: FontWeight.w800, color: ok ? p.greenD : p.red)),
                if ((e.reason ?? '').isNotEmpty)
                  Text(e.reason!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted)),
              ]),
            ),
            Text(_fmt(e.createdAt), style: AppType.body(size: 11.5, weight: FontWeight.w600, color: p.faint)),
          ]),
        );
      },
    );
  }

  String _fmt(DateTime? t) {
    if (t == null) return '';
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)} ${two(l.day)}/${two(l.month)}';
  }

  Widget _miniBtn(Palette p, String label, Color color, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Text(label, style: AppType.body(size: 13, weight: FontWeight.w800, color: onTap == null ? p.muted : color)),
      );

  void _confirmDelete(BuildContext context, String what, Future<void> Function() onConfirm) {
    context.shell.showSheet((_) => AppSheet(
          title: 'Xoá $what?',
          body: Builder(builder: (context) {
            final p = context.palette;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Thao tác này không thể hoàn tác.', style: AppType.body(size: 14, weight: FontWeight.w600, color: p.ink2)),
            );
          }),
          footer: Builder(builder: (context) {
            final p = context.palette;
            return Row(children: [
              AppButton('Huỷ', large: true, variant: BtnVariant.soft, onTap: () => context.shell.closeSheet()),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton('Xoá', icon: 'logout', large: true, block: true, variant: BtnVariant.pri, textColor: p.red, onTap: () {
                  context.shell.closeSheet();
                  onConfirm();
                }),
              ),
            ]);
          }),
        ));
  }

  void _openDeviceForm(BuildContext context, String branchId, {HwDevice? existing}) {
    context.shell.showSheet((_) => _DeviceFormSheet(branchId: branchId, existing: existing));
  }

  void _openRouteForm(BuildContext context, String branchId, List<HwDevice> printers) {
    context.shell.showSheet((_) => _RouteFormSheet(branchId: branchId, printers: printers));
  }
}

// ---- device form ----------------------------------------------------------
class _DeviceFormSheet extends StatefulWidget {
  final String branchId;
  final HwDevice? existing;
  const _DeviceFormSheet({required this.branchId, this.existing});
  @override
  State<_DeviceFormSheet> createState() => _DeviceFormSheetState();
}

class _DeviceFormSheetState extends State<_DeviceFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _printerName;
  late final TextEditingController _address;
  late String _type;
  late String _conn;
  late bool _active;
  bool _busy = false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _name = TextEditingController(text: d?.name ?? '');
    _printerName = TextEditingController(text: d?.printerName ?? 'XP-80C');
    _address = TextEditingController(text: d?.address ?? '');
    _type = d?.type ?? 'BILL_PRINTER';
    _conn = d?.connectionType ?? 'AGENT';
    _active = d?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _printerName.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final a = context.read<AdminDataController>();
    final name = _name.text.trim();
    if (name.isEmpty) {
      context.shell.toast('Nhập tên thiết bị', 'edit');
      return;
    }
    setState(() => _busy = true);
    final err = await a.saveDevice(widget.branchId,
        id: widget.existing?.id,
        name: name,
        type: _type,
        connectionType: _conn,
        address: _address.text.trim(),
        printerName: _printerName.text.trim(),
        isActive: _isEdit ? _active : null);
    if (!mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast(_isEdit ? 'Đã lưu thiết bị' : 'Đã thêm thiết bị', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final printer = _isPrinter(_type);
    return AppSheet(
      title: _isEdit ? 'Sửa thiết bị' : 'Thêm thiết bị',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(p, 'Tên thiết bị'),
        _field(p, _name, hint: 'VD: Máy in bill quầy 1'),
        const SizedBox(height: 12),
        _label(p, 'Loại thiết bị'),
        _chips(p, _hwTypes, _type, (v) => setState(() => _type = v), (v) => _hwTypeLabel[v] ?? v),
        const SizedBox(height: 12),
        _label(p, 'Kết nối'),
        _chips(p, _connTypes, _conn, (v) => setState(() => _conn = v), (v) => v),
        const SizedBox(height: 12),
        if (printer) ...[
          _label(p, 'Tên máy in Windows (cho POS Agent)'),
          _field(p, _printerName, hint: 'VD: XP-80C'),
        ] else ...[
          _label(p, 'IP / địa chỉ'),
          _field(p, _address, hint: 'VD: 192.168.1.50'),
        ],
        if (_isEdit) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => setState(() => _active = !_active),
            child: Row(children: [
              Icon(_active ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 22, color: _active ? p.greenD : p.line2),
              const SizedBox(width: 10),
              Text('Đang hoạt động', style: AppType.body(size: 14, weight: FontWeight.w700, color: p.ink)),
            ]),
          ),
        ],
      ]),
      footer: AppButton(_busy ? 'Đang lưu…' : (_isEdit ? 'Lưu' : 'Thêm thiết bị'), icon: 'check', large: true, block: true, enabled: !_busy, onTap: _submit),
    );
  }

  Widget _label(Palette p, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(t, style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.ink2)),
      );

  Widget _chips(Palette p, List<String> opts, String active, ValueChanged<String> onPick, String Function(String) label) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final o in opts) PillChip(label(o), on: o == active, onTap: () => onPick(o))],
      );

  Widget _field(Palette p, TextEditingController c, {String? hint}) => TextField(
        controller: c,
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

// ---- route form -----------------------------------------------------------
class _RouteFormSheet extends StatefulWidget {
  final String branchId;
  final List<HwDevice> printers;
  const _RouteFormSheet({required this.branchId, required this.printers});
  @override
  State<_RouteFormSheet> createState() => _RouteFormSheetState();
}

class _RouteFormSheetState extends State<_RouteFormSheet> {
  String _jobType = 'BILL';
  String? _hardwareId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _hardwareId = widget.printers.isNotEmpty ? widget.printers.first.id : null;
  }

  Future<void> _submit() async {
    if (_hardwareId == null) {
      context.shell.toast('Chọn thiết bị in', 'edit');
      return;
    }
    final a = context.read<AdminDataController>();
    setState(() => _busy = true);
    final err = await a.createRoute(widget.branchId, jobType: _jobType, hardwareId: _hardwareId!);
    if (!mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast('Đã thêm route', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppSheet(
      title: 'Thêm định tuyến in',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text('Loại chứng từ', style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.ink2)),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final j in _jobTypes) PillChip(_jobLabel[j] ?? j, on: _jobType == j, onTap: () => setState(() => _jobType = j)),
        ]),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text('In ra thiết bị', style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.ink2)),
        ),
        Column(children: [
          for (final d in widget.printers)
            GestureDetector(
              onTap: () => setState(() => _hardwareId = d.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                decoration: BoxDecoration(
                  color: _hardwareId == d.id ? p.greenBg : p.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _hardwareId == d.id ? p.greenD : p.line),
                ),
                child: Row(children: [
                  Icon(_hardwareId == d.id ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      size: 20, color: _hardwareId == d.id ? p.greenD : p.line2),
                  const SizedBox(width: 11),
                  Expanded(child: Text(d.name, style: AppType.body(size: 14, weight: FontWeight.w700, color: p.ink))),
                  AppBadge(_hwTypeLabel[d.type] ?? d.type, color: BadgeColor.amber),
                ]),
              ),
            ),
        ]),
      ]),
      footer: AppButton(_busy ? 'Đang thêm…' : 'Thêm route', icon: 'check', large: true, block: true, enabled: !_busy, onTap: _submit),
    );
  }
}
