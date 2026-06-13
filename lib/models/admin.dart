double _num(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);

int _int(dynamic v) =>
    v == null ? 0 : (v is num ? v.round() : double.tryParse(v.toString())?.round() ?? 0);

/// GET /admin/audit-logs — one data-change audit row.
class AuditRow {
  final String id;
  final String action;
  final String entityType;
  final DateTime? createdAt;
  final String? actorName;
  final String? actorUsername;
  AuditRow({
    required this.id,
    required this.action,
    required this.entityType,
    required this.createdAt,
    required this.actorName,
    required this.actorUsername,
  });
  factory AuditRow.fromJson(Map j) {
    final actor = j['actor'] as Map?;
    return AuditRow(
      id: j['id'] as String,
      action: (j['action'] ?? '') as String,
      entityType: (j['entityType'] ?? '') as String,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      actorName: actor?['fullName'] as String?,
      actorUsername: actor?['username'] as String?,
    );
  }
}

/// GET /admin/sync/devices — a synced POS device.
class SyncDevice {
  final String id;
  final String deviceId;
  final DateTime? lastSyncedAt;
  final int pendingCount;
  final bool isOnline;
  SyncDevice({
    required this.id,
    required this.deviceId,
    required this.lastSyncedAt,
    required this.pendingCount,
    required this.isOnline,
  });
  factory SyncDevice.fromJson(Map j) => SyncDevice(
        id: j['id'] as String,
        deviceId: (j['deviceId'] ?? '') as String,
        lastSyncedAt: j['lastSyncedAt'] != null ? DateTime.tryParse(j['lastSyncedAt'].toString()) : null,
        pendingCount: (j['pendingCount'] as num?)?.toInt() ?? 0,
        isOnline: (j['isOnline'] as bool?) ?? false,
      );
}

/// GET /admin/sync/conflicts — an unresolved sync conflict.
class SyncConflict {
  final String id;
  final String entityType;
  final String status;
  final String? resolution;
  final DateTime? createdAt;
  SyncConflict({
    required this.id,
    required this.entityType,
    required this.status,
    required this.resolution,
    required this.createdAt,
  });
  factory SyncConflict.fromJson(Map j) => SyncConflict(
        id: j['id'] as String,
        entityType: (j['entityType'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        resolution: j['resolution'] as String?,
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      );
}

/// GET /admin/hardware-devices — a printer / drawer / screen / terminal.
class HwDevice {
  final String id;
  final String name;
  final String type; // BILL_PRINTER | STICKER_PRINTER | CASH_DRAWER | KDS_SCREEN | POS_TERMINAL
  final String connectionType; // AGENT | USB | NETWORK | BLUETOOTH | SERIAL
  final String? address;
  final bool isActive;
  final String? printerName; // config.printerName (Windows printer)
  HwDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.connectionType,
    required this.address,
    required this.isActive,
    required this.printerName,
  });

  factory HwDevice.fromJson(Map j) {
    final config = j['config'] as Map?;
    return HwDevice(
      id: j['id'] as String,
      name: (j['name'] ?? '') as String,
      type: (j['type'] ?? '') as String,
      connectionType: (j['connectionType'] ?? '') as String,
      address: j['address'] as String?,
      isActive: (j['isActive'] as bool?) ?? true,
      printerName: config?['printerName'] as String?,
    );
  }

  bool get isPrinter => type == 'BILL_PRINTER' || type == 'STICKER_PRINTER';
}

/// GET /admin/print-routes — which document type prints to which device.
class PrintRoute {
  final String id;
  final String jobType; // BILL | STICKER | KITCHEN_TICKET
  final String? hardwareName;
  final bool isDefault;
  PrintRoute({required this.id, required this.jobType, required this.hardwareName, required this.isDefault});
  factory PrintRoute.fromJson(Map j) => PrintRoute(
        id: j['id'] as String,
        jobType: (j['jobType'] ?? '') as String,
        hardwareName: ((j['hardware'] as Map?)?['name']) as String?,
        isDefault: (j['isDefault'] as bool?) ?? false,
      );
}

