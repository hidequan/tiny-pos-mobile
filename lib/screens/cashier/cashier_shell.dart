import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import 'sell_screen.dart';
import 'orders_screen.dart';
import 'tables_screen.dart';
import 'shift_screen.dart';

class CashierShell extends StatelessWidget {
  const CashierShell({super.key});
  @override
  Widget build(BuildContext context) {
    final tab = context.watch<AppState>().cashTab;
    switch (tab) {
      case 'orders':
        return const OrdersScreen();
      case 'tables':
        return const TablesScreen();
      case 'shift':
        return const ShiftScreen();
      case 'sell':
      default:
        return const SellScreen();
    }
  }
}
