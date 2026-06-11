import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/shift_repository.dart';
import '../models/shift.dart';

/// Loads the cashier's current shift and runs open/close/cash-in/out.
class ShiftController extends ChangeNotifier {
  final ShiftRepository repo;
  ShiftController(this.repo);

  Shift? shift;
  bool loading = false;
  bool loaded = false;
  bool busy = false;
  String? error;

  bool get hasOpenShift => shift != null && shift!.isOpen;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      shift = await repo.current();
      loaded = true;
      error = null;
    } on ApiException catch (e) {
      if (!silent) error = e.message;
    } catch (_) {
      if (!silent) error = 'Không tải được ca làm việc';
    }
    loading = false;
    notifyListeners();
  }

  Future<String?> openShift({required int openingCash, String? branchId}) async {
    busy = true;
    notifyListeners();
    String? err;
    try {
      shift = await repo.open(openingCash: openingCash, branchId: branchId);
      await load(silent: true);
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = 'Không mở được ca';
    }
    busy = false;
    notifyListeners();
    return err;
  }

  Future<String?> cashMovement({required bool isIn, required int amount, String? reason}) async {
    final s = shift;
    if (s == null) return 'Chưa có ca mở';
    busy = true;
    notifyListeners();
    String? err;
    try {
      if (isIn) {
        await repo.cashIn(s.id, amount: amount, reason: reason);
      } else {
        await repo.cashOut(s.id, amount: amount, reason: reason);
      }
      await load(silent: true);
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = 'Không ghi nhận được';
    }
    busy = false;
    notifyListeners();
    return err;
  }

  /// Returns (error, closedShift). On success error is null and the closed
  /// shift (with difference) is returned for the summary screen.
  Future<(String?, Shift?)> closeShift({required Map<int, int> denominations, String? note}) async {
    final s = shift;
    if (s == null) return ('Chưa có ca mở', null);
    busy = true;
    notifyListeners();
    String? err;
    Shift? closed;
    try {
      closed = await repo.close(s.id, denominations: denominations, note: note);
      await load(silent: true);
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = 'Không đóng được ca';
    }
    busy = false;
    notifyListeners();
    return (err, closed);
  }

  @visibleForTesting
  void debugSetShift(Shift? s) {
    shift = s;
    loaded = true;
    loading = false;
    error = null;
    notifyListeners();
  }
}
