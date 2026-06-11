import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/table_repository.dart';
import '../models/bill.dart';
import '../models/table.dart';

/// Loads the floor map and runs dine-in session actions. Also tracks the
/// "active" table session so the cashier Sell flow can route new items into a
/// table's bill instead of creating a take-away order.
class TablesController extends ChangeNotifier {
  final TableRepository repo;
  TablesController(this.repo);

  List<TableArea> areas = [];
  bool loading = false;
  bool loaded = false;
  String? error;
  final Set<String> _busy = {}; // table/session ids with an in-flight write

  // Active dine-in session that the Sell screen is currently ordering into.
  String? activeSessionId;
  String? activeTableLabel;

  bool busy(String id) => _busy.contains(id);
  bool get hasActiveSession => activeSessionId != null;

  int get tableCount => areas.fold(0, (a, x) => a + x.tables.length);
  int get occupiedCount =>
      areas.fold(0, (a, x) => a + x.tables.where((t) => t.isOccupied).length);

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      areas = await repo.map();
      loaded = true;
      error = null;
    } on ApiException catch (e) {
      if (!silent) error = e.message;
    } catch (_) {
      if (!silent) error = 'Không tải được sơ đồ bàn';
    }
    loading = false;
    notifyListeners();
  }

  /// Open an empty table, set it active, reload the map. Returns the sessionId.
  Future<String?> openTable(CafeTable table, {int guestCount = 1}) async {
    if (_busy.contains(table.id)) return null;
    _busy.add(table.id);
    notifyListeners();
    String? sessionId;
    try {
      sessionId = await repo.openTable(table.id, guestCount: guestCount);
      setActive(sessionId, table.label);
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Không mở được bàn ${table.label}';
    }
    _busy.remove(table.id);
    await load(silent: true);
    return sessionId;
  }

  /// Mark a dirty table cleaned.
  Future<void> cleanTable(CafeTable table) async {
    if (_busy.contains(table.id)) return;
    _busy.add(table.id);
    notifyListeners();
    try {
      await repo.clean(table.id);
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {/* surfaced on reload */}
    _busy.remove(table.id);
    await load(silent: true);
  }

  /// Close a settled session.
  Future<String?> closeSession(String sessionId) async {
    if (_busy.contains(sessionId)) return 'Đang xử lý…';
    _busy.add(sessionId);
    notifyListeners();
    String? err;
    try {
      await repo.close(sessionId);
      if (activeSessionId == sessionId) clearActive();
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = 'Không đóng được bàn';
    }
    _busy.remove(sessionId);
    await load(silent: true);
    return err;
  }

  /// Add cart items into a session's bill (dine-in ordering).
  Future<void> addItems(String sessionId, List<BillItemInput> items) async {
    await repo.addItems(sessionId, items);
    await load(silent: true);
  }

  Future<TableSessionDetail> sessionDetail(String sessionId) =>
      repo.sessionDetail(sessionId);

  void setActive(String sessionId, String tableLabel) {
    activeSessionId = sessionId;
    activeTableLabel = tableLabel;
    notifyListeners();
  }

  void clearActive() {
    activeSessionId = null;
    activeTableLabel = null;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetAreas(List<TableArea> a) {
    areas = a;
    loaded = true;
    loading = false;
    error = null;
    notifyListeners();
  }
}
