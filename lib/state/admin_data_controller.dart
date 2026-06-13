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

  final Set<String> _productBusy = {};
  bool productBusy(String id) => _productBusy.contains(id);

  int get lowStockCount => balances.where((b) => b.low).length;

  // Audit log.
  List<AuditRow> auditRows = [];
  bool auditLoading = false;
  bool auditLoaded = false;
  String? auditError;

  // Sync monitor.
  List<SyncDevice> syncDevices = [];
  List<SyncConflict> syncConflicts = [];
  bool syncLoading = false;
  bool syncLoaded = false;
  String? syncError;
  final Set<String> _conflictBusy = {};
  bool conflictBusy(String id) => _conflictBusy.contains(id);

  // Hardware (devices + print routes + cash drawer events).
  List<HwDevice> devices = [];
  List<PrintRoute> printRoutes = [];
  List<DrawerEvent> drawerEvents = [];
  bool hwLoading = false;
  bool hwLoaded = false;
  String? hwError;
  final Set<String> _hwBusy = {};
  bool hwBusy(String id) => _hwBusy.contains(id);

  // Branches.
  List<Branch> branches = [];
  bool branchesLoading = false;
  bool branchesLoaded = false;
  String? branchesError;

  // Admin shifts (đối soát ca).
  List<AdminShift> adminShifts = [];
  bool adminShiftsLoading = false;
  bool adminShiftsLoaded = false;
  String? adminShiftsError;
  final Set<String> _shiftBusy = {};
  bool shiftBusy(String id) => _shiftBusy.contains(id);
  String _shiftFrom = '';
  String _shiftTo = '';

  // Menu config (categories / sizes / toppings).
  List<AdminCategory> categories = [];
  List<AdminSize> sizes = [];
  List<AdminTopping> toppings = [];
  bool catalogLoading = false;
  bool catalogLoaded = false;
  String? catalogError;

  // Admin bills (xem mọi hoá đơn).
  List<AdminBill> bills = [];
  AdminBillSummary billsSummary = AdminBillSummary.empty();
  bool billsLoading = false;
  bool billsLoaded = false;
  bool billsLoadingMore = false;
  String? billsError;
  int _billsPage = 1;
  int _billsTotal = 0;
  String billStatusFilter = '';
  String billServiceFilter = '';
  String billSearch = '';
  bool get billsHasMore => bills.length < _billsTotal;

  // Cash movements (sổ quỹ ca).
  List<CashMovement> cashMovements = [];
  bool cmLoading = false;
  bool cmLoaded = false;
  String? cmError;
  final Set<String> _cmBusy = {};
  bool cmBusy(String id) => _cmBusy.contains(id);
  List<CashMovement> get cmPending => cashMovements.where((m) => m.isPending).toList();

  // Floor areas + tables (admin config).
  List<FloorArea> areas = [];
  bool areasLoading = false;
  bool areasLoaded = false;
  String? areasError;
  String? selectedAreaId;
  List<AdminTable> areaTables = [];
  bool tablesLoading = false;
  String? tablesError;

  // Vouchers.
  List<Voucher> vouchers = [];
  bool vouchersLoading = false;
  bool vouchersLoaded = false;
  String? vouchersError;

  // Void/refund approval queue.
  List<VoidRefundRequest> vrRequests = [];
  bool vrLoading = false;
  bool vrLoaded = false;
  String? vrError;
  final Set<String> _vrBusy = {};
  bool vrBusy(String id) => _vrBusy.contains(id);
  int get vrPendingCount => vrRequests.where((r) => r.isPending).length;

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

  // ---- product writes (returns an error message, or null on success) ------

  Future<String?> toggleProductStatus(String id, bool active) async {
    if (_productBusy.contains(id)) return null;
    _productBusy.add(id);
    notifyListeners();
    String? err;
    try {
      await repo.setProductStatus(id, active);
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = 'Không cập nhật được trạng thái';
    }
    _productBusy.remove(id);
    notifyListeners();
    return err;
  }

  Future<String?> createProduct({
    required String categoryId,
    required String name,
    required int basePrice,
    bool active = true,
  }) async {
    try {
      await repo.createProduct(categoryId: categoryId, name: name, basePrice: basePrice, active: active);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không tạo được sản phẩm';
    }
  }

  Future<String?> updateProduct(String id, {String? name, String? categoryId, int? basePrice, bool? active}) async {
    try {
      await repo.updateProduct(id, name: name, categoryId: categoryId, basePrice: basePrice, active: active);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không lưu được sản phẩm';
    }
  }

  // ---- staff + inventory writes (return error message, or null on success) --

  Future<String?> createStaff({
    required String username,
    required String password,
    required String fullName,
    required String staffRole,
    String? branchId,
  }) async {
    try {
      await repo.createStaff(
          username: username, password: password, fullName: fullName, staffRole: staffRole, branchId: branchId);
      await loadStaff();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không tạo được nhân viên';
    }
  }

  Future<String?> deactivateStaff(String id) async {
    try {
      await repo.deactivateStaff(id);
      await loadStaff();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không khoá được tài khoản';
    }
  }

  Future<String?> reactivateStaff(String id) async {
    try {
      await repo.reactivateStaff(id);
      await loadStaff();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không mở khoá được tài khoản';
    }
  }

  Future<String?> stockIn({
    required String branchId,
    required String ingredientId,
    required num quantity,
    String? reason,
  }) async {
    try {
      await repo.stockIn(branchId: branchId, ingredientId: ingredientId, quantity: quantity, reason: reason);
      await loadInventory();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không nhập kho được';
    }
  }

  Future<String?> adjustStock({
    required String branchId,
    required String ingredientId,
    required num quantity,
    required String reason,
  }) async {
    try {
      await repo.adjustStock(branchId: branchId, ingredientId: ingredientId, quantity: quantity, reason: reason);
      await loadInventory();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không điều chỉnh được';
    }
  }

  // ---- audit log -----------------------------------------------------------
  Future<void> loadAudit() async {
    auditLoading = true;
    auditError = null;
    notifyListeners();
    try {
      auditRows = await repo.auditLogs();
      auditLoaded = true;
    } on ApiException catch (e) {
      auditError = e.message;
    } catch (_) {
      auditError = 'Không tải được nhật ký';
    }
    auditLoading = false;
    notifyListeners();
  }

  void ensureAudit() {
    if (!auditLoaded && !auditLoading) loadAudit();
  }

  // ---- sync monitor --------------------------------------------------------
  Future<void> loadSync() async {
    syncLoading = true;
    syncError = null;
    notifyListeners();
    try {
      syncDevices = await repo.syncDevices();
      syncConflicts = await repo.syncConflicts();
      syncLoaded = true;
    } on ApiException catch (e) {
      syncError = e.message;
    } catch (_) {
      syncError = 'Không tải được đồng bộ';
    }
    syncLoading = false;
    notifyListeners();
  }

  void ensureSync() {
    if (!syncLoaded && !syncLoading) loadSync();
  }

  Future<String?> resolveConflict(String id, String resolution) async {
    if (_conflictBusy.contains(id)) return null;
    _conflictBusy.add(id);
    notifyListeners();
    String? err;
    try {
      await repo.resolveConflict(id, resolution);
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = 'Không xử lý được conflict';
    }
    _conflictBusy.remove(id);
    await loadSync();
    return err;
  }

  // ---- hardware ------------------------------------------------------------
  Future<void> loadHardware(String branchId) async {
    hwLoading = true;
    hwError = null;
    notifyListeners();
    try {
      devices = await repo.hwDevices(branchId);
      printRoutes = await repo.printRoutes(branchId);
      drawerEvents = await repo.drawerEvents(branchId);
      hwLoaded = true;
    } on ApiException catch (e) {
      hwError = e.message;
    } catch (_) {
      hwError = 'Không tải được thiết bị';
    }
    hwLoading = false;
    notifyListeners();
  }

  void ensureHardware(String branchId) {
    if (!hwLoaded && !hwLoading) loadHardware(branchId);
  }

  Future<String?> _hwOp(String branchId, Future<void> Function() run, String fb) async {
    try {
      await run();
      await loadHardware(branchId);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return fb;
    }
  }

  Future<String?> saveDevice(
    String branchId, {
    String? id,
    required String name,
    required String type,
    required String connectionType,
    String? address,
    String? printerName,
    bool? isActive,
  }) =>
      _hwOp(
          branchId,
          () => id == null
              ? repo.createDevice(branchId: branchId, name: name, type: type, connectionType: connectionType, address: address, printerName: printerName)
              : repo.updateDevice(id, name: name, type: type, connectionType: connectionType, address: address, printerName: printerName, isActive: isActive),
          'Không lưu được thiết bị');

  Future<String?> removeDevice(String branchId, String id) =>
      _hwOp(branchId, () => repo.deleteDevice(id), 'Không xoá được thiết bị');

  Future<String?> createRoute(String branchId, {required String jobType, required String hardwareId}) =>
      _hwOp(branchId, () => repo.createRoute(branchId: branchId, jobType: jobType, hardwareId: hardwareId), 'Không thêm được route');

  Future<String?> removeRoute(String branchId, String id) =>
      _hwOp(branchId, () => repo.deleteRoute(id), 'Không xoá được route');

  /// Returns a human message for the toast (and refreshes nothing — read-only).
  Future<({bool ok, String message})> testPrint(String id) async {
    if (_hwBusy.contains(id)) return (ok: false, message: '');
    _hwBusy.add(id);
    notifyListeners();
    ({bool ok, String message}) result;
    try {
      final r = await repo.testPrint(id);
      result = r.ok
          ? (ok: true, message: '✓ Đã gửi lệnh in thử tới máy in')
          : (ok: false, message: 'Máy in chưa phản hồi (${r.error ?? r.status}). Kiểm tra POS Agent đang chạy & đúng tên máy in.');
    } on ApiException catch (e) {
      result = (ok: false, message: e.message);
    } catch (_) {
      result = (ok: false, message: 'Lỗi in thử');
    }
    _hwBusy.remove(id);
    notifyListeners();
    return result;
  }

  // ---- branches ------------------------------------------------------------
  Future<void> loadBranches() async {
    branchesLoading = true;
    branchesError = null;
    notifyListeners();
    try {
      branches = await repo.branches();
      branchesLoaded = true;
    } on ApiException catch (e) {
      branchesError = e.message;
    } catch (_) {
      branchesError = 'Không tải được chi nhánh';
    }
    branchesLoading = false;
    notifyListeners();
  }

  void ensureBranches() {
    if (!branchesLoaded && !branchesLoading) loadBranches();
  }

  Future<String?> updateBranch(
    String id, {
    String? name,
    String? address,
    String? phone,
    int? cashOutLimit,
    int? cashDiffThreshold,
  }) async {
    try {
      await repo.updateBranch(id,
          name: name, address: address, phone: phone,
          cashOutLimit: cashOutLimit, cashDiffThreshold: cashDiffThreshold);
      await loadBranches();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không lưu được chi nhánh';
    }
  }

  // ---- admin shifts --------------------------------------------------------
  Future<void> loadAdminShifts({required String from, required String to}) async {
    _shiftFrom = from;
    _shiftTo = to;
    adminShiftsLoading = true;
    adminShiftsError = null;
    notifyListeners();
    try {
      adminShifts = await repo.shiftSummary(from: from, to: to);
      adminShiftsLoaded = true;
    } on ApiException catch (e) {
      adminShiftsError = e.message;
    } catch (_) {
      adminShiftsError = 'Không tải được danh sách ca';
    }
    adminShiftsLoading = false;
    notifyListeners();
  }

  Future<String?> confirmShift(String id) async {
    if (_shiftBusy.contains(id)) return null;
    _shiftBusy.add(id);
    notifyListeners();
    String? err;
    try {
      await repo.confirmShift(id);
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = 'Không xác nhận được ca';
    }
    _shiftBusy.remove(id);
    if (_shiftFrom.isNotEmpty) await loadAdminShifts(from: _shiftFrom, to: _shiftTo);
    return err;
  }

  // ---- menu config ---------------------------------------------------------
  Future<void> loadCatalog(String branchId) async {
    catalogLoading = true;
    catalogError = null;
    notifyListeners();
    try {
      categories = await repo.categoriesAdmin(branchId);
      sizes = await repo.sizesAdmin();
      toppings = await repo.toppingsAdmin(branchId);
      catalogLoaded = true;
    } on ApiException catch (e) {
      catalogError = e.message;
    } catch (_) {
      catalogError = 'Không tải được cấu hình menu';
    }
    catalogLoading = false;
    notifyListeners();
  }

  void ensureCatalog(String branchId) {
    if (!catalogLoaded && !catalogLoading) loadCatalog(branchId);
  }

  Future<String?> _catalogOp(String branchId, Future<void> Function() run, String fb) async {
    try {
      await run();
      await loadCatalog(branchId);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return fb;
    }
  }

  Future<String?> saveCategory(String branchId, {String? id, required String name}) => _catalogOp(
      branchId,
      () => id == null ? repo.createCategory(branchId, name) : repo.updateCategory(id, name),
      'Không lưu được danh mục');
  Future<String?> removeCategory(String branchId, String id) =>
      _catalogOp(branchId, () => repo.deleteCategory(id), 'Không xoá được danh mục');

  Future<String?> saveSize(String branchId, {String? id, required String code, required String name}) => _catalogOp(
      branchId,
      () => id == null ? repo.createSize(code, name) : repo.updateSize(id, code, name),
      'Không lưu được size');
  Future<String?> removeSize(String branchId, String id) =>
      _catalogOp(branchId, () => repo.deleteSize(id), 'Không xoá được size');

  Future<String?> saveTopping(String branchId, {String? id, required String name, required int price}) => _catalogOp(
      branchId,
      () => id == null ? repo.createTopping(name, price) : repo.updateTopping(id, name, price),
      'Không lưu được topping');
  Future<String?> removeTopping(String branchId, String id) =>
      _catalogOp(branchId, () => repo.deleteTopping(id), 'Không xoá được topping');

  // ---- admin bills ---------------------------------------------------------
  Future<void> loadBills({bool reset = true}) async {
    if (reset) {
      _billsPage = 1;
      billsLoading = true;
      billsError = null;
    } else {
      if (billsLoadingMore || !billsHasMore) return;
      billsLoadingMore = true;
      _billsPage += 1;
    }
    notifyListeners();
    try {
      final res = await repo.adminBills(
        status: billStatusFilter,
        serviceType: billServiceFilter,
        q: billSearch,
        page: _billsPage,
      );
      if (reset) {
        bills = res.items;
      } else {
        bills = [...bills, ...res.items];
      }
      billsSummary = res.summary;
      _billsTotal = res.total;
      billsLoaded = true;
      billsError = null;
    } on ApiException catch (e) {
      billsError = e.message;
      if (!reset) _billsPage -= 1;
    } catch (_) {
      billsError = 'Không tải được hoá đơn';
      if (!reset) _billsPage -= 1;
    }
    billsLoading = false;
    billsLoadingMore = false;
    notifyListeners();
  }

  void ensureBills() {
    if (!billsLoaded && !billsLoading) loadBills();
  }

  void setBillStatusFilter(String s) {
    if (billStatusFilter == s) return;
    billStatusFilter = s;
    loadBills();
  }

  void setBillServiceFilter(String s) {
    if (billServiceFilter == s) return;
    billServiceFilter = s;
    loadBills();
  }

  void setBillSearch(String s) {
    billSearch = s;
    loadBills();
  }

  // ---- cash movements ------------------------------------------------------
  Future<void> loadCashMovements() async {
    cmLoading = true;
    cmError = null;
    notifyListeners();
    try {
      cashMovements = await repo.cashMovements();
      cmLoaded = true;
    } on ApiException catch (e) {
      cmError = e.message;
    } catch (_) {
      cmError = 'Không tải được sổ quỹ';
    }
    cmLoading = false;
    notifyListeners();
  }

  void ensureCashMovements() {
    if (!cmLoaded && !cmLoading) loadCashMovements();
  }

  Future<String?> decideCashMovement(String id, {required bool approve}) async {
    if (_cmBusy.contains(id)) return null;
    _cmBusy.add(id);
    notifyListeners();
    String? err;
    try {
      if (approve) {
        await repo.approveCashMovement(id);
      } else {
        await repo.rejectCashMovement(id);
      }
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = approve ? 'Không duyệt được' : 'Không từ chối được';
    }
    _cmBusy.remove(id);
    await loadCashMovements();
    return err;
  }

  // ---- floor areas + tables ------------------------------------------------
  Future<void> loadAreas(String branchId, {bool keepSelection = false}) async {
    areasLoading = true;
    areasError = null;
    notifyListeners();
    try {
      areas = await repo.floorAreas(branchId);
      areasLoaded = true;
      // Auto-select the first area (or keep current if still present).
      if (!keepSelection || !areas.any((a) => a.id == selectedAreaId)) {
        selectedAreaId = areas.isNotEmpty ? areas.first.id : null;
        if (selectedAreaId != null) {
          await _loadTables(selectedAreaId!);
        } else {
          areaTables = [];
        }
      }
    } on ApiException catch (e) {
      areasError = e.message;
    } catch (_) {
      areasError = 'Không tải được khu vực';
    }
    areasLoading = false;
    notifyListeners();
  }

  Future<void> selectArea(String areaId) async {
    selectedAreaId = areaId;
    notifyListeners();
    await _loadTables(areaId);
  }

  Future<void> _loadTables(String areaId) async {
    tablesLoading = true;
    tablesError = null;
    notifyListeners();
    try {
      areaTables = await repo.areaTables(areaId);
    } on ApiException catch (e) {
      tablesError = e.message;
    } catch (_) {
      tablesError = 'Không tải được bàn';
    }
    tablesLoading = false;
    notifyListeners();
  }

  Future<String?> _areaOp(String branchId, Future<void> Function() run, String fb) async {
    try {
      await run();
      await loadAreas(branchId, keepSelection: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return fb;
    }
  }

  Future<String?> createArea(String branchId, {required String name, int level = 1}) =>
      _areaOp(branchId, () => repo.createFloorArea(branchId, name: name, level: level), 'Không tạo được khu vực');
  Future<String?> updateArea(String branchId, String id, {String? name, int? level}) =>
      _areaOp(branchId, () => repo.updateFloorArea(id, name: name, level: level), 'Không sửa được khu vực');
  Future<String?> deleteArea(String branchId, String id) =>
      _areaOp(branchId, () => repo.deleteFloorArea(id), 'Không xoá được khu vực');

  Future<String?> _tableOp(Future<void> Function() run, String fb) async {
    final area = selectedAreaId;
    try {
      await run();
      if (area != null) await _loadTables(area);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return fb;
    }
  }

  Future<String?> createTable({required String code, String? name, int seats = 2}) =>
      _tableOp(() => repo.createTable(selectedAreaId!, code: code, name: name, seats: seats), 'Không tạo được bàn');
  Future<String?> updateTable(String id, {String? code, String? name, int? seats, String? status}) =>
      _tableOp(() => repo.updateTable(id, code: code, name: name, seats: seats, status: status), 'Không sửa được bàn');
  Future<String?> deleteTable(String id) =>
      _tableOp(() => repo.deleteTable(id), 'Không xoá được bàn');

  // ---- vouchers ------------------------------------------------------------
  Future<void> loadVouchers() async {
    vouchersLoading = true;
    vouchersError = null;
    notifyListeners();
    try {
      vouchers = await repo.vouchers();
      vouchersLoaded = true;
    } on ApiException catch (e) {
      vouchersError = e.message;
    } catch (_) {
      vouchersError = 'Không tải được voucher';
    }
    vouchersLoading = false;
    notifyListeners();
  }

  void ensureVouchers() {
    if (!vouchersLoaded && !vouchersLoading) loadVouchers();
  }

  Future<String?> createVoucher({
    required String code,
    required String name,
    required String discountType,
    required int discountValue,
    int minOrderAmount = 0,
    int? maxDiscount,
    int? usageLimit,
    String? startsAt,
    String? endsAt,
  }) async {
    try {
      await repo.createVoucher(
        code: code, name: name, discountType: discountType, discountValue: discountValue,
        minOrderAmount: minOrderAmount, maxDiscount: maxDiscount, usageLimit: usageLimit,
        startsAt: startsAt, endsAt: endsAt,
      );
      await loadVouchers();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không tạo được voucher';
    }
  }

  Future<String?> updateVoucher(
    String id, {
    String? name,
    int? discountValue,
    int? minOrderAmount,
    int? maxDiscount,
    int? usageLimit,
    String? status,
    String? startsAt,
    String? endsAt,
  }) async {
    try {
      await repo.updateVoucher(id,
          name: name, discountValue: discountValue, minOrderAmount: minOrderAmount,
          maxDiscount: maxDiscount, usageLimit: usageLimit, status: status,
          startsAt: startsAt, endsAt: endsAt);
      await loadVouchers();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không lưu được voucher';
    }
  }

  Future<String?> deleteVoucher(String id) async {
    try {
      await repo.deleteVoucher(id);
      await loadVouchers();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không xoá được voucher';
    }
  }

  // ---- void/refund approval ------------------------------------------------
  Future<void> loadVoidRefund() async {
    vrLoading = true;
    vrError = null;
    notifyListeners();
    try {
      vrRequests = await repo.voidRefundRequests();
      vrLoaded = true;
    } on ApiException catch (e) {
      vrError = e.message;
    } catch (_) {
      vrError = 'Không tải được yêu cầu huỷ/hoàn';
    }
    vrLoading = false;
    notifyListeners();
  }

  Future<String?> decideVoidRefund(String id, {required bool approve, String? reason}) async {
    if (_vrBusy.contains(id)) return null;
    _vrBusy.add(id);
    notifyListeners();
    String? err;
    try {
      if (approve) {
        await repo.approveVoidRefund(id);
      } else {
        await repo.rejectVoidRefund(id, reason: reason);
      }
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = approve ? 'Không duyệt được' : 'Không từ chối được';
    }
    _vrBusy.remove(id);
    await loadVoidRefund();
    return err;
  }

  void ensureVoidRefund() {
    if (!vrLoaded && !vrLoading) loadVoidRefund();
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
