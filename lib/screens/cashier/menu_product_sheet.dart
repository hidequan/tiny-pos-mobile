import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/menu_controller.dart';
import '../../models/menu.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../data/seed.dart' show vnd;
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'option_pill.dart';

// Đường / Đá levels accepted by the API (% — 0/30/50/70/100).
const _levelOpts = [100, 70, 50, 30, 0];

/// Tap a real menu product → open the options sheet (size / đường / đá / topping
/// / note / qty). Always opens so the cashier can set sugar/ice for any drink.
void onTapMenuProduct(BuildContext context, MenuProduct product) {
  context.shell.showSheet((_) => _MenuProductSheet(productId: product.id));
}

class _MenuProductSheet extends StatefulWidget {
  final String productId;
  const _MenuProductSheet({required this.productId});
  @override
  State<_MenuProductSheet> createState() => _MenuProductSheetState();
}

class _MenuProductSheetState extends State<_MenuProductSheet> {
  final _note = TextEditingController();
  final _qtyCtl = TextEditingController(text: '1');
  String? _variantId;
  final Set<String> _toppingIds = {};
  int _qty = 1;
  int _sugar = 100;
  int _ice = 100;

  @override
  void dispose() {
    _note.dispose();
    _qtyCtl.dispose();
    super.dispose();
  }

  void _setQty(int v) {
    final next = v.clamp(1, AppState.maxItemQty);
    setState(() => _qty = next);
    if (_qtyCtl.text != '$next') {
      _qtyCtl.text = '$next';
      _qtyCtl.selection = TextSelection.collapsed(offset: _qtyCtl.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final menu = context.read<PosMenuController>().menu;
    final product = menu?.products.firstWhere((x) => x.id == widget.productId);
    if (product == null || menu == null) return const SizedBox.shrink();

    _variantId ??= product.defaultVariant?.id;
    ProductVariant? variant;
    for (final v in product.variants) {
      if (v.id == _variantId) {
        variant = v;
        break;
      }
    }
    variant ??= product.defaultVariant;
    final allowedToppings = product.toppingIds.isEmpty
        ? <MenuTopping>[]
        : menu.toppings.where((t) => product.toppingIds.contains(t.id)).toList();
    final toppingsSelected = allowedToppings.where((t) => _toppingIds.contains(t.id)).toList();
    final extra = toppingsSelected.fold<int>(0, (a, t) => a + t.price);
    final unit = (variant?.price ?? product.basePrice) + extra;

    Widget group(String label, Widget child) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(label, style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink)),
            ),
            child,
          ]),
        );

    Widget levelPills(int selected, ValueChanged<int> onPick) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final lv in _levelOpts)
              OptionPill(label: '$lv%', on: selected == lv, onTap: () => onPick(lv)),
          ],
        );

    return AppSheet(
      title: product.name,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (product.variants.length > 1)
          group(
            'Kích cỡ',
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final v in product.variants)
                OptionPill(
                  label: v.sizeName ?? v.sizeCode ?? 'Mặc định',
                  on: _variantId == v.id,
                  onTap: () => setState(() => _variantId = v.id),
                ),
            ]),
          ),
        group('Đường', levelPills(_sugar, (lv) => setState(() => _sugar = lv))),
        group('Đá', levelPills(_ice, (lv) => setState(() => _ice = lv))),
        if (allowedToppings.isNotEmpty)
          group(
            'Topping',
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in allowedToppings)
                OptionPill(
                  label: t.name,
                  price: t.price,
                  on: _toppingIds.contains(t.id),
                  onTap: () => setState(() =>
                      _toppingIds.contains(t.id) ? _toppingIds.remove(t.id) : _toppingIds.add(t.id)),
                ),
            ]),
          ),
        group(
          'Ghi chú',
          TextField(
            controller: _note,
            maxLines: 2,
            style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink),
            decoration: _dec(p, 'VD: ít ngọt, mang theo ống hút...'),
          ),
        ),
      ]),
      footer: Row(children: [
        _qtyControl(p),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton('Thêm · ${vnd(unit * _qty)}', variant: BtnVariant.pri, onTap: () {
            context.read<AppState>().addMenuFromApi(
                  product,
                  variant: variant,
                  toppings: toppingsSelected,
                  note: _note.text,
                  qty: _qty,
                  sugar: _sugar,
                  sugarLabel: '$_sugar%',
                  ice: _ice,
                  iceLabel: '$_ice%',
                );
            context.shell.closeSheet();
            context.shell.toast('${product.name} đã thêm vào đơn', 'check');
          }),
        ),
      ]),
    );
  }

  // Số lượng: gõ trực tiếp được + nút − / + (giới hạn 1..99).
  Widget _qtyControl(Palette p) {
    Widget btn(IconData ic, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 44,
            alignment: Alignment.center,
            child: Icon(ic, size: 20, color: p.ink),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: p.cream2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: p.line2, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.remove_rounded, () => _setQty(_qty - 1)),
        SizedBox(
          width: 44,
          child: TextField(
            controller: _qtyCtl,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            style: AppType.body(size: 16, weight: FontWeight.w800, color: p.ink),
            decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true, contentPadding: EdgeInsets.symmetric(vertical: 12)),
            onChanged: (v) {
              final n = int.tryParse(v) ?? 1;
              setState(() => _qty = n.clamp(1, AppState.maxItemQty));
            },
            onEditingComplete: () => _setQty(_qty),
          ),
        ),
        btn(Icons.add_rounded, () => _setQty(_qty + 1)),
      ]),
    );
  }

  InputDecoration _dec(Palette p, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppType.body(size: 14.5, weight: FontWeight.w500, color: p.faint),
        filled: true,
        fillColor: p.paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
      );
}