/// GET /admin/cash-drawer-events — a drawer open/attempt audit row.
class DrawerEvent {
  final String id;
  final String type; // OPENED | FAILED | ...
  final String? reason;
  final DateTime? createdAt;
  DrawerEvent({required this.id, required this.type, required this.reason, required this.createdAt});
  factory DrawerEvent.fromJson(Map j) => DrawerEvent(
        id: j['id'] as String,
        type: (j['type'] ?? '') as String,
        reason: j['reason'] as String?,
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      );
}

/// GET /admin/branches — a store branch (manager sees only their own).
class Branch {
  final String id;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final String status;
  final int cashOutLimit;
  final int cashDiffThreshold;
  Branch({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.phone,
    required this.status,
    required this.cashOutLimit,
    required this.cashDiffThreshold,
  });

  factory Branch.fromJson(Map j) => Branch(
        id: j['id'] as String,
        code: (j['code'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        address: j['address'] as String?,
        phone: j['phone'] as String?,
        status: (j['status'] ?? 'ACTIVE') as String,
        cashOutLimit: _int(j['cashOutLimit']),
        cashDiffThreshold: _int(j['cashDiffThreshold']),
      );
}

/// GET /admin/reports/shift-summary — a shift reconciliation row.
class AdminShift {
  final String id;
  final String shiftCode;
  final String status; // OPEN | PENDING_CONFIRMATION | CONFIRMED | ...
  final String? cashier;
  final String? shiftType; // CA_SANG | CA_CHIEU | CA_TOI
  final int openingCash;
  final int? expectedCash;
  final int? actualCash;
  final int? difference;
  final DateTime? openedAt;
  final DateTime? closedAt;
  AdminShift({
    required this.id,
    required this.shiftCode,
    required this.status,
    required this.cashier,
    required this.shiftType,
    required this.openingCash,
    required this.expectedCash,
    required this.actualCash,
    required this.difference,
    required this.openedAt,
    required this.closedAt,
  });

  factory AdminShift.fromJson(Map j) {
    int? optInt(dynamic v) => v == null ? null : _int(v);
    return AdminShift(
      id: j['id'] as String,
      shiftCode: (j['shiftCode'] ?? '') as String,
      status: (j['status'] ?? '') as String,
      cashier: j['cashier'] as String?,
      shiftType: j['shiftType'] as String?,
      openingCash: _int(j['openingCash']),
      expectedCash: optInt(j['expectedCash']),
      actualCash: optInt(j['actualCash']),
      difference: optInt(j['difference']),
      openedAt: j['openedAt'] != null ? DateTime.tryParse(j['openedAt'].toString()) : null,
      closedAt: j['closedAt'] != null ? DateTime.tryParse(j['closedAt'].toString()) : null,
    );
  }

  bool get isPending => status == 'PENDING_CONFIRMATION';

  /// Slot from shiftType, else inferred from the open hour.
  String get slot {
    if (shiftType == 'CA_SANG' || shiftType == 'CA_CHIEU' || shiftType == 'CA_TOI') return shiftType!;
    final h = openedAt?.toLocal().hour ?? 0;
    return h < 12 ? 'CA_SANG' : h < 17 ? 'CA_CHIEU' : 'CA_TOI';
  }
}

/// GET /admin/product-categories — a menu category.
class AdminCategory {
  final String id;
  final String name;
  final int productCount;
  AdminCategory({required this.id, required this.name, required this.productCount});
  factory AdminCategory.fromJson(Map j) => AdminCategory(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        productCount: (((j['_count'] as Map?) ?? const {})['products'] as num?)?.toInt() ?? 0,
      );
}

/// GET /admin/sizes — a size option (S / M / L).
class AdminSize {
  final String id;
  final String code;
  final String name;
  AdminSize({required this.id, required this.code, required this.name});
  factory AdminSize.fromJson(Map j) => AdminSize(
        id: j['id'] as String,
        code: (j['code'] ?? '') as String,
        name: (j['name'] ?? '') as String,
      );
}

/// GET /admin/toppings — a topping add-on.
class AdminTopping {
  final String id;
  final String name;
  final int price;
  AdminTopping({required this.id, required this.name, required this.price});
  factory AdminTopping.fromJson(Map j) => AdminTopping(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        price: _int(j['price']),
      );
}

/// GET /admin/bills — one bill row in the admin bills list.
class AdminBill {
  final String id;
  final String billCode;
  final String status;
  final String serviceType;
  final int grandTotal;
  final int paidTotal;
  final int refundedTotal;
  final int itemCount;
  final DateTime? createdAt;
  final String? cashierName;
  final String? customerName;
  final String? tableCode;
  final List<String> paymentMethods;
  AdminBill({
    required this.id,
    required this.billCode,
    required this.status,
    required this.serviceType,
    required this.grandTotal,
    required this.paidTotal,
    required this.refundedTotal,
    required this.itemCount,
    required this.createdAt,
    required this.cashierName,
    required this.customerName,
    required this.tableCode,
    required this.paymentMethods,
  });

  factory AdminBill.fromJson(Map j) {
    final cashier = j['cashier'] as Map?;
    final customer = j['customer'] as Map?;
    final table = ((j['tableSession'] as Map?)?['table']) as Map?;
    final payments = (j['payments'] as List?) ?? const [];
    final methods = <String>{};
    for (final pmt in payments) {
      if (pmt is Map && pmt['status'] == 'SUCCESS' && pmt['method'] != null) {
        methods.add(pmt['method'].toString());
      }
    }
    return AdminBill(
      id: j['id'] as String,
      billCode: (j['billCode'] ?? '') as String,
      status: (j['status'] ?? '') as String,
      serviceType: (j['serviceType'] ?? 'TAKE_AWAY') as String,
      grandTotal: _int(j['grandTotal']),
      paidTotal: _int(j['paidTotal']),
      refundedTotal: _int(j['refundedTotal']),
      itemCount: (((j['_count'] as Map?) ?? const {})['items'] as num?)?.toInt() ?? 0,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      cashierName: cashier?['fullName'] as String?,
      customerName: customer?['name'] as String?,
      tableCode: table?['code'] as String?,
      paymentMethods: methods.toList(),
    );
  }

  bool get isDineIn => serviceType == 'DINE_IN';
}

/// Aggregate totals returned alongside the admin bills list.
class AdminBillSummary {
  final int totalBills;
  final int paidBills;
  final int paidRevenue;
  final int refundedTotal;
  final int grossTotal;
  AdminBillSummary({
    required this.totalBills,
    required this.paidBills,
    required this.paidRevenue,
    required this.refundedTotal,
    required this.grossTotal,
  });
  factory AdminBillSummary.fromJson(Map j) => AdminBillSummary(
        totalBills: (j['totalBills'] as num?)?.toInt() ?? 0,
        paidBills: (j['paidBills'] as num?)?.toInt() ?? 0,
        paidRevenue: _int(j['paidRevenue']),
        refundedTotal: _int(j['refundedTotal']),
        grossTotal: _int(j['grossTotal']),
      );
  static AdminBillSummary empty() => AdminBillSummary(totalBills: 0, paidBills: 0, paidRevenue: 0, refundedTotal: 0, grossTotal: 0);
}

/// GET /admin/cash-movements — one cash drawer ledger entry.
class CashMovement {
  final String id;
  final String type; // OPENING | CASH_SALE | CASH_IN | CASH_OUT | CASH_REFUND | ADJUSTMENT | CLOSING
  final String status; // POSTED | PENDING | APPROVED | REJECTED
  final int amount; // signed (CASH_OUT/REFUND are negative)
  final String? reason;
  final DateTime? createdAt;
  final String? shiftCode;
  final String? cashierName;
  CashMovement({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.reason,
    required this.createdAt,
    required this.shiftCode,
    required this.cashierName,
  });

  factory CashMovement.fromJson(Map j) {
    final shift = j['shift'] as Map?;
    final cashier = shift?['cashier'] as Map?;
    return CashMovement(
      id: j['id'] as String,
      type: (j['type'] ?? '') as String,
      status: (j['status'] ?? 'POSTED') as String,
      amount: _int(j['amount']),
      reason: j['reason'] as String?,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      shiftCode: shift?['shiftCode'] as String?,
      cashierName: cashier?['fullName'] as String?,
    );
  }

  bool get isPending => status == 'PENDING';
}

/// GET /admin/branches/:branchId/floor-areas — a zone/floor holding tables.
class FloorArea {
  final String id;
  final String name;
  final int level;
  final int tableCount;
  FloorArea({required this.id, required this.name, required this.level, required this.tableCount});
  factory FloorArea.fromJson(Map j) => FloorArea(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        level: (j['level'] as num?)?.toInt() ?? 1,
        tableCount: (((j['_count'] as Map?) ?? const {})['tables'] as num?)?.toInt() ?? 0,
      );
}

/// GET /admin/floor-areas/:areaId/tables — a configurable table.
class AdminTable {
  final String id;
  final String code;
  final String? name;
  final int seats;
  final String status; // EMPTY | OCCUPIED | DIRTY | LOCKED ...
  AdminTable({required this.id, required this.code, required this.name, required this.seats, required this.status});
  factory AdminTable.fromJson(Map j) => AdminTable(
        id: j['id'] as String,
        code: (j['code'] ?? '') as String,
        name: j['name'] as String?,
        seats: (j['seats'] as num?)?.toInt() ?? 0,
        status: (j['status'] ?? 'EMPTY') as String,
      );
  String get label => (name != null && name!.isNotEmpty) ? name! : code;
}

/// GET /admin/vouchers — a discount code.
class Voucher {
  final String id;
  final String code;
  final String name;
  final String status; // ACTIVE | INACTIVE | EXPIRED | USED_UP
  final String discountType; // PERCENTAGE | FIXED_AMOUNT
  final int discountValue; // % when PERCENTAGE, else VND
  final int minOrderAmount;
  final int? maxDiscount;
  final int? usageLimit;
  final int usageCount;
  final DateTime? startsAt;
  final DateTime? endsAt;
  Voucher({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.maxDiscount,
    required this.usageLimit,
    required this.usageCount,
    required this.startsAt,
    required this.endsAt,
  });

  factory Voucher.fromJson(Map j) => Voucher(
        id: j['id'] as String,
        code: (j['code'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        status: (j['status'] ?? 'ACTIVE') as String,
        discountType: (j['discountType'] ?? 'PERCENTAGE') as String,
        discountValue: _int(j['discountValue']),
        minOrderAmount: _int(j['minOrderAmount']),
        maxDiscount: j['maxDiscount'] != null ? _int(j['maxDiscount']) : null,
        usageLimit: (j['usageLimit'] as num?)?.toInt(),
        usageCount: (j['usageCount'] as num?)?.toInt() ?? 0,
        startsAt: j['startsAt'] != null ? DateTime.tryParse(j['startsAt'].toString()) : null,
        endsAt: j['endsAt'] != null ? DateTime.tryParse(j['endsAt'].toString()) : null,
      );

  bool get isPercent => discountType == 'PERCENTAGE';
  bool get isActive => status == 'ACTIVE';
}

/// GET /admin/void-refund-requests — a cashier's request awaiting Manager review.
class VoidRefundRequest {
  final String id;
  final String type; // VOID | REFUND
  final String status; // PENDING | APPROVED | REJECTED
  final String? reason;
  final int? amount;
  final DateTime? createdAt;
  final String billCode;
  final int billGrandTotal;
  VoidRefundRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.reason,
    required this.amount,
    required this.createdAt,
    required this.billCode,
    required this.billGrandTotal,
  });

  factory VoidRefundRequest.fromJson(Map j) {
    final bill = (j['bill'] as Map?) ?? const {};
    return VoidRefundRequest(
      id: j['id'] as String,
      type: (j['type'] ?? '') as String,
      status: (j['status'] ?? 'PENDING') as String,
      reason: j['reason'] as String?,
      amount: j['amount'] != null ? _int(j['amount']) : null,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      billCode: (bill['billCode'] ?? '') as String,
      billGrandTotal: _int(bill['grandTotal']),
    );
  }

  bool get isVoid => type == 'VOID';
  bool get isPending => status == 'PENDING';
  int get displayAmount => amount ?? billGrandTotal;
}

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
  final String id; // balance row id
  final String ingredientId; // the ingredient FK (used for stock-in/adjust)
  final String code;
  final String name;
  final String unit;
  final double onHand;
  final double reserved;
  final double minStock;
  StockBalance({
    required this.id,
    required this.ingredientId,
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
      ingredientId: (j['ingredientId'] ?? ing['id'] ?? j['id']) as String,
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
