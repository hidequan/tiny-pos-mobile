import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';

void openKdsProfile(BuildContext context) {
  final p0 = context.palette;
  context.shell.showSheet((_) => AppSheet(
        title: 'Tài khoản',
        body: Builder(builder: (context) {
          final p = context.palette;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
              child: Row(children: [
                Avatar('QD', size: 56, colors: const [Color(0xFF3F8F5B), Color(0xFF6FB07A)]),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('Phạm Quốc Dũng', style: AppType.body(size: 17, weight: FontWeight.w800, color: p.ink)),
                  const SizedBox(height: 5),
                  const AppBadge('🍳 Pha chế', color: BadgeColor.green),
                ]),
              ]),
            ),
            CardBox(
              clip: true,
              padding: EdgeInsets.zero,
              child: ListRow(leading: LeadIcon(icon: 'store'), title: 'Chi nhánh Cầu Giấy', subtitle: 'Quầy Bar 1'),
            ),
          ]);
        }),
        footer: AppButton('Đăng xuất / đổi vai trò',
            icon: 'logout', large: true, block: true, variant: BtnVariant.soft, textColor: p0.red, onTap: () {
          context.shell.closeSheet();
          context.read<AppState>().logout();
        }),
      ));
}
