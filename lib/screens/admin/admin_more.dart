import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_info.dart';
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
    final u = context.watch<SessionState>().user;
    final p = context.palette;

    final items = [
      ['receipt', const Color(0xFFFDE7E1), p.terracotta, 'Duyệt huỷ / hoàn', 'Yêu cầu từ thu ngân', 'voidrefund'],
      ['book', const Color(0xFFE9EFE2), p.greenD, 'Đơn hàng', 'Xem & lọc mọi hoá đơn', 'adminbills'],
      ['users', const Color(0xFFFCE8DF), p.terracotta, 'Nhân viên & phân quyền', '${state.staff.length} người · RBAC', 'staff'],
      ['gift', const Color(0xFFEFE6F7), const Color(0xFF7A4FB0), 'Voucher / Khuyến mãi', 'Mã giảm giá', 'promos'],
      ['book', p.cream2, p.caramel, 'Cấu hình Menu', 'Danh mục · Size · Topping', 'menuconfig'],
      ['table', p.blueBg, const Color(0xFF3E6E8E), 'Khu vực & Bàn', 'Sơ đồ bàn dine-in', 'tablesadmin'],
      ['store', p.greenBg, p.greenD, 'Chi nhánh', '${state.branches.length} cửa hàng', 'branches'],
      ['cash', p.greenBg, p.greenD, 'Sổ quỹ ca', 'Dòng tiền ra / vào · duyệt rút quỹ', 'cashflow'],
      ['clock', p.amberBg, p.amber, 'Ca làm việc', 'Quản lý lịch & đối soát', 'shiftadmin'],
      ['print', p.cream2, p.espresso, 'Thiết bị & Máy in', 'Máy in · két tiền · định tuyến', 'hardware'],
      ['receipt', p.cream2, p.ink2, 'Audit log', 'Nhật ký thao tác toàn hệ thống', 'audit'],
      ['layers', p.blueBg, const Color(0xFF3E6E8E), 'Giám sát đồng bộ', 'Thiết bị & conflict', 'syncmonitor'],
      ['settings', p.cream2, p.espresso, 'Cài đặt hệ thống', 'Thuế, in bill, thiết bị', 'settings'],
      ['coffee', p.cream2, p.terracotta, 'Giới thiệu & Hỗ trợ', 'Phiên bản · liên hệ · bảo mật', 'about'],
    ];

    return Column(children: [
      TopBar(
        title: 'Quản lý',
        subtitle: Text('${AppInfo.name} · v${AppInfo.version}', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [Avatar(u?.initials ?? 'QT', onTap: () => openAdminProfile(context))],
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
                      } else if (it[5] == 'about') {
                        openAbout(context);
                      } else {
                        state.openAdminSub(it[5] as String);
                      }
                    },
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text('${AppInfo.name} v${AppInfo.version} · ${AppInfo.developer}\n© 2026 · Hỗ trợ: ${AppInfo.supportEmail}',
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
