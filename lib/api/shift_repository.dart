import '../models/shift.dart';
import 'api_client.dart';

/// Cashier shift operations (/pos/shifts...). open/close/cash-in/out are WRITES
/// — only run write tests against a local/test backend.
class ShiftRepository {
  final ApiClient api;
  ShiftRepository(this.api);

  /// Current open shift for the signed-in cashier (with summary), or null.
  Future<Shift?> current() async {
    final data = await api.get('/pos/shifts/current');
    if (data == null) return null;
    return Shift.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Open a shift with the opening cash float — POST /pos/shifts/open.
  /// branchId is intentionally omitted; the server defaults to the cashier's
  /// own branch (sending it risks a stale/invalid value failing validation).
  Future<Shift> open({required int openingCash, String? branchId}) async {
    final data = await api.post('/pos/shifts/open', body: {'openingCash': openingCash});
    return Shift.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Record cash put into the drawer — POST /pos/shifts/:id/cash-in.
  Future<void> cashIn(String shiftId, {required int amount, String? reason}) =>
      api.post('/pos/shifts/$shiftId/cash-in', body: {'amount': amount, 'reason': ?reason});

  /// Record cash taken out of the drawer — POST /pos/shifts/:id/cash-out.
  Future<void> cashOut(String shiftId, {required int amount, String? reason}) =>
      api.post('/pos/shifts/$shiftId/cash-out', body: {'amount': amount, 'reason': ?reason});

  /// Close the shift with a counted-cash breakdown — POST /pos/shifts/:id/close.
  Future<Shift> close(String shiftId, {required Map<int, int> denominations, String? note}) async {
    final lines = [
      for (final e in denominations.entries)
        if (e.value > 0) {'denomination': e.key, 'count': e.value},
    ];
    final data = await api.post('/pos/shifts/$shiftId/close', body: {
      'denominations': lines,
      'note': ?note,
    });
    return Shift.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
