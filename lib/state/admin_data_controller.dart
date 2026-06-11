import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/admin_repository.dart';
import '../models/admin.dart';

/// Loads admin master data (staff + inventory + BOM). Each section loads
/// independently and caches; screens call the matching ensure* on first open.
class AdminDataController extends ChangeNotifier {
  final AdminRepository repo;
  AdminDataController(this.repo);

  List<StaffMember> staff = [];
  bool staffLoaded = false;
  bool staffLoading = false;
  String? staffError;

  List<StockBalance> balances = [];
  List<BomRecipe> boms = [];
  bool invLoaded = false;
  bool invLoading = false;
  String? invError;

  int get lowStockCount => balances.where((b) => b.low).length;

  Future<void> loadStaff() async {
    staffLoading = true;
    staffError = null;
    notifyListeners();
    try {
      staff = await repo.users();
      staffLoaded = true;
    } on ApiException catch (e) {
      staffError = e.message;
    } catch (_) {
      staffError = 'Không tải được nhân viên';
    }
    staffLoading = false;
    notifyListeners();
  }

  Future<void> loadInventory() async {
    invLoading = true;
    invError = null;
    notifyListeners();
    try {
      balances = await repo.inventoryBalances();
      boms = await repo.bomRecipes();
      invLoaded = true;
    } on ApiException catch (e) {
      invError = e.message;
    } catch (_) {
      invError = 'Không tải được kho';
    }
    invLoading = false;
    notifyListeners();
  }

  void ensureStaff() {
    if (!staffLoaded && !staffLoading) loadStaff();
  }

  void ensureInventory() {
    if (!invLoaded && !invLoading) loadInventory();
  }

  @visibleForTesting
  void debugSet({List<StaffMember>? staff, List<StockBalance>? balances, List<BomRecipe>? boms}) {
    if (staff != null) {
      this.staff = staff;
      staffLoaded = true;
    }
    if (balances != null) {
      this.balances = balances;
      invLoaded = true;
    }
    if (boms != null) this.boms = boms;
    staffLoading = false;
    invLoading = false;
    staffError = null;
    invError = null;
    notifyListeners();
  }
}
