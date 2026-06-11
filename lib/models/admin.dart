double _num(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);

/// GET /admin/users — a staff member.
class StaffMember {
  final String id;
  final String username;
  final String fullName;
  final String staffRole; // CASHIER | BARISTA | MANAGER | ADMIN | SUPER_ADMIN
  final String status; // ACTIVE | INACTIVE | ...
  StaffMember({
    required this.id,
    required this.username,
    required this.fullName,
    required this.staffRole,
    required this.status,
  });

  factory StaffMember.fromJson(Map j) => StaffMember(
        id: j['id'] as String,
        username: (j['username'] ?? '') as String,
        fullName: (j['fullName'] ?? '') as String,
        staffRole: (j['staffRole'] ?? '') as String,
        status: (j['status'] ?? '') as String,
      );

  bool get active => status == 'ACTIVE';
  String get roleLabel => switch (staffRole) {
        'CASHIER' => 'Thu ngân',
        'BARISTA' => 'Pha chế',
        'MANAGER' => 'Quản lý',
        'ADMIN' => 'Quản trị',
        'SUPER_ADMIN' => 'Quản trị cấp cao',
        _ => staffRole,
      };
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return username.isNotEmpty ? username[0].toUpperCase() : '?';
    return parts.last[0].toUpperCase();
  }
}

/// GET /admin/inventory/balances — on-hand stock per ingredient.
class StockBalance {
  final String id;
  final String code;
  final String name;
  final String unit;
  final double onHand;
  final double reserved;
  final double minStock;
  StockBalance({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    required this.onHand,
    required this.reserved,
    required this.minStock,
  });

  factory StockBalance.fromJson(Map j) {
    final ing = (j['ingredient'] as Map?) ?? const {};
    return StockBalance(
      id: j['id'] as String,
      code: (ing['code'] ?? j['code'] ?? '') as String,
      name: (ing['name'] ?? j['name'] ?? '') as String,
      unit: (ing['unit'] ?? j['unit'] ?? '') as String,
      onHand: _num(j['onHand']),
      reserved: _num(j['reserved']),
      minStock: _num(ing['minStock'] ?? j['minStock']),
    );
  }

  bool get low => minStock > 0 && onHand <= minStock;
  /// Fill ratio vs a soft "full" of 3× the safety threshold (for the bar).
  double get ratio {
    final full = minStock > 0 ? minStock * 3 : (onHand <= 0 ? 1 : onHand);
    return (onHand / full).clamp(0, 1).toDouble();
  }
}

/// GET /admin/bom-recipes — a product/topping recipe (định lượng).
class BomItem {
  final String ingredientName;
  final double quantity;
  final String unit;
  BomItem({required this.ingredientName, required this.quantity, required this.unit});
  factory BomItem.fromJson(Map j) {
    final ing = (j['ingredient'] as Map?) ?? const {};
    return BomItem(
      ingredientName: (ing['name'] ?? j['ingredientName'] ?? 'Nguyên liệu') as String,
      quantity: _num(j['quantity']),
      unit: (j['unit'] ?? ing['unit'] ?? '') as String,
    );
  }
}

class BomRecipe {
  final String id;
  final String name;
  final bool isActive;
  final List<BomItem> items;
  BomRecipe({required this.id, required this.name, required this.isActive, required this.items});
  factory BomRecipe.fromJson(Map j) => BomRecipe(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        isActive: (j['isActive'] as bool?) ?? true,
        items: ((j['items'] as List?) ?? const []).map((e) => BomItem.fromJson(e as Map)).toList(),
      );
}
