int _int(dynamic v) =>
    v == null ? 0 : (v is num ? v.round() : double.tryParse(v.toString())?.round() ?? 0);

/// GET /admin/reports/sales-summary
class SalesSummary {
  final int revenue;
  final int billCount;
  final int avgBill;
  final int itemsSold;
  final int discountTotal;
  final int refundedTotal;
  final int takeAway;
  final int dineIn;
  SalesSummary({
    required this.revenue,
    required this.billCount,
    required this.avgBill,
    required this.itemsSold,
    required this.discountTotal,
    required this.refundedTotal,
    required this.takeAway,
    required this.dineIn,
  });

  factory SalesSummary.fromJson(Map j) {
    final svc = (j['byService'] as Map?) ?? const {};
    return SalesSummary(
      revenue: _int(j['revenue']),
      billCount: _int(j['billCount']),
      avgBill: _int(j['avgBill']),
      itemsSold: _int(j['itemsSold']),
      discountTotal: _int(j['discountTotal']),
      refundedTotal: _int(j['refundedTotal']),
      takeAway: _int(svc['TAKE_AWAY']),
      dineIn: _int(svc['DINE_IN']),
    );
  }

  static SalesSummary empty() =>
      SalesSummary(revenue: 0, billCount: 0, avgBill: 0, itemsSold: 0, discountTotal: 0, refundedTotal: 0, takeAway: 0, dineIn: 0);
}

/// GET /admin/reports/best-selling-products
class BestSeller {
  final String productName;
  final int quantity;
  final int revenue;
  BestSeller({required this.productName, required this.quantity, required this.revenue});
  factory BestSeller.fromJson(Map j) => BestSeller(
        productName: (j['productName'] ?? '') as String,
        quantity: _int(j['quantity']),
        revenue: _int(j['revenue']),
      );
}

/// GET /admin/reports/payment-methods
class PayMethodStat {
  final String method; // CASH | QR | CARD | WALLET ...
  final int amount;
  final int count;
  PayMethodStat({required this.method, required this.amount, required this.count});
  factory PayMethodStat.fromJson(Map j) => PayMethodStat(
        method: (j['method'] ?? '') as String,
        amount: _int(j['amount']),
        count: _int(j['count']),
      );

  String get label => switch (method) {
        'CASH' => 'Tiền mặt',
        'QR' => 'Chuyển khoản',
        'CARD' => 'Thẻ',
        'WALLET' || 'MOMO' => 'Ví điện tử',
        _ => method,
      };
}
