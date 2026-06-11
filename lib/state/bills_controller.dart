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
  String? error;

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (loaded && !force) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      bills = await repo.listBills();
      loaded = true;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Không tải được danh sách đơn';
    }
    loading = false;
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
