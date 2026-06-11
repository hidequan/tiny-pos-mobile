import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/session.dart';
import '../../data/models.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';

InputDecoration _dec(BuildContext context, String hint) {
  final p = context.palette;
  return InputDecoration(
    hintText: hint,
    hintStyle: AppType.body(size: 14.5, weight: FontWeight.w500, color: p.faint),
    filled: true,
    fillColor: p.paper,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
  );
}

Widget _fieldLabel(BuildContext context, String t) => Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(t, style: AppType.body(size: 12, weight: FontWeight.w800, color: context.palette.ink2)),
    );

/// Branch picker sheet.
void openBranchPick(BuildContext context) {
  context.shell.showSheet((_) => Consumer<AppState>(builder: (context, state, _) {
        final p = context.palette;
        return AppSheet(
          title: 'Chọn chi nhánh',
          body: CardBox(
            clip: true,
            padding: EdgeInsets.zero,
            child: RowList([
              for (final b in state.branches)
                ListRow(
                  onTap: () {
                    state.setAdminBranch(b.name);
                    context.shell.closeSheet();
                    context.shell.toast('Đã chuyển: ${b.name}', 'store');
                  },
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(b.open ? '🟢' : '⚪', style: const TextStyle(fontSize: 18)),
                  ),
                  title: b.name,
                  subtitle: '${b.addr} · ${b.staff} nhân viên',
                  trailing: b.name == state.adminBranch
                      ? Icon(Icons.check_rounded, color: p.greenD, size: 20)
                      : Text(kShort(b.rev), style: AppType.body(size: 13, weight: FontWeight.w800, color: p.terracotta)),
                ),
            ]),
          ),
        );
      }));
}

/// System settings sheet.
void openSettings(BuildContext context) {
  context.shell.showSheet((_) => _SettingsHolder());
}

class _SettingsHolder extends StatefulWidget {
  @override
  State<_SettingsHolder> createState() => _SettingsHolderState();
}

class _SettingsHolderState extends State<_SettingsHolder> {
  final Map<String, bool> sw = {'vat': true, 'print': true, 'sound': true};
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget toggleRow(String key, String title, String sub) => Container(
          color: p.paper,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
                const SizedBox(height: 2),
                Text(sub, style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
              ]),
            ),
            SwitchDot(on: sw[key]!, onTap: () => setState(() => sw[key] = !sw[key]!)),
          ]),
        );
    final state = context.watch<AppState>();
    Widget darkRow() => Container(
          color: p.paper,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Chế độ tối', style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
                const SizedBox(height: 2),
                Text('Giao diện nền tối cho toàn app', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
              ]),
            ),
            SwitchDot(on: state.userDark, onTap: state.toggleDarkMode),
          ]),
        );
    return AppSheet(
      title: 'Cài đặt hệ thống',
      body: CardBox(
        clip: true,
        padding: EdgeInsets.zero,
        child: RowList([
          darkRow(),
          toggleRow('vat', 'Thuế VAT', 'Áp dụng 8% trên hóa đơn'),
          toggleRow('print', 'In bill tự động', 'Sau khi thanh toán'),
          toggleRow('sound', 'Âm thanh đơn mới (KDS)', 'Chuông khi có đơn'),
          ListRow(leading: LeadIcon(icon: 'print'), title: 'Thiết bị', subtitle: 'Máy in, két tiền, màn KDS',
              onTap: () => context.shell.toast('Kết nối máy in & két tiền', 'print')),
        ]),
      ),
      footer: AppButton('Lưu', large: true, block: true, onTap: () {
        context.shell.closeSheet();
        context.shell.toast('Đã lưu cài đặt', 'check');
      }),
    );
  }
}

/// Admin account sheet.
void openAdminProfile(BuildContext context) {
  final p0 = context.palette;
  context.shell.showSheet((_) => Consumer<AppState>(builder: (context, state, _) {
        final p = context.palette;
        return AppSheet(
          title: 'Tài khoản',
          body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
              child: Row(children: [
                Avatar('AN', size: 56),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('Nguyễn Văn An', style: AppType.body(size: 17, weight: FontWeight.w800, color: p.ink)),
                  const SizedBox(height: 5),
                  const AppBadge('⚙️ Quản trị', color: BadgeColor.red),
                ]),
              ]),
            ),
            CardBox(
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                ListRow(leading: LeadIcon(icon: 'store'), title: state.adminBranch, subtitle: 'Chi nhánh đang quản lý'),
                ListRow(
                    leading: LeadIcon(icon: 'settings'),
                    title: 'Cài đặt',
                    subtitle: 'Thuế, in bill, thiết bị',
                    onTap: () {
                      context.shell.closeSheet();
                      openSettings(context);
                    }),
              ]),
            ),
          ]),
          footer: AppButton('Đăng xuất / đổi vai trò',
              icon: 'logout', large: true, block: true, variant: BtnVariant.soft, textColor: p0.red, onTap: () {
            context.shell.closeSheet();
            context.read<SessionState>().logout();
          }),
        );
      }));
}

