import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/menu_controller.dart';
import '../../state/admin_data_controller.dart';
import '../../models/menu.dart';
import '../../data/seed.dart' show vnd;
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_sheets.dart';
import 'product_form.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});
  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  String? _cat; // null = all

  @override
  void initState() {
    super.initState();
    final m = context.read<PosMenuController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!m.isLoaded) m.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<PosMenuController>();
    final p = context.palette;
    final menu = m.menu;
    final products = menu?.products ?? const <MenuProduct>[];
    final avail = products.where((x) => x.available).length;

    return Column(children: [
      TopBar(
        title: 'Thực đơn',
        subtitle: Text(
          menu != null ? '${products.length} món · $avail đang bán' : 'Đang tải…',
          style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2),
        ),
        actions: [
          IconBtn('plus', bg: p.terracotta, fg: Colors.white, iconSize: 22, onTap: () => openProductForm(context)),
          Avatar('AN', onTap: () => openAdminProfile(context)),
        ],
      ),
      if (menu != null && menu.categories.isNotEmpty)
        ChipsRow(children: [
          PillChip('Tất cả', on: _cat == null, onTap: () => setState(() => _cat = null)),
          for (final c in menu.categories)
            PillChip(c.name, on: _cat == c.id, onTap: () => setState(() => _cat = c.id)),
        ]),
      Expanded(child: _body(context, m)),
    ]);
  }

  Widget _body(BuildContext context, PosMenuController m) {
    final p = context.palette;
    if (m.loading && !m.isLoaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (m.error != null && !m.isLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📋', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(m.error!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => m.load(force: true)),
        ]),
      );
    }
    final menu = m.menu;
    if (menu == null) return const SizedBox.shrink();
    final list = _cat == null ? menu.products : menu.products.where((x) => x.categoryId == _cat).toList();
    final catName = {for (final c in menu.categories) c.id: c.name};

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        CardBox(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          clip: true,
          padding: EdgeInsets.zero,
          child: RowList([
            for (final prod in list)
              ListRow(
                onTap: () => _detail(context, prod, catName[prod.categoryId] ?? 'Khác'),
                leading: _thumb(context, prod),
                title: prod.name,
                subtitle: '${catName[prod.categoryId] ?? 'Khác'} · ${vnd(prod.displayPrice)}'
                    '${prod.hasModifiers ? ' · có tùy chọn' : ''}',
                trailing: AppBadge(prod.available ? 'Đang bán' : 'Tạm hết',
                    color: prod.available ? BadgeColor.green : BadgeColor.gray),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _thumb(BuildContext context, MenuProduct prod) {
    final p = context.palette;
    final bytes = prod.imageBytes;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.memory(bytes, width: 38, height: 38, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(11)),
      child: Icon(Icons.local_cafe_outlined, size: 19, color: p.muted),
    );
  }

  void _detail(BuildContext context, MenuProduct prod, String catName) {
    context.shell.showSheet((_) => _ProductDetailSheet(prod: prod, catName: catName));
  }
}

/// Read + quick-availability-toggle + edit for one product.
class _ProductDetailSheet extends StatelessWidget {
  final MenuProduct prod;
  final String catName;
  const _ProductDetailSheet({required this.prod, required this.catName});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final admin = context.watch<AdminDataController>();
    final busy = admin.productBusy(prod.id);

    return AppSheet(
      title: prod.name,
      headerExtra: [
        AppBadge(prod.available ? 'Đang bán' : 'Tạm hết', color: prod.available ? BadgeColor.green : BadgeColor.gray),
      ],
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        CardBox(
          radius: 14,
          padding: const EdgeInsets.all(13),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Đang bán', style: AppType.body(size: 14.5, weight: FontWeight.w700, color: p.ink)),
                const SizedBox(height: 2),
                Text(prod.available ? 'Hiển thị trên menu thu ngân' : 'Đang tạm ẩn khỏi menu',
                    style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
              ]),
            ),
            if (busy)
              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.muted))
            else
              SwitchDot(on: prod.available, onTap: () => _toggle(context)),
          ]),
        ),
        const SizedBox(height: 14),
        CardBox(
          radius: 14,
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            KvRow('Danh mục', Text(catName, style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
            KvRow('Giá', Text(vnd(prod.displayPrice), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta))),
            KvRow('Tùy chọn', Text(prod.hasModifiers ? 'Có' : 'Không',
                style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)), last: prod.variants.isEmpty),
          ]),
        ),
        if (prod.variants.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Kích cỡ / giá', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
          const SizedBox(height: 8),
          CardBox(
            clip: true,
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < prod.variants.length; i++)
                KvRow(
                  prod.variants[i].sizeName ?? prod.variants[i].sizeCode ?? 'Mặc định',
                  Text(vnd(prod.variants[i].price), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)),
                  last: i == prod.variants.length - 1,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                ),
            ]),
          ),
        ],
      ]),
      footer: AppButton('Sửa sản phẩm', icon: 'edit', large: true, block: true, onTap: () {
        context.shell.closeSheet();
        openProductForm(context, edit: prod);
      }),
    );
  }

  Future<void> _toggle(BuildContext context) async {
    final admin = context.read<AdminDataController>();
    final menu = context.read<PosMenuController>();
    final err = await admin.toggleProductStatus(prod.id, !prod.available);
    if (!context.mounted) return;
    if (err == null) {
      await menu.load(force: true);
      if (!context.mounted) return;
      context.shell.closeSheet();
      context.shell.toast(prod.available ? '${prod.name}: tạm ẩn' : '${prod.name}: mở bán', 'check');
    } else {
      context.shell.toast(err, 'edit');
    }
  }
}
