import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session.dart';
import '../../state/admin_data_controller.dart';
import '../../models/admin.dart';
import '../../data/seed.dart' show vnd;
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_widgets.dart';

/// Cấu hình Menu — CRUD categories / sizes / toppings. Ported from the web
/// admin/menu page (3 tabs).
class MenuConfigScreen extends StatefulWidget {
  const MenuConfigScreen({super.key});
  @override
  State<MenuConfigScreen> createState() => _MenuConfigScreenState();
}

class _MenuConfigScreenState extends State<MenuConfigScreen> {
  int _tab = 0; // 0 categories, 1 sizes, 2 toppings
  String? get _branchId => context.read<SessionState>().user?.branchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = _branchId;
      if (mounted && b != null) context.read<AdminDataController>().ensureCatalog(b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminDataController>();
    final p = context.palette;
    final branchId = _branchId;
    return Column(children: [
      BackBar(
        title: 'Cấu hình Menu',
        sub: a.catalogLoaded ? '${a.categories.length} danh mục · ${a.sizes.length} size · ${a.toppings.length} topping' : 'Đang tải…',
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Segmented(
          labels: const ['Danh mục', 'Size', 'Topping'],
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
    if (a.catalogLoading && !a.catalogLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (a.catalogError != null && !a.catalogLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(a.catalogError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => a.loadCatalog(branchId)),
        ]),
      );
    }
    final kind = ['cat', 'size', 'topping'][_tab];
    final addLabel = ['+ Thêm danh mục', '+ Thêm size', '+ Thêm topping'][_tab];
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionHeader(['Danh mục', 'Kích cỡ', 'Topping'][_tab], action: addLabel,
            onAction: () => _openForm(context, branchId, kind)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            if (_tab == 0)
              for (final c in a.categories)
                _row(context, branchId, p, kind, id: c.id, title: c.name, trailing: '${c.productCount} SP')
            else if (_tab == 1)
              for (final s in a.sizes)
                _row(context, branchId, p, kind, id: s.id, title: s.name, lead: s.code)
            else
              for (final t in a.toppings)
                _row(context, branchId, p, kind, id: t.id, title: t.name, trailing: vnd(t.price)),
            if ((_tab == 0 && a.categories.isEmpty) || (_tab == 1 && a.sizes.isEmpty) || (_tab == 2 && a.toppings.isEmpty))
              const Padding(padding: EdgeInsets.only(top: 8), child: EmptyState(emoji: '🍵', title: 'Chưa có mục nào', sub: 'Bấm "+ Thêm" để tạo')),
          ]),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String branchId, Palette p, String kind,
      {required String id, required String title, String? trailing, String? lead}) {
    return GestureDetector(
      onTap: () => _openForm(context, branchId, kind, id: id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
        child: Row(children: [
          if (lead != null) ...[
            AppBadge(lead, color: BadgeColor.gray),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink))),
          if (trailing != null) ...[
            Text(trailing, style: AppType.body(size: 13, weight: FontWeight.w700, color: p.muted)),
            const SizedBox(width: 8),
          ],
          Icon(Icons.edit_outlined, size: 16, color: p.faint),
        ]),
      ),
    );
  }

  void _openForm(BuildContext context, String branchId, String kind, {String? id}) {
    final a = context.read<AdminDataController>();
    AdminCategory? cat;
    AdminSize? size;
    AdminTopping? top;
    if (id != null) {
      if (kind == 'cat') cat = a.categories.where((x) => x.id == id).cast<AdminCategory?>().firstWhere((_) => true, orElse: () => null);
      if (kind == 'size') size = a.sizes.where((x) => x.id == id).cast<AdminSize?>().firstWhere((_) => true, orElse: () => null);
      if (kind == 'topping') top = a.toppings.where((x) => x.id == id).cast<AdminTopping?>().firstWhere((_) => true, orElse: () => null);
    }
    context.shell.showSheet((_) => _CatalogFormSheet(
          branchId: branchId, kind: kind, id: id,
          initName: cat?.name ?? size?.name ?? top?.name ?? '',
          initCode: size?.code ?? '',
          initPrice: top?.price ?? 0,
        ));
  }
}

