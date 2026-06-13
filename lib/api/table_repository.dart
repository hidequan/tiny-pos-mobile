import '../models/bill.dart';
import '../models/table.dart';
import 'api_client.dart';

/// POS dine-in table operations against the shared backend (/pos/table-...).
/// [map]/[sessionDetail] are reads; the rest are WRITES — only run write tests
/// against a local/test backend, never the production branch.
class TableRepository {
  final ApiClient api;
  TableRepository(this.api);

  /// Floor map: areas + tables (+ active session summary) — GET /pos/table-map.
  Future<List<TableArea>> map() async {
    final data = await api.get('/pos/table-map');
    final list = data is List ? data : ((data as Map)['areas'] ?? const []) as List;
    return list.map((e) => TableArea.fromJson(e as Map)).toList();
  }

  /// Full session detail — GET /pos/table-sessions/:id.
  Future<TableSessionDetail> sessionDetail(String sessionId) async {
    final data = await api.get('/pos/table-sessions/$sessionId');
    return TableSessionDetail.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Open an empty table (creates a session + dine-in bill) — returns sessionId.
  Future<String> openTable(String tableId, {int guestCount = 1}) async {
    final data = await api.post('/pos/tables/$tableId/open', body: {'guestCount': guestCount});
    final m = Map<String, dynamic>.from(data as Map);
    final session = m['session'] is Map ? Map<String, dynamic>.from(m['session'] as Map) : m;
    return session['id'] as String;
  }

  /// Add items to a session's primary (or given) bill — POST add-items.
  Future<void> addItems(String sessionId, List<BillItemInput> items, {String? billId}) async {
    await api.post('/pos/table-sessions/$sessionId/add-items', body: {
      'billId': ?billId,
      'items': items.map((e) => e.toJson()).toList(),
    });
  }

  /// Move a session to an empty table — POST transfer {toTableId}.
  Future<void> transfer(String sessionId, String toTableId) =>
      api.post('/pos/table-sessions/$sessionId/transfer', body: {'toTableId': toTableId});

  /// Merge another open session INTO this one — POST merge {sourceSessionId,
  /// mergeBills}. When [mergeBills] is true the unpaid bills are also merged.
  Future<void> mergeTable(String sessionId, String sourceSessionId, {bool mergeBills = false}) =>
      api.post('/pos/table-sessions/$sessionId/merge',
          body: {'sourceSessionId': sourceSessionId, 'mergeBills': mergeBills});

  /// Merge ≥2 unpaid bills in a session into one — POST merge-bills {billIds}.
  Future<void> mergeBills(String sessionId, List<String> billIds) =>
      api.post('/pos/table-sessions/$sessionId/merge-bills', body: {'billIds': billIds});

  /// Split selected items/quantities off a bill into a new bill — POST
  /// split-bill {billId, items:[{billItemId, quantity}]}.
  Future<void> splitBill(String sessionId, String billId, List<Map<String, dynamic>> items) =>
      api.post('/pos/table-sessions/$sessionId/split-bill', body: {'billId': billId, 'items': items});

  /// Close a session (all bills must be settled) — POST close.
  Future<void> close(String sessionId) => api.post('/pos/table-sessions/$sessionId/close');

  /// Mark a dirty table as cleaned (DIRTY → EMPTY) — POST clean.
  Future<void> clean(String tableId) => api.post('/pos/tables/$tableId/clean');
}
