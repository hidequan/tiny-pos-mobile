import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../data/models.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../theme/app_icons.dart';
import 'shell.dart';
import '../screens/login_screen.dart';
import '../screens/cashier/cashier_shell.dart';
import '../screens/kds/kds_shell.dart';
import '../screens/admin/admin_shell.dart';

/// The mobile "phone frame": a fixed-width (max 480px) column centered on a
/// warm backdrop — matching the mockup's non-responsive web shell exactly.
class PhoneFrame extends StatefulWidget {
  const PhoneFrame({super.key});

  @override
  State<PhoneFrame> createState() => _PhoneFrameState();
}

class _PhoneFrameState extends State<PhoneFrame> {
  final ShellController _shell = ShellController();

  @override
  void dispose() {
    _shell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final palette = state.isDark ? Palette.dark : Palette.light;

    return Scaffold(
      backgroundColor: const Color(0xFFE9E0D2),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            color: palette.cream,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(color: palette.cream),
            child: PaletteScope(
              palette: palette,
              child: ShellScope(
                controller: _shell,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(child: _body(state)),
                        if (state.role != null) _BottomNav(state: state),
                      ],
                    ),
                    const ShellOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(AppState state) {
    switch (state.role) {
      case null:
        return const LoginScreen();
      case Role.cashier:
        return const CashierShell();
      case Role.kds:
        return const KdsShell();
      case Role.admin:
        return const AdminShell();
    }
  }
}

/// `.bottomnav` — role-specific tab bar.
class _BottomNav extends StatelessWidget {
  final AppState state;
  const _BottomNav({required this.state});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    late final List<List<String>> tabs;
    late final String active;
    late final void Function(String) onTap;

    switch (state.role!) {
      case Role.cashier:
        tabs = [
          ['sell', 'Bán hàng', 'sell'],
          ['orders', 'Đơn hàng', 'receipt'],
          ['tables', 'Sơ đồ bàn', 'table'],
          ['shift', 'Ca làm', 'clock'],
        ];
        active = state.cashTab;
        onTap = state.setCashTab;
        break;
      case Role.kds:
        tabs = [
          ['queue', 'Hàng chờ', 'fire'],
          ['done', 'Đã xong', 'check'],
          ['stats', 'Thống kê', 'chart'],
        ];
        active = state.kdsTab;
        onTap = state.setKdsTab;
        break;
      case Role.admin:
        tabs = [
          ['home', 'Tổng quan', 'grid'],
          ['menu', 'Thực đơn', 'book'],
          ['inv', 'Kho', 'box'],
          ['reports', 'Báo cáo', 'chart'],
          ['more', 'Thêm', 'layers'],
        ];
        active = state.adminTab;
        onTap = state.setAdminTab;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        border: Border(top: BorderSide(color: p.line)),
        boxShadow: const [BoxShadow(color: Color(0x16281206), blurRadius: 24, offset: Offset(0, -8))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
          child: Row(
            children: [
              for (final t in tabs)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(t[0]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.get(t[2]), size: 23, color: active == t[0] ? p.terracotta : p.muted),
                          const SizedBox(height: 3),
                          Text(
                            t[1],
                            maxLines: 1,
                            style: AppType.body(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: active == t[0] ? p.terracotta : p.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