/// Edit-product sheet.
void openEditProduct(BuildContext context, Product product) {
  context.shell.showSheet((_) => _EditProductSheet(product: product));
}

class _EditProductSheet extends StatefulWidget {
  final Product product;
  const _EditProductSheet({required this.product});
  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.product.name);
  late final TextEditingController _price = TextEditingController(text: '${widget.product.price}');
  late String _cat = widget.product.cat;
  late bool _avail = !widget.product.sold;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = context.read<AppState>();
    return AppSheet(
      title: 'Sửa món',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Padding(padding: const EdgeInsets.fromLTRB(0, 4, 0, 10), child: Text(widget.product.emoji, style: const TextStyle(fontSize: 46)))),
        _fieldLabel(context, 'Tên món'),
        TextField(controller: _name, decoration: _dec(context, ''), style: AppType.body(color: p.ink)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Giá bán (đ)'),
        TextField(controller: _price, keyboardType: TextInputType.number, decoration: _dec(context, ''), style: AppType.body(color: p.ink)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Nhóm'),
        _catDropdown(context, _cat, (v) => setState(() => _cat = v)),
        const SizedBox(height: 14),
        CardBox(
          radius: 13,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Đang bán', style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
                const SizedBox(height: 2),
                Text('Hiển thị trên màn hình thu ngân', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
              ]),
            ),
            SwitchDot(on: _avail, onTap: () => setState(() => _avail = !_avail)),
          ]),
        ),
      ]),
      footer: Row(children: [
        AppButton('🗑', variant: BtnVariant.soft, large: true, textColor: p.red, onTap: () {
          state.deleteProduct(widget.product.id);
          context.shell.closeSheet();
          context.shell.toast('Đã xóa ${widget.product.name}', 'check');
        }),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton('Lưu thay đổi', large: true, onTap: () {
            state.saveProduct(widget.product.id, _name.text.trim(), int.tryParse(_price.text) ?? 0, _cat, !_avail);
            context.shell.closeSheet();
            context.shell.toast('Đã lưu ${_name.text.trim()}', 'check');
          }),
        ),
      ]),
    );
  }
}

/// Add-product sheet.
void openAddProduct(BuildContext context) {
  context.shell.showSheet((_) => const _AddProductSheet());
}

class _AddProductSheet extends StatefulWidget {
  const _AddProductSheet();
  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _emoji = TextEditingController();
  String _cat = 'cf';

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _emoji.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = context.read<AppState>();
    return AppSheet(
      title: 'Thêm món mới',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel(context, 'Tên món'),
        TextField(controller: _name, decoration: _dec(context, 'VD: Cà phê dừa'), style: AppType.body(color: p.ink)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Giá bán (đ)'),
        TextField(controller: _price, keyboardType: TextInputType.number, decoration: _dec(context, '35000'), style: AppType.body(color: p.ink)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Nhóm'),
        _catDropdown(context, _cat, (v) => setState(() => _cat = v)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Biểu tượng (emoji)'),
        TextField(controller: _emoji, maxLength: 2, decoration: _dec(context, '☕'), style: AppType.body(color: p.ink)),
      ]),
      footer: AppButton('Thêm vào thực đơn', icon: 'plus', large: true, block: true, onTap: () {
        final name = _name.text.trim();
        if (name.isEmpty) {
          context.shell.toast('Nhập tên món', 'edit');
          return;
        }
        state.addProduct(name, _cat, int.tryParse(_price.text) ?? 0, _emoji.text.trim());
        context.shell.closeSheet();
        context.shell.toast('Đã thêm $name', 'check');
      }),
    );
  }
}

/// Generic single-field dropdown (v0.1.2 add-forms).
Widget _dropdown(BuildContext context, String value, List<MapEntry<String, String>> items, ValueChanged<String> onChanged) {
  final p = context.palette;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(13), border: Border.all(color: p.line2, width: 1.5)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: p.paper,
        style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink),
        items: [for (final e in items) DropdownMenuItem(value: e.key, child: Text(e.value))],
        onChanged: (v) => v != null ? onChanged(v) : null,
      ),
    ),
  );
}

/// Add-staff form (v0.1.2).
void openAddStaff(BuildContext context) => context.shell.showSheet((_) => const _AddStaffSheet());

