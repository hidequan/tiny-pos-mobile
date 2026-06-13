import 'dart:async';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/kds_repository.dart';
import '../models/kds.dart';

/// Loads + polls the bar queue (online "real-time" via a short poll) and runs
/// item/ticket transitions.
class KdsController extends ChangeNotifier {
  final KdsRepository repo;
  KdsController(this.repo);

  List<KdsTicket> tickets = [];
  KdsStats stats = KdsStats(0, 0, 0);
  bool loading = false;
  bool loaded = false;
  String? error;
  Timer? _poll;
  final Set<String> _busyItems = {};

  // Completed (SERVED) tickets for the "Đã hoàn thành" tab — loaded on demand.
  List<KdsTicket> served = [];
  bool servedLoading = false;
  String? servedError;

  bool itemBusy(String id) => _busyItems.contains(id);

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final t = await repo.tickets();
      final s = await repo.stats();
      tickets = t;
      stats = s;
      loaded = true;
      error = null;
    } on ApiException catch (e) {
      if (!silent) error = e.message;
    } catch (_) {
      if (!silent) error = 'Không tải được hàng chờ';
    }
    loading = false;
    notifyListeners();
  }

  /// Poll every few seconds while the KDS screen is open (cheap online sync).
  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => load(silent: true));
  }

  void stopPolling() => _poll?.cancel();

  /// Mark an item made (READY). One-way; refreshes from the server.
  Future<void> markItemDone(String itemId) async {
    if (_busyItems.contains(itemId)) return;
    _busyItems.add(itemId);
    notifyListeners();
    try {
      await repo.readyItem(itemId);
    } catch (_) {/* surfaced on next poll */}
    _busyItems.remove(itemId);
    await load(silent: true);
  }

  /// Begin preparing a whole ticket (WAITING → PREPARING).
  Future<void> startTicket(String ticketId) async {
    try {
      await repo.startTicket(ticketId);
    } catch (_) {/* surfaced on next poll */}
    await load(silent: true);
  }

  Future<void> bumpTicket(String ticketId) async {
    try {
      await repo.completeTicket(ticketId);
    } catch (_) {}
    await load(silent: true);
  }

  /// Load today's completed (SERVED) tickets for the Done tab.
  Future<void> loadServed() async {
    servedLoading = true;
    servedError = null;
    notifyListeners();
    try {
      served = await repo.tickets(status: 'SERVED');
    } on ApiException catch (e) {
      servedError = e.message;
    } catch (_) {
      servedError = 'Không tải được đơn đã hoàn thành';
    }
    servedLoading = false;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetData(List<KdsTicket> t, KdsStats s) {
    tickets = t;
    stats = s;
    loaded = true;
    loading = false;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
