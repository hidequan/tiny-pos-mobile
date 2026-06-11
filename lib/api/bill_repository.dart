import '../models/bill.dart';
import 'api_client.dart';

/// POS bill operations against the shared backend (/pos/bills...).
/// All of these are WRITES except [listBills]/[unpaidBills] — only run write
/// tests against a local/test backend, never the production "Mỹ Nhân" branch.
class BillRepository {
  final ApiClient api;
  BillRepository(this.api);

  /// Create a bill (optionally with items) — POST /pos/bills.
  Future<Bill> createBill({
    required String serviceType, // TAKE_AWAY | DINE_IN
    List<BillItemInput> items = const [],
    String? tableSessionId,
    String? customerId,
    String? note,
    String? idempotencyKey,
  }) async {
    final data = await api.post('/pos/bills', body: {
      'serviceType': serviceType,
      'tableSessionId': ?tableSessionId,
      'customerId': ?customerId,
      if (note != null && note.isNotEmpty) 'note': note,
      if (items.isNotEmpty) 'items': items.map((e) => e.toJson()).toList(),
      'idempotencyKey': idempotencyKey ?? _key(),
    });
    return Bill.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Add items to an existing bill — POST /pos/bills/{id}/items.
  Future<Bill> addItems(String billId, List<BillItemInput> items) async {
    final data = await api.post('/pos/bills/$billId/items',
        body: {'items': items.map((e) => e.toJson()).toList()});
    return Bill.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Pay a bill in cash — POST /pos/bills/{id}/payments/cash.
  Future<Bill> payCash(String billId, {required int received, int? amount}) async {
    final data = await api.post('/pos/bills/$billId/payments/cash', body: {
      'received': received,
      'amount': ?amount,
      'idempotencyKey': _key(),
    });
    return _billFrom(data);
  }

  /// Create a dynamic QR (mock gateway) — POST /pos/bills/{id}/payments/qr.
  /// Returns the pending QR (paymentId + payload + amount); not yet collected.
  Future<QrPayment> createQr(String billId, {int? amount}) async {
    final data = await api.post('/pos/bills/$billId/payments/qr', body: {'amount': ?amount});
    return QrPayment.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Confirm a QR/transfer payment manually (cashier saw the money land) —
  /// POST /pos/payments/{paymentId}/manual-confirm. Returns the paid bill.
  Future<Bill> confirmPayment(String paymentId, {int? amount, String? referenceCode}) async {
    final data = await api.post('/pos/payments/$paymentId/manual-confirm', body: {
      'amount': ?amount,
      'referenceCode': ?referenceCode,
    });
    return _billFrom(data);
  }

  Future<List<Bill>> listBills() async {
    final data = await api.get('/pos/bills');
    final list = data is List ? data : ((data as Map)['items'] ?? (data)['data'] ?? []) as List;
    return list.map((e) => Bill.fromJson(e as Map)).toList();
  }

  Future<List<Bill>> unpaidBills() async {
    final data = await api.get('/pos/bills/unpaid');
    final list = data is List ? data : ((data as Map)['items'] ?? []) as List;
    return list.map((e) => Bill.fromJson(e as Map)).toList();
  }

  // The cash-pay response may be the bill, or {bill, payment} — normalise it.
  Bill _billFrom(dynamic data) {
    final m = Map<String, dynamic>.from(data as Map);
    if (m['bill'] is Map) return Bill.fromJson(Map<String, dynamic>.from(m['bill'] as Map));
    return Bill.fromJson(m);
  }

  // A simple idempotency key without dart:io (no Date.now in this env's tests,
  // but runtime is fine via DateTime).
  String _key() => 'app-${DateTime.now().microsecondsSinceEpoch}';
}
