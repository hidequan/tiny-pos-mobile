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

  Future<void> bumpTicket(String ticketId) async {
    try {
      await repo.completeTicket(ticketId);
    } catch (_) {}
    await load(silent: true);
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
