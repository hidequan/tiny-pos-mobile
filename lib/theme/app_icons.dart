import 'package:flutter/material.dart';

/// Maps the mockup's named SVG icons to the closest Material icon.
/// Keys match the `I = {...}` icon set in `tinypos.html`.
class AppIcons {
  static const Map<String, IconData> _map = {
    'sell': Icons.shopping_cart_outlined,
    'receipt': Icons.receipt_long_outlined,
    'table': Icons.table_restaurant_outlined,
    'clock': Icons.access_time_rounded,
    'chart': Icons.bar_chart_rounded,
    'book': Icons.menu_book_outlined,
    'box': Icons.inventory_2_outlined,
    'report': Icons.description_outlined,
    'grid': Icons.grid_view_rounded,
    'fire': Icons.local_fire_department_outlined,
    'user': Icons.person_outline_rounded,
    'users': Icons.groups_outlined,
    'settings': Icons.settings_outlined,
    'bell': Icons.notifications_outlined,
    'search': Icons.search_rounded,
    'back': Icons.chevron_left_rounded,
    'forward': Icons.chevron_right_rounded,
    'plus': Icons.add_rounded,
    'check': Icons.check_rounded,
    'cash': Icons.payments_outlined,
    'card': Icons.credit_card_rounded,
    'qr': Icons.qr_code_2_rounded,
    'wallet': Icons.account_balance_wallet_outlined,
    'tag': Icons.sell_outlined,
    'store': Icons.storefront_outlined,
    'print': Icons.print_outlined,
    'edit': Icons.edit_outlined,
    'trend': Icons.trending_up_rounded,
    'filter': Icons.filter_alt_outlined,
    'scan': Icons.qr_code_scanner_rounded,
    'logout': Icons.logout_rounded,
    'coffee': Icons.local_cafe_outlined,
    'history': Icons.history_rounded,
    'gift': Icons.card_giftcard_rounded,
    'layers': Icons.layers_outlined,
  };

  static IconData get(String name) => _map[name] ?? Icons.circle_outlined;
}
