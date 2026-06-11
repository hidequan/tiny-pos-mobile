int _int(dynamic v) =>
    v == null ? 0 : (v is num ? v.round() : double.tryParse(v.toString())?.round() ?? 0);

/// Cash reconciliation summary for a shift (server-computed).
class ShiftSummary {
  final int openingCash;
  final int cashSales;
  final int cashIn;
  final int cashOut; // typically negative
  final int cashRefund;
  final int expectedCash;
  final int sentToBarUnpaidCount;
  final int pendingApprovals;
  ShiftSummary({
    required this.openingCash,
    required this.cashSales,
    required this.cashIn,
    required this.cashOut,
    required this.cashRefund,
    required this.expectedCash,
    required this.sentToBarUnpaidCount,
    required this.pendingApprovals,
  });

  factory ShiftSummary.fromJson(Map j) => ShiftSummary(
        openingCash: _int(j['openingCash']),
        cashSales: _int(j['cashSales']),
        cashIn: _int(j['cashIn']),
        cashOut: _int(j['cashOut']),
        cashRefund: _int(j['cashRefund']),
        expectedCash: _int(j['expectedCash']),
        sentToBarUnpaidCount: (j['sentToBarUnpaidCount'] as num?)?.toInt() ?? 0,
        pendingApprovals: (j['pendingApprovals'] as num?)?.toInt() ?? 0,
      );

  static ShiftSummary empty() => ShiftSummary(
      openingCash: 0, cashSales: 0, cashIn: 0, cashOut: 0, cashRefund: 0,
      expectedCash: 0, sentToBarUnpaidCount: 0, pendingApprovals: 0);
}

/// A cashier work shift, as returned by /pos/shifts.
class Shift {
  final String id;
  final String shiftCode;
  final String status; // OPEN | CLOSED | CONFIRMED | ...
  final int openingCash;
  final int? expectedCash;
  final int? actualCash;
  final int? difference;
  final String? shiftType; // CA_SANG | CA_CHIEU | ...
  final DateTime? openedAt;
  final DateTime? closedAt;
  final ShiftSummary summary;

  Shift({
    required this.id,
    required this.shiftCode,
    required this.status,
    required this.openingCash,
    required this.expectedCash,
    required this.actualCash,
    required this.difference,
    required this.shiftType,
    required this.openedAt,
    required this.closedAt,
    required this.summary,
  });

  factory Shift.fromJson(Map j) => Shift(
        id: j['id'] as String,
        shiftCode: (j['shiftCode'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        openingCash: _int(j['openingCash']),
        expectedCash: j['expectedCash'] != null ? _int(j['expectedCash']) : null,
        actualCash: j['actualCash'] != null ? _int(j['actualCash']) : null,
        difference: j['difference'] != null ? _int(j['difference']) : null,
        shiftType: j['shiftType'] as String?,
        openedAt: j['openedAt'] != null ? DateTime.tryParse(j['openedAt'].toString()) : null,
        closedAt: j['closedAt'] != null ? DateTime.tryParse(j['closedAt'].toString()) : null,
        summary: j['summary'] != null
            ? ShiftSummary.fromJson(j['summary'] as Map)
            : ShiftSummary.empty(),
      );

  bool get isOpen => status == 'OPEN';
  String get shiftTypeLabel => switch (shiftType) {
        'CA_SANG' => 'Ca sáng',
        'CA_CHIEU' => 'Ca chiều',
        'CA_TOI' => 'Ca tối',
        _ => 'Ca làm việc',
      };
}
