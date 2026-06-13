import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import 'admin_home.dart';
import 'admin_menu.dart';
import 'admin_inv.dart';
import 'admin_reports.dart';
import 'admin_more.dart';
import 'admin_subs.dart';
import 'admin_tables.dart';
import 'admin_cashflow.dart';
import 'admin_bills.dart';
import 'admin_menu_config.dart';
import 'admin_shifts.dart';
import 'admin_hardware.dart';
import 'admin_system.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.adminTab == 'more' && state.adminSub != null) {
      switch (state.adminSub) {
        case 'voidrefund':
          return const VoidRefundScreen();
        case 'tablesadmin':
          return const TablesAdminScreen();
        case 'cashflow':
          return const CashFlowScreen();
        case 'adminbills':
          return const AdminBillsScreen();
        case 'menuconfig':
          return const MenuConfigScreen();
        case 'hardware':
          return const HardwareScreen();
        case 'audit':
          return const AuditLogScreen();
        case 'syncmonitor':
          return const SyncMonitorScreen();
        case 'staff':
          return const StaffScreen();
        case 'promos':
          return const VouchersScreen();
        case 'branches':
          return const BranchesScreen();
        case 'shiftadmin':
          return const AdminShiftsScreen();
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
