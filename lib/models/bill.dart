/// A line on a bill, as returned by the POS bill endpoints.
class BillItem {
  final String id;
  final String? variantId;
  final String productName;
  final String? variantName;
  final String? sizeName;
  final int unitPrice;
  final int quantity;
  final int lineTotal;
  final String? note;
  final String status;
  BillItem({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.sizeName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.note,
    required this.status,
  });

  static int _int(dynamic v) =>
      v == null ? 0 : (v is num ? v.round() : double.tryParse(v.toString())?.round() ?? 0);

  factory BillItem.fromJson(Map j) => BillItem(
        id: j['id'] as String,
        variantId: j['variantId'] as String?,
        productName: (j['productName'] ?? '') as String,
        variantName: j['variantName'] as String?,
        sizeName: j['sizeName'] as String?,
        unitPrice: _int(j['unitPrice']),
        quantity: (j['quantity'] as num?)?.toInt() ?? 0,
        lineTotal: _int(j['lineTotal']),
        note: j['note'] as String?,
        status: (j['status'] ?? '') as String,
      );
}

/// A bill (order) shared with the web backend.
class Bill {
  final String id;
  final String billCode;
  final String status; // DRAFT | SENT_TO_BAR_UNPAID | PAID | VOIDED ...
  final String serviceType; // TAKE_AWAY | DINE_IN
  final int subtotal;
  final int discountTotal;
  final int grandTotal;
  final int paidTotal;
  final String? note;
  final DateTime? paidAt;
  final List<BillItem> items;

  Bill({
    required this.id,
    required this.billCode,
    required this.status,
    required this.serviceType,
    required this.subtotal,
    required this.discountTotal,
    required this.grandTotal,
    required this.paidTotal,
    required this.note,
    required this.paidAt,
    required this.items,
  });

  factory Bill.fromJson(Map j) => Bill(
        id: j['id'] as String,
        billCode: (j['billCode'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        serviceType: (j['serviceType'] ?? 'TAKE_AWAY') as String,
        subtotal: BillItem._int(j['subtotal']),
        discountTotal: BillItem._int(j['discountTotal']),
        grandTotal: BillItem._int(j['grandTotal']),
        paidTotal: BillItem._int(j['paidTotal']),
        note: j['note'] as String?,
        paidAt: j['paidAt'] != null ? DateTime.tryParse(j['paidAt'].toString()) : null,
        items: ((j['items'] as List?) ?? const []).map((e) => BillItem.fromJson(e as Map)).toList(),
      );

  int get itemCount => items.fold(0, (a, i) => a + i.quantity);
  bool get isPaid => status == 'PAID';
}

/// One line to POST when creating/adding to a bill (matches BillItemInput).
class BillItemInput {
  final String variantId;
  final int quantity;
  final List<String> toppingIds;
  final int? sugar;
  final int? ice;
  final String? note;
  BillItemInput({
    required this.variantId,
    required this.quantity,
    this.toppingIds = const [],
    this.sugar,
    this.ice,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'variantId': variantId,
        'quantity': quantity,
        if (toppingIds.isNotEmpty) 'toppingIds': toppingIds,
        if (sugar != null) 'sugar': sugar,
        if (ice != null) 'ice': ice,
        if (note != null && note!.isNotEmpty) 'note': note,
      };
}
