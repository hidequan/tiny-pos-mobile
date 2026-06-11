import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/admin_data_controller.dart';
import '../../state/menu_controller.dart';
import '../../models/menu.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';

/// Create (edit == null) or edit a product. Writes via AdminDataController and
/// reloads the shared menu on success.
void openProductForm(BuildContext context, {MenuProduct? edit}) {
  context.shell.showSheet((_) => _ProductForm(edit: edit));
}

class _ProductForm extends StatefulWidget {
  final MenuProduct? edit;
  const _ProductForm({this.edit});
  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  String? _categoryId;
  late bool _active;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _name = TextEditingController(text: e?.name ?? '');
    _price = TextEditingController(text: e != null ? '${e.displayPrice}' : '');
    _categoryId = e?.categoryId;
    _active = e?.available ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isEdit = widget.edit != null;
    final cats = context.read<PosMenuController>().menu?.categories ?? const <MenuCategory>[];

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

    return AppSheet(
      title: isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        field('Tên món', TextField(
          controller: _name,
          style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink),
          decoration: deco('VD: Cà phê sữa đá'),
        )),
        field('Danh mục', Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in cats)
            PillChip(c.name, on: _categoryId == c.id, onTap: () => setState(() => _categoryId = c.id)),
        ])),
        field('Giá bán (đ)', TextField(
          controller: _price,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink),
          decoration: deco('VD: 29000'),
        )),
        const SizedBox(height: 8),
        CardBox(
          radius: 14,
          padding: const EdgeInsets.all(13),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Đang bán', style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
                const SizedBox(height: 2),
                Text(_active ? 'Hiển thị trên menu thu ngân' : 'Tạm ẩn khỏi menu',
                    style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
              ]),
            ),
            SwitchDot(on: _active, onTap: () => setState(() => _active = !_active)),
          ]),
        ),
      ]),
      footer: AppButton(
        _busy ? 'Đang lưu...' : (isEdit ? 'Lưu thay đổi' : 'Tạo sản phẩm'),
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
    final price = int.tryParse(_price.text.trim());
    if (name.isEmpty) {
      context.shell.toast('Nhập tên món', 'edit');
      return;
    }
    if (_categoryId == null) {
      context.shell.toast('Chọn danh mục', 'edit');
      return;
    }
    if (price == null || price <= 0) {
      context.shell.toast('Nhập giá hợp lệ', 'edit');
      return;
    }
    setState(() => _busy = true);
    final admin = context.read<AdminDataController>();
    final menu = context.read<PosMenuController>();
    final e = widget.edit;
    final err = e == null
        ? await admin.createProduct(categoryId: _categoryId!, name: name, basePrice: price, active: _active)
        : await admin.updateProduct(e.id,
            name: name, categoryId: _categoryId, basePrice: price, active: _active);
    if (!context.mounted) return;
    if (err == null) {
      await menu.load(force: true);
      if (!context.mounted) return;
      context.shell.closeSheet();
      context.shell.toast(e == null ? 'Đã tạo "$name"' : 'Đã lưu "$name"', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }
}
