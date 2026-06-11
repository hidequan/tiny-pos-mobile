import 'bill.dart';

/// Summary of the active session on a table, as returned inline by /pos/table-map.
class TableSessionSummary {
  final String id;
  final String status; // OPEN | WAITING | SERVED | PAYMENT_REQUESTED
  final int guestCount;
  final int billCount;
  final int total;
  TableSessionSummary({
    required this.id,
    required this.status,
    required this.guestCount,
    required this.billCount,
    required this.total,
  });

  static int _int(dynamic v) =>
      v == null ? 0 : (v is num ? v.round() : double.tryParse(v.toString())?.round() ?? 0);

  factory TableSessionSummary.fromJson(Map j) => TableSessionSummary(
        id: j['id'] as String,
        status: (j['status'] ?? '') as String,
        guestCount: (j['guestCount'] as num?)?.toInt() ?? 0,
        billCount: (j['billCount'] as num?)?.toInt() ?? 0,
        total: _int(j['total']),
      );
}

/// One table on the floor map.
class CafeTable {
  final String id;
  final String code;
  final String? name;
  final int seats;
  final String status; // EMPTY | OCCUPIED | DIRTY | ORDERING | ... | LOCKED
  final int posX;
  final int posY;
  final TableSessionSummary? session;
  CafeTable({
    required this.id,
    required this.code,
    required this.name,
    required this.seats,
    required this.status,
    required this.posX,
    required this.posY,
    required this.session,
  });

  factory CafeTable.fromJson(Map j) => CafeTable(
        id: j['id'] as String,
        code: (j['code'] ?? '') as String,
        name: j['name'] as String?,
        seats: (j['seats'] as num?)?.toInt() ?? 0,
        status: (j['status'] ?? 'EMPTY') as String,
        posX: (j['posX'] as num?)?.toInt() ?? 0,
        posY: (j['posY'] as num?)?.toInt() ?? 0,
        session: j['session'] != null ? TableSessionSummary.fromJson(j['session'] as Map) : null,
      );

  String get label => (name != null && name!.isNotEmpty) ? name! : code;
  bool get isEmpty => status == 'EMPTY';
  bool get isDirty => status == 'DIRTY';
  bool get isLocked => status == 'LOCKED';
  bool get isOccupied => session != null || !(isEmpty || isDirty || isLocked);
  int get total => session?.total ?? 0;
}

/// A floor area (e.g. Tầng 1) holding tables.
class TableArea {
  final String id;
  final String name;
  final int level;
  final List<CafeTable> tables;
  TableArea({required this.id, required this.name, required this.level, required this.tables});

  factory TableArea.fromJson(Map j) => TableArea(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        level: (j['level'] as num?)?.toInt() ?? 1,
        tables: ((j['tables'] as List?) ?? const [])
            .map((e) => CafeTable.fromJson(e as Map))
            .toList(),
      );
}

/// Full session detail (table + bills with items), from /pos/table-sessions/:id.
class TableSessionDetail {
  final String id;
  final String status;
  final int guestCount;
  final String tableId;
  final String tableCode;
  final List<Bill> bills;
  TableSessionDetail({
    required this.id,
    required this.status,
    required this.guestCount,
    required this.tableId,
    required this.tableCode,
    required this.bills,
  });

  factory TableSessionDetail.fromJson(Map j) {
    final table = (j['table'] as Map?) ?? const {};
    return TableSessionDetail(
      id: j['id'] as String,
      status: (j['status'] ?? '') as String,
      guestCount: (j['guestCount'] as num?)?.toInt() ?? 0,
      tableId: (table['id'] ?? j['tableId'] ?? '') as String,
      tableCode: (table['code'] ?? '') as String,
      bills: ((j['bills'] as List?) ?? const [])
          .map((e) => Bill.fromJson(e as Map))
          .toList(),
    );
  }

  /// The primary unpaid bill to add items to (first active), or null.
  Bill? get primaryUnpaid {
    for (final b in bills) {
      if (b.status == 'DRAFT' || b.status == 'SENT_TO_BAR_UNPAID' || b.status == 'PENDING_PAYMENT') {
        return b;
      }
    }
    return bills.isNotEmpty ? bills.first : null;
  }

  int get grandTotal => bills
      .where((b) => b.status != 'VOIDED')
      .fold(0, (a, b) => a + b.grandTotal);
  int get itemCount => bills.fold(0, (a, b) => a + b.itemCount);
}
