import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import 'admin_home.dart';
import 'admin_menu.dart';
import 'admin_inv.dart';
import 'admin_reports.dart';
import 'admin_more.dart';
import 'admin_subs.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.adminTab == 'more' && state.adminSub != null) {
      switch (state.adminSub) {
        case 'staff':
          return const StaffScreen();
        case 'promos':
          return const PromosScreen();
        case 'branches':
          return const BranchesScreen();
        case 'shiftadmin':
          return const ShiftAdminScreen();
      }
    }
    switch (state.adminTab) {
      case 'menu':
        return const AdminMenuScreen();
      case 'inv':
        return const AdminInvScreen();
      case 'reports':
        return const AdminReportsScreen();
      case 'more':
        return const AdminMoreScreen();
      case 'home':
      default:
        return const AdminHomeScreen();
    }
  }
}