class _CatalogFormSheet extends StatefulWidget {
  final String branchId;
  final String kind; // cat | size | topping
  final String? id;
  final String initName;
  final String initCode;
  final int initPrice;
  const _CatalogFormSheet({
    required this.branchId,
    required this.kind,
    this.id,
    required this.initName,
    required this.initCode,
    required this.initPrice,
  });
  @override
  State<_CatalogFormSheet> createState() => _CatalogFormSheetState();
}

class _CatalogFormSheetState extends State<_CatalogFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _price;
  bool _busy = false;
  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initName);
    _code = TextEditingController(text: widget.initCode);
    _price = TextEditingController(text: widget.initPrice > 0 ? '${widget.initPrice}' : '');
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _price.dispose();
    super.dispose();
  }

  String get _titleNoun => widget.kind == 'cat' ? 'danh mục' : widget.kind == 'size' ? 'size' : 'topping';

  Future<void> _submit() async {
    final a = context.read<AdminDataController>();
    final name = _name.text.trim();
    final code = _code.text.trim().toUpperCase();
    final price = int.tryParse(_price.text.trim().replaceAll('.', '')) ?? 0;
    if (name.isEmpty || (widget.kind == 'size' && code.isEmpty)) {
      context.shell.toast(widget.kind == 'size' ? 'Nhập mã và tên size' : 'Nhập tên $_titleNoun', 'edit');
      return;
    }
    setState(() => _busy = true);
    String? err;
    switch (widget.kind) {
      case 'cat':
        err = await a.saveCategory(widget.branchId, id: widget.id, name: name);
      case 'size':
        err = await a.saveSize(widget.branchId, id: widget.id, code: code, name: name);
      default:
        err = await a.saveTopping(widget.branchId, id: widget.id, name: name, price: price);
    }
    if (!mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast(_isEdit ? 'Đã lưu $_titleNoun' : 'Đã thêm $_titleNoun', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }

  Future<void> _delete() async {
    final a = context.read<AdminDataController>();
    setState(() => _busy = true);
    String? err;
    switch (widget.kind) {
      case 'cat':
        err = await a.removeCategory(widget.branchId, widget.id!);
      case 'size':
        err = await a.removeSize(widget.branchId, widget.id!);
      default:
        err = await a.removeTopping(widget.branchId, widget.id!);
    }
    if (!mounted) return;
    if (err == null) {
      context.shell.closeSheet();
      context.shell.toast('Đã xoá $_titleNoun', 'check');
    } else {
      setState(() => _busy = false);
      context.shell.toast(err, 'edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppSheet(
      title: '${_isEdit ? 'Sửa' : 'Thêm'} ${_titleNoun[0].toUpperCase()}${_titleNoun.substring(1)}',
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.kind == 'size') ...[
          _label(p, 'Mã size'),
          _field(p, _code, hint: 'VD: S / M / L', caps: true),
          const SizedBox(height: 12),
        ],
        _label(p, widget.kind == 'size' ? 'Tên size' : 'Tên $_titleNoun'),
        _field(p, _name, hint: widget.kind == 'cat' ? 'VD: Cà phê' : widget.kind == 'size' ? 'VD: Nhỏ' : 'VD: Trân châu'),
        if (widget.kind == 'topping') ...[
          const SizedBox(height: 12),
          _label(p, 'Giá (đ)'),
          _field(p, _price, hint: 'VD: 5000', number: true),
        ],
      ]),
      footer: _isEdit
          ? Row(children: [
              AppButton('Xoá', large: true, variant: BtnVariant.soft, textColor: p.red, onTap: _busy ? null : _delete),
              const SizedBox(width: 10),
              Expanded(child: AppButton(_busy ? 'Đang lưu…' : 'Lưu', icon: 'check', large: true, block: true, enabled: !_busy, onTap: _submit)),
            ])
          : AppButton(_busy ? 'Đang thêm…' : 'Thêm', icon: 'check', large: true, block: true, enabled: !_busy, onTap: _submit),
    );
  }

  Widget _label(Palette p, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(t, style: AppType.body(size: 12.5, weight: FontWeight.w800, color: p.ink2)),
      );

  Widget _field(Palette p, TextEditingController c, {String? hint, bool number = false, bool caps = false}) => TextField(
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
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
        ),
      );
}
