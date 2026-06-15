import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/bill_repository.dart';
import '../models/bill.dart';

/// Loads the branch's bills (GET /pos/bills) for the cashier's Orders screen.
class BillsController extends ChangeNotifier {
  final BillRepository repo;
  BillsController(this.repo);

  List<Bill> bills = [];
  bool loading = false;
  bool loaded = false;
  bool loadingMore = false;
  String? error;
  int _page = 1;
  int _total = 0;
  static const int _pageSize = 20;
  bool get hasMore => bills.length < _total;

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (loaded && !force) return;
    _page = 1;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final r = await repo.listBillsPaged(page: 1, limit: _pageSize);
      bills = r.items;
      _total = r.total;
      loaded = true;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Không tải được danh sách đơn';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (loadingMore || loading || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      final r = await repo.listBillsPaged(page: _page + 1, limit: _pageSize);
      bills = [...bills, ...r.items];
      _total = r.total;
      _page += 1;
    } catch (_) {/* keep what we have */}
    loadingMore = false;
    notifyListeners();
  }

  int get paidRevenue => bills.where((b) => b.isPaid).fold(0, (a, b) => a + b.grandTotal);
  int get paidCount => bills.where((b) => b.isPaid).length;

  @visibleForTesting
  void debugSetBills(List<Bill> b) {
    bills = b;
    loaded = true;
    loading = false;
    error = null;
    notifyListeners();
  }
}
