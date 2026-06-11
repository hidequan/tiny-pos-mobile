import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/admin_data_controller.dart';
import '../../state/session.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';

const _roleOptions = [
  ['CASHIER', 'Thu ngân'],
  ['BARISTA', 'Pha chế'],
  ['MANAGER', 'Quản lý'],
];

/// Create a staff account (writes via AdminDataController, reloads the list).
void openStaffForm(BuildContext context) {
  context.shell.showSheet((_) => const _StaffForm());
}

class _StaffForm extends StatefulWidget {
  const _StaffForm();
  @override
  State<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<_StaffForm> {
  final _name = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  String _role = 'CASHIER';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: AppType.body(size: 14.5, weight: FontWeight.w500, color: p.faint),
          filled: true,
          fillColor: p.paper,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
        );

    Widget field(String label, Widget child) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(label, style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink)),
            ),
            child,
          ]),
        );

    return AppSheet(
      title: 'Thêm nhân viên',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        field('Họ và tên', TextField(controller: _name, style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink), decoration: deco('VD: Nguyễn Văn A'))),
        field('Tên đăng nhập', TextField(
          controller: _user,
          autocorrect: false,
          enableSuggestions: false,
          style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink),
          decoration: deco('VD: cashier05'),
        )),
        field('Mật khẩu', TextField(
          controller: _pass,
          obscureText: true,
          style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink),
          decoration: deco('Tối thiểu 6 ký tự'),
        )),
        field('Vai trò', Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in _roleOptions)
            PillChip(r[1], on: _role == r[0], onTap: () => setState(() => _role = r[0])),
        ])),
      ]),
      footer: AppButton(
        _busy ? 'Đang tạo...' : 'Tạo nhân viên',
        icon: 'check',
        large: true,
        block: true,
        enabled: !_busy,
        onTap: () => _save(context),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final name = _name.text.trim();
    final user = _user.text.trim();
    final pass = _pass.text;
    if (name.isEmpty) return context.shell.toast('Nhập họ tên', 'edit');
    if (user.length < 3) return context.shell.toast('Tên đăng nhập tối thiểu 3 ký tự', 'edit');
    if (pass.length < 6) return context.shell.toast('Mật khẩu tối thiểu 6 ký tự', 'edit');
    setState(() => _busy = true);
    final admin = context.read<AdminDataController>();
    final branchId = context.read<SessionState>().user?.branchId;
    final err = await admin.createStaff(
        username: user, password: pass, fullName: name, staffRole: _role, branchId: branchId);
    if (!context.mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast('Đã thêm $name', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }
}
