import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/session.dart';
import '../../state/menu_controller.dart';
import '../../models/menu.dart';
import '../../data/seed.dart' show vnd;
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'cashier_sheets.dart';
import 'menu_product_sheet.dart';

/// POS sell screen — now backed by the REAL shared menu (GET /pos/menu).
class SellScreen extends StatelessWidget {
  const SellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final menuCtl = context.watch<PosMenuController>();
    final p = context.palette;

    // Kick off the load once (first time the cashier opens the screen).
    if (!menuCtl.isLoaded && !menuCtl.loading && menuCtl.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => menuCtl.load());
    }

    final sub = state.otype == 'dinein'
        ? 'Tại bàn${state.table != null ? ' · ${state.table}' : ''}'
        : 'Mang đi';

    return Column(
      children: [
        TopBar(
          title: 'Bán hàng',
          subtitle: Text(sub, style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
          actions: [
            IconBtn('scan', onTap: () => context.shell.toast('Quét mã vạch sản phẩm', 'scan')),
            Avatar(_initials(context), onTap: () => openProfile(context)),
          ],
        ),
        Expanded(child: _body(context, state, menuCtl)),
      ],
    );
  }

  String _initials(BuildContext context) =>
      context.read<SessionState>().user?.initials ?? 'TB';

  Widget _body(BuildContext context, AppState state, PosMenuController menuCtl) {
    final p = context.palette;
    if (menuCtl.loading && !menuCtl.isLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (menuCtl.error != null && !menuCtl.isLoaded) {
      return _ErrorRetry(message: menuCtl.error!, onRetry: () => menuCtl.load(force: true));
    }
    final menu = menuCtl.menu;
    if (menu == null) return const SizedBox.shrink();

    var products = menu.byCategory(state.cat == 'all' ? null : state.cat);
    final q = state.sellSearch.trim().toLowerCase();
    if (q.isNotEmpty) {
      products = products.where((x) => x.name.toLowerCase().contains(q)).toList();
    }

    return Column(
      children: [
        SearchField(hint: 'Tìm món...', value: state.sellSearch, onChanged: state.setSellSearch),
        ChipsRow(children: [
          PillChip('Tất cả', emoji: '✨', on: state.cat == 'all', onTap: () => state.setCat('all')),
          for (final c in menu.categories)
            PillChip(c.name, on: state.cat == c.id, onTap: () => state.setCat(c.id)),
        ]),
        Expanded(
          child: Stack(
            children: [
              if (products.isEmpty)
                EmptyState(emoji: '🔍', title: 'Không có món', sub: 'Thử nhóm hoặc từ khóa khác')
              else
                GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 150,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => _ProductCard(product: products[i]),
                ),
              if (state.cartCount > 0) Positioned(left: 12, right: 12, bottom: 12, child: _CartBar(state: state)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final MenuProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final qty = context.select<AppState, int>((s) => s.qtyForProduct(product.id));
    final soldOut = !product.available;
    final bytes = product.imageBytes;

    return Pressable(
      scale: 0.97,
      onTap: soldOut ? null : () => onTapMenuProduct(context, product),
      child: Opacity(
        opacity: soldOut ? 0.5 : 1,
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: bytes != null
                        ? Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover, gaplessPlayback: true)
                        : Container(
                            width: 72,
                            height: 72,
                            color: p.cream2,
                            child: Icon(Icons.local_cafe_outlined, size: 30, color: p.muted),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body(size: 13.5, weight: FontWeight.w700, color: p.ink, height: 1.2)),
                  ),
                  const SizedBox(height: 6),
                  soldOut
                      ? Text('Hết hàng', style: AppType.body(size: 12, weight: FontWeight.w600, color: p.muted))
                      : Text(vnd(product.displayPrice),
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
              else if (product.hasModifiers)
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

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text('Không tải được thực đơn', style: AppType.display(size: 16, color: p.ink)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 18),
          AppButton('Thử lại', icon: 'history', onTap: onRetry),
        ]),
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
