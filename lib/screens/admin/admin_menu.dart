import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_sheets.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  String _catName(String id) {
    final c = Seed.cats.where((x) => x.id == id);
    return c.isEmpty ? 'Khác' : c.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    final list = state.products.where((x) => state.adminCat == 'all' || x.cat == state.adminCat).toList();
    final avail = state.products.where((x) => !x.sold).length;

    return Column(children: [
      TopBar(
        title: 'Thực đơn',
        subtitle: Text('${state.products.length} món · $avail đang bán',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [
          IconBtn('plus', bg: p.terracotta, fg: Colors.white, iconSize: 22, onTap: () => openAddProduct(context)),
          Avatar('AN', onTap: () => openAdminProfile(context)),
        ],
      ),
      ChipsRow(children: [
        for (final c in Seed.cats)
          PillChip(c.name, emoji: c.emoji, on: state.adminCat == c.id, onTap: () => state.setAdminCat(c.id)),
      ]),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            CardBox(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                for (final prod in list)
                  ListRow(
                    onTap: () => openEditProduct(context, prod),
                    leading: LeadIcon(emoji: prod.emoji),
                    title: prod.name,
                    subtitle: '${_catName(prod.cat)} · ${vnd(prod.price)}${prod.opt ? ' · có tùy chọn' : ''}',
                    trailing: SwitchDot(on: !prod.sold, onTap: () {
                      state.toggleAvail(prod.id);
                      context.shell.toast(prod.sold ? '${prod.name}: tạm hết' : '${prod.name}: mở bán', 'check');
                    }),
                  ),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }
}
