import 'package:flutter/material.dart';
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

bool _needsOptions(MenuProduct p) =>
    p.hasModifiers || p.variants.length > 1 || p.toppingIds.isNotEmpty;

/// Tap a real menu product: add directly, or open the size/topping sheet.
void onTapMenuProduct(BuildContext context, MenuProduct product) {
  final state = context.read<AppState>();
  if (!_needsOptions(product)) {
    state.addMenuFromApi(product, variant: product.defaultVariant);
    context.shell.toast('${product.name} đã thêm', 'check');
    return;
  }
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
  String? _variantId;
  final Set<String> _toppingIds = {};
  int _qty = 1;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
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
            decoration: InputDecoration(
              hintText: 'VD: ít ngọt, mang theo ống hút...',
              hintStyle: AppType.body(size: 14.5, weight: FontWeight.w500, color: p.faint),
              filled: true,
              fillColor: p.paper,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
            ),
          ),
        ),
      ]),
      footer: Row(children: [
        QtyStepper(value: _qty, onChange: (d) => setState(() => _qty = (_qty + d).clamp(1, 99))),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton('Thêm · ${vnd(unit * _qty)}', variant: BtnVariant.pri, onTap: () {
            context.read<AppState>().addMenuFromApi(
                  product,
                  variant: variant,
                  toppings: toppingsSelected,
                  note: _note.text,
                  qty: _qty,
                );
            context.shell.closeSheet();
            context.shell.toast('${product.name} đã thêm vào đơn', 'check');
          }),
        ),
      ]),
    );
  }
}
