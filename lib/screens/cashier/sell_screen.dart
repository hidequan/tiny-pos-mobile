import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../data/models.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'cashier_sheets.dart';

class SellScreen extends StatelessWidget {
  const SellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    var list = state.productsForCat(state.cat);
    final q = state.sellSearch.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((pr) => pr.name.toLowerCase().contains(q)).toList();
    }
    final sub = state.otype == 'dinein'
        ? 'Tại bàn${state.table != null ? ' · ${state.table}' : ''} · Ca chiều'
        : 'Mang đi · Ca chiều';

    return Column(
      children: [
        TopBar(
          title: 'Bán hàng',
          subtitle: Text(sub, style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
          actions: [
            IconBtn('scan', onTap: () => context.shell.toast('Quét mã vạch sản phẩm', 'scan')),
            Avatar('TB', onTap: () => openProfile(context)),
          ],
        ),
        SearchField(
          hint: 'Tìm món...',
          value: state.sellSearch,
          onChanged: state.setSellSearch,
        ),
        ChipsRow(children: [
          for (final c in Seed.cats)
            PillChip(c.name, emoji: c.emoji, on: state.cat == c.id, onTap: () => state.setCat(c.id)),
        ]),
        Expanded(
          child: Stack(
            children: [
              if (list.isEmpty)
                EmptyState(emoji: '🔍', title: 'Không tìm thấy món', sub: 'Thử từ khóa hoặc nhóm khác')
              else
                GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 128,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _ProductCard(product: list[i]),
                ),
              if (state.cartCount > 0)
                Positioned(left: 12, right: 12, bottom: 12, child: _CartBar(state: state)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final qty = context.watch<AppState>().qtyForProduct(product.id);

    return Pressable(
      scale: 0.97,
      onTap: product.sold ? null : () => tapProduct(context, product),
      child: Opacity(
        opacity: product.sold ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.line),
            boxShadow: const [BoxShadow(color: Color(0x0F3C1E0A), blurRadius: 3, offset: Offset(0, 1))],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.center,
                    child: Text(product.emoji, style: const TextStyle(fontSize: 29)),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(product.name,
                        style: AppType.body(size: 13.5, weight: FontWeight.w700, color: p.ink, height: 1.2)),
                  ),
                  const SizedBox(height: 7),
                  product.sold
                      ? Text('Hết hàng', style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted))
                      : Text(vnd(product.price),
                          style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
                ],
              ),
              if (qty > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: p.terracotta,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: p.terracotta.withValues(alpha: 0.6), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    alignment: Alignment.center,
                    child: Text('$qty', style: AppType.body(size: 13, weight: FontWeight.w800, color: Colors.white)),
                  ),
                )
              else if (product.opt)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(8)),
                    child: Text('tùy chọn', style: AppType.body(size: 10, weight: FontWeight.w800, color: p.ink2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final AppState state;
  const _CartBar({required this.state});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      scale: 0.98,
      onTap: () => openCart(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.espresso,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x47281206), blurRadius: 50, offset: Offset(0, 18))],
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: Text('${state.cartCount}', style: AppType.body(size: 15, weight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(vnd(state.cartSubtotal), style: AppType.body(size: 15, weight: FontWeight.w800, color: Colors.white)),
              Text('${state.cartCount} món trong đơn',
                  style: AppType.body(size: 12, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.7))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: p.terracotta, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Xem đơn', style: AppType.body(size: 14, weight: FontWeight.w800, color: Colors.white)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white),
            ]),
          ),
        ]),
      ),
    );
  }
}
