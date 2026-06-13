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

  /// Push a bill to the bar/KDS for preparation — POST /pos/bills/{id}/send-to-bar.
  /// Done after payment (so paid orders reach the bar) and for the "Gửi Bar,
  /// thu tiền sau" flow. Best-effort: callers may ignore failures.
  Future<void> sendToBar(String billId) => api.post('/pos/bills/$billId/send-to-bar');

  /// Hold / resume a bill — POST /pos/bills/{id}/hold | /resume.
  Future<void> holdBill(String billId) => api.post('/pos/bills/$billId/hold');
  Future<void> resumeBill(String billId) => api.post('/pos/bills/$billId/resume');

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

  /// Apply a voucher code to a bill (server recomputes the discount) —
  /// POST /pos/bills/{id}/apply-voucher. Returns the updated bill.
  Future<Bill> applyVoucher(String billId, String code) async {
    final data = await api.post('/pos/bills/$billId/apply-voucher', body: {'code': code});
    return _billFrom(data);
  }

  /// Remove the applied voucher — DELETE /pos/bills/{id}/voucher.
  Future<Bill> removeVoucher(String billId) async {
    final data = await api.delete('/pos/bills/$billId/voucher');
    return _billFrom(data);
  }

  /// Request to VOID an unpaid bill — POST /pos/bills/{id}/void-request {reason}.
  /// Creates a request a Manager must approve (perm bill.void_request).
  Future<void> voidRequest(String billId, String reason) =>
      api.post('/pos/bills/$billId/void-request', body: {'reason': reason});

  /// Request to REFUND a paid bill — POST /pos/bills/{id}/refund-request
  /// {amount, reason}. Creates a request a Manager must approve.
  Future<void> refundRequest(String billId, {required int amount, required String reason}) =>
      api.post('/pos/bills/$billId/refund-request', body: {'amount': amount, 'reason': reason});

  /// Full bill (with line items) — GET /pos/bills/{id}. Used for receipts.
  Future<Bill> getBill(String billId) async {
    final data = await api.get('/pos/bills/$billId');
    return Bill.fromJson(Map<String, dynamic>.from(data as Map));
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