class _AddStaffSheet extends StatefulWidget {
  const _AddStaffSheet();
  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _role = 'cashier';
  String _branch = 'Cầu Giấy';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = context.read<AppState>();
    return AppSheet(
      title: 'Thêm nhân viên',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel(context, 'Họ tên'),
        TextField(controller: _name, decoration: _dec(context, 'VD: Nguyễn Văn A'), style: AppType.body(color: p.ink)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Số điện thoại'),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: _dec(context, '09xx xxx xxx'), style: AppType.body(color: p.ink)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Vai trò'),
        _dropdown(context, _role, const [
          MapEntry('admin', '⚙️ Quản trị'),
          MapEntry('cashier', '🧾 Thu ngân'),
          MapEntry('barista', '🍳 Pha chế'),
        ], (v) => setState(() => _role = v)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Chi nhánh'),
        _dropdown(context, _branch, [for (final b in state.branches) MapEntry(b.name, b.name)], (v) => setState(() => _branch = v)),
      ]),
      footer: AppButton('Lưu nhân viên', icon: 'check', large: true, block: true, onTap: () {
        final name = _name.text.trim();
        if (name.isEmpty) {
          context.shell.toast('Nhập họ tên', 'edit');
          return;
        }
        state.addStaff(name, _role, _phone.text.trim(), _branch);
        context.shell.closeSheet();
        context.shell.toast('Đã thêm $name', 'check');
      }),
    );
  }
}

/// Add-promo form (v0.1.2).
void openAddPromo(BuildContext context) => context.shell.showSheet((_) => const _AddPromoSheet());

class _AddPromoSheet extends StatefulWidget {
  const _AddPromoSheet();
  @override
  State<_AddPromoSheet> createState() => _AddPromoSheetState();
}

class _AddPromoSheetState extends State<_AddPromoSheet> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _type = TextEditingController();
  final _emoji = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _type.dispose();
    _emoji.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = context.read<AppState>();
    return AppSheet(
      title: 'Tạo khuyến mãi',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel(context, 'Tên chương trình'),
        TextField(controller: _name, decoration: _dec(context, 'VD: Giờ vàng 14h–16h'), style: AppType.body(color: p.ink)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Mô tả'),
        TextField(controller: _desc, decoration: _dec(context, 'VD: Giảm 20% toàn menu'), style: AppType.body(color: p.ink)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Nhãn (badge)'),
        TextField(controller: _type, decoration: _dec(context, 'VD: -20%'), style: AppType.body(color: p.ink)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Biểu tượng (emoji)'),
        TextField(controller: _emoji, maxLength: 2, decoration: _dec(context, '🎁'), style: AppType.body(color: p.ink)),
      ]),
      footer: AppButton('Lưu khuyến mãi', icon: 'check', large: true, block: true, onTap: () {
        final name = _name.text.trim();
        if (name.isEmpty) {
          context.shell.toast('Nhập tên chương trình', 'edit');
          return;
        }
        state.addPromo(name, _desc.text.trim(), _type.text.trim(), _emoji.text.trim());
        context.shell.closeSheet();
        context.shell.toast('Đã tạo $name', 'check');
      }),
    );
  }
}

/// Add-branch form (v0.1.2).
void openAddBranch(BuildContext context) => context.shell.showSheet((_) => const _AddBranchSheet());

class _AddBranchSheet extends StatefulWidget {
  const _AddBranchSheet();
  @override
  State<_AddBranchSheet> createState() => _AddBranchSheetState();
}

class _AddBranchSheetState extends State<_AddBranchSheet> {
  final _name = TextEditingController();
  final _addr = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _addr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = context.read<AppState>();
    return AppSheet(
      title: 'Thêm chi nhánh',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel(context, 'Tên chi nhánh'),
        TextField(controller: _name, decoration: _dec(context, 'VD: Hoàn Kiếm'), style: AppType.body(color: p.ink)),
        const SizedBox(height: 12),
        _fieldLabel(context, 'Địa chỉ'),
        TextField(controller: _addr, decoration: _dec(context, 'VD: 12 Hàng Bài, Hoàn Kiếm'), style: AppType.body(color: p.ink)),
      ]),
      footer: AppButton('Lưu chi nhánh', icon: 'check', large: true, block: true, onTap: () {
        final name = _name.text.trim();
        if (name.isEmpty) {
          context.shell.toast('Nhập tên chi nhánh', 'edit');
          return;
        }
        state.addBranch(name, _addr.text.trim());
        context.shell.closeSheet();
        context.shell.toast('Đã thêm $name', 'check');
      }),
    );
  }
}

Widget _catDropdown(BuildContext context, String value, ValueChanged<String> onChanged) {
  final p = context.palette;
  final cats = Seed.cats.where((c) => c.id != 'all').toList();
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(13), border: Border.all(color: p.line2, width: 1.5)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: p.paper,
        style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink),
        items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.name}'))],
        onChanged: (v) => v != null ? onChanged(v) : null,
      ),
    ),
  );
}
