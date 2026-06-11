import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/session.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../theme/app_icons.dart';
import '../../widgets/common.dart';
import 'admin_sheets.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    final activePromos = state.promos.where((x) => x.on).length;

    final items = [
      ['users', const Color(0xFFFCE8DF), p.terracotta, 'Nhân viên & phân quyền', '${state.staff.length} người · RBAC', 'staff'],
      ['gift', const Color(0xFFEFE6F7), const Color(0xFF7A4FB0), 'Khuyến mãi', '$activePromos đang chạy', 'promos'],
      ['store', p.greenBg, p.greenD, 'Chi nhánh', '${state.branches.length} cửa hàng', 'branches'],
      ['clock', p.amberBg, p.amber, 'Ca làm việc', 'Quản lý lịch & đối soát', 'shiftadmin'],
      ['settings', p.cream2, p.espresso, 'Cài đặt hệ thống', 'Thuế, in bill, thiết bị', 'settings'],
    ];

    return Column(children: [
      TopBar(
        title: 'Quản lý',
        subtitle: Text('Tiny POS · v0.2.0', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [Avatar('AN', onTap: () => openAdminProfile(context))],
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            CardBox(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                for (final it in items)
                  ListRow(
                    leading: LeadIcon(icon: it[0] as String, bg: it[1] as Color, fg: it[2] as Color),
                    title: it[3] as String,
                    subtitle: it[4] as String,
                    trailing: Icon(AppIcons.get('forward'), size: 18, color: p.faint),
                    onTap: () {
                      if (it[5] == 'settings') {
                        openSettings(context);
                      } else {
                        state.openAdminSub(it[5] as String);
                      }
                    },
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text('Tiny POS · Bản xem trước di động\n© 2025 · Đăng nhập: Nguyễn Văn An',
                  textAlign: TextAlign.center, style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.muted)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppButton('Đăng xuất / đổi vai trò',
                  icon: 'logout', block: true, variant: BtnVariant.soft, textColor: p.red,
                  onTap: () => context.read<SessionState>().logout()),
            ),
          ],
        ),
      ),
    ]);
  }
}
