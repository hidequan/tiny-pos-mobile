import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'admin_widgets.dart';

/// Nhân viên & RBAC.
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  static const _roles = [
    ['admin', 'Quản trị'],
    ['cashier', 'Thu ngân'],
    ['barista', 'Pha chế'],
  ];

  BadgeColor _badge(String role) =>
      {'admin': BadgeColor.red, 'cashier': BadgeColor.blue, 'barista': BadgeColor.green}[role]!;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(children: [
      BackBar(title: 'Nhân viên', sub: 'RBAC · ${state.staff.length} người'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            SectionHeader('Danh sách nhân viên', action: '+ Thêm', onAction: () => context.shell.toast('Thêm nhân viên mới', 'plus')),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                for (final s in state.staff)
                  ListRow(
                    leading: Avatar(s.name.split(' ').last[0]),
                    title: s.name,
                    subtitle: '${s.phone} · ${s.br}',
                    trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                      AppBadge('${Seed.roleMeta[s.role]![2]} ${Seed.roleMeta[s.role]![0]}', color: _badge(s.role)),
                      const SizedBox(height: 6),
                      SwitchDot(on: s.active, onTap: () {
                        state.toggleStaff(s.id);
                        context.shell.toast('${s.name}${s.active ? ': đang hoạt động' : ': đã khóa'}', 'user');
                      }),
                    ]),
                  ),
              ]),
            ),
            const SectionHeader('Phân quyền theo vai trò'),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: _matrix(context),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton('Tùy chỉnh vai trò', icon: 'settings', block: true, variant: BtnVariant.ghost,
                  onTap: () => context.shell.toast('Tùy chỉnh vai trò & quyền', 'settings')),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _matrix(BuildContext context) {
    final p = context.palette;
    Widget headerCell(String t) => SizedBox(
        width: 46, child: Text(t, textAlign: TextAlign.center, style: AppType.body(size: 10, weight: FontWeight.w800, color: p.ink2, height: 1.1)));
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line2, width: 2))),
        child: Row(children: [
          Expanded(child: Text('QUYỀN HẠN', style: AppType.body(size: 11.5, weight: FontWeight.w700, color: p.ink2, letterSpacing: 0.3))),
          for (final r in _roles) headerCell(r[1]),
        ]),
      ),
      for (final perm in Seed.perms)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
          child: Row(children: [
            Expanded(child: Text(perm[0] as String, style: AppType.body(size: 12.5, weight: FontWeight.w700, color: p.ink))),
            for (final r in _roles)
              SizedBox(
                width: 46,
                child: Center(
                  child: (perm[1] as List).contains(r[0])
                      ? Text('✓', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.greenD))
                      : Text('–', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.faint)),
                ),
              ),
          ]),
        ),
    ]);
  }
}

/// Khuyến mãi.
class PromosScreen extends StatelessWidget {
  const PromosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final active = state.promos.where((x) => x.on).length;
    return Column(children: [
      BackBar(title: 'Khuyến mãi', sub: '$active chương trình đang chạy'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            SectionHeader('Chương trình', action: '+ Tạo', onAction: () => context.shell.toast('Tạo khuyến mãi mới', 'plus')),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                for (var i = 0; i < state.promos.length; i++)
                  ListRow(
                    leading: LeadIcon(emoji: state.promos[i].emoji),
                    title: state.promos[i].name,
                    subtitle: state.promos[i].desc,
                    trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                      AppBadge(state.promos[i].type, color: state.promos[i].on ? BadgeColor.green : BadgeColor.amber),
                      const SizedBox(height: 6),
                      SwitchDot(on: state.promos[i].on, onTap: () {
                        final wasOn = state.promos[i].on;
                        state.togglePromo(i);
                        context.shell.toast('${state.promos[i].name}${!wasOn ? ': bật' : ': tắt'}', 'gift');
                      }),
                    ]),
                  ),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }
}

/// Chi nhánh.
class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    return Column(children: [
      BackBar(title: 'Chi nhánh', sub: '${state.branches.length} cửa hàng'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          children: [
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                for (final b in state.branches)
                  ListRow(
                    leading: LeadIcon(icon: 'store', bg: b.open ? p.greenBg : p.cream2, fg: b.open ? p.greenD : p.muted),
                    title: b.name,
                    subtitle: b.addr,
                    trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                      Text(kShort(b.rev), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
                      const SizedBox(height: 2),
                      Text('${b.staff} NV · ${b.open ? 'mở' : 'đóng'}', style: AppType.body(size: 11, weight: FontWeight.w600, color: p.muted)),
                    ]),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: AppButton('Thêm chi nhánh', icon: 'plus', block: true, variant: BtnVariant.ghost,
                  onTap: () => context.shell.toast('Thêm chi nhánh mới', 'plus')),
            ),
          ],
        ),
      ),
    ]);
  }
}

/// Ca làm việc (admin view).
class ShiftAdminScreen extends StatelessWidget {
  const ShiftAdminScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    return Column(children: [
      BackBar(title: 'Ca làm việc', sub: 'Hôm nay · ${state.adminBranch}'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                Expanded(child: StatCard(icon: 'clock', bg: p.greenBg, fg: p.greenD, value: '2', label: 'Ca đang mở')),
                const SizedBox(width: 10),
                Expanded(child: StatCard(icon: 'cash', bg: const Color(0xFFFCE8DF), fg: p.terracotta, value: kShort(4820000), label: 'Tiền mặt hiện có')),
              ]),
            ),
            const SectionHeader('Ca hôm nay'),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                ListRow(
                  leading: LeadIcon(emoji: '🟢', bg: p.greenBg),
                  title: 'Ca sáng · 06:00–14:00',
                  subtitle: 'Trần Thị Bình · đã đóng',
                  trailing: Text('2.1tr', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
                ),
                ListRow(
                  leading: LeadIcon(emoji: '🟢', bg: p.greenBg),
                  title: 'Ca chiều · 14:00–22:00',
                  subtitle: 'Lê Minh Châu · đang mở',
                  trailing: Text('2.7tr', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.terracotta)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton('Lịch sử đối soát', icon: 'history', block: true, variant: BtnVariant.ghost,
                  onTap: () => context.shell.toast('Xem lịch sử đối soát ca', 'history')),
            ),
          ],
        ),
      ),
    ]);
  }
}
