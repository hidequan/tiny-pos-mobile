import '../models/admin.dart';
import '../models/bill.dart';
import 'api_client.dart';

/// Admin master-data reads (/admin/users, /admin/inventory, /admin/bom-recipes).
/// All READS — safe against any backend. Writes will be added later.
class AdminRepository {
  final ApiClient api;
  AdminRepository(this.api);

  Future<List<StaffMember>> users() async {
    final data = await api.get('/admin/users');
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => StaffMember.fromJson(e as Map)).toList();
  }

  Future<List<StockBalance>> inventoryBalances() async {
    final data = await api.get('/admin/inventory/balances');
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => StockBalance.fromJson(e as Map)).toList();
  }

  Future<List<BomRecipe>> bomRecipes() async {
    final data = await api.get('/admin/bom-recipes');
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => BomRecipe.fromJson(e as Map)).toList();
  }

  // ---- audit log (MANAGER+, audit.view) -----------------------------------
  Future<List<AuditRow>> auditLogs() async {
    final data = await api.get('/admin/audit-logs');
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => AuditRow.fromJson(e as Map)).toList();
  }

  // ---- sync monitor (MANAGER+, sync.view / sync.resolve) ------------------
  Future<List<SyncDevice>> syncDevices() async {
    final data = await api.get('/admin/sync/devices');
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => SyncDevice.fromJson(e as Map)).toList();
  }

  Future<List<SyncConflict>> syncConflicts() async {
    final data = await api.get('/admin/sync/conflicts');
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => SyncConflict.fromJson(e as Map)).toList();
  }

  Future<void> resolveConflict(String id, String resolution) =>
      api.post('/sync/conflicts/$id/resolve', body: {'resolution': resolution});

  // ---- hardware (MANAGER+, hardware.manage) -------------------------------
  Future<List<HwDevice>> hwDevices(String branchId) async {
    final data = await api.get('/admin/hardware-devices', query: {'branchId': branchId});
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => HwDevice.fromJson(e as Map)).toList();
  }

  Future<void> createDevice({
    required String branchId,
    required String name,
    required String type,
    required String connectionType,
    String? address,
    String? printerName,
  }) {
    final printer = type == 'BILL_PRINTER' || type == 'STICKER_PRINTER';
    return api.post('/admin/hardware-devices', body: {
      'branchId': branchId,
      'name': name,
      'type': type,
      'connectionType': connectionType,
      if (!printer && address != null && address.isNotEmpty) 'address': address,
      if (printer && printerName != null && printerName.isNotEmpty) 'config': {'printerName': printerName},
    });
  }

  Future<void> updateDevice(
    String id, {
    String? name,
    String? type,
    String? connectionType,
    String? address,
    String? printerName,
    bool? isActive,
  }) {
    final printer = type == 'BILL_PRINTER' || type == 'STICKER_PRINTER';
    return api.patch('/admin/hardware-devices/$id', body: {
      'name': ?name,
      'type': ?type,
      'connectionType': ?connectionType,
      if (!printer && address != null) 'address': address,
      if (printer) 'config': {'printerName': printerName ?? ''},
      'isActive': ?isActive,
    });
  }

  Future<void> deleteDevice(String id) => api.delete('/admin/hardware-devices/$id');

  /// Send a test print — returns {ok, status, error}.
  Future<({bool ok, String status, String? error})> testPrint(String id) async {
    final data = await api.post('/admin/hardware-devices/$id/test-print');
    final m = Map<String, dynamic>.from(data as Map);
    return (ok: (m['ok'] as bool?) ?? false, status: (m['status'] ?? '').toString(), error: m['error'] as String?);
  }

  Future<List<PrintRoute>> printRoutes(String branchId) async {
    final data = await api.get('/admin/print-routes', query: {'branchId': branchId});
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => PrintRoute.fromJson(e as Map)).toList();
  }

  Future<void> createRoute({required String branchId, required String jobType, required String hardwareId, bool isDefault = true}) =>
      api.post('/admin/print-routes', body: {'branchId': branchId, 'jobType': jobType, 'hardwareId': hardwareId, 'isDefault': isDefault});

  Future<void> deleteRoute(String id) => api.delete('/admin/print-routes/$id');

  Future<List<DrawerEvent>> drawerEvents(String branchId) async {
    final data = await api.get('/admin/cash-drawer-events', query: {'branchId': branchId});
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => DrawerEvent.fromJson(e as Map)).toList();
  }

  // ---- branches (MANAGER+, branch.manage) ---------------------------------
  Future<List<Branch>> branches() async {
    final data = await api.get('/admin/branches');
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => Branch.fromJson(e as Map)).toList();
  }

  Future<void> updateBranch(
    String id, {
    String? name,
    String? address,
    String? phone,
    int? cashOutLimit,
    int? cashDiffThreshold,
  }) =>
      api.patch('/admin/branches/$id', body: {
        'name': ?name,
        'address': ?address,
        'phone': ?phone,
        'cashOutLimit': ?cashOutLimit,
        'cashDiffThreshold': ?cashDiffThreshold,
      });

  // ---- admin shifts (MANAGER+, report.view / shift.confirm) ---------------
  Future<List<AdminShift>> shiftSummary({required String from, required String to}) async {
    final data = await api.get('/admin/reports/shift-summary', query: {'from': from, 'to': to});
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => AdminShift.fromJson(e as Map)).toList();
  }

  Future<void> confirmShift(String id) => api.post('/admin/shifts/$id/confirm');

  // ---- menu config: categories / sizes / toppings (MANAGER+) --------------
  Future<List<AdminCategory>> categoriesAdmin(String branchId) async {
    final data = await api.get('/admin/product-categories', query: {'branchId': branchId});
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => AdminCategory.fromJson(e as Map)).toList();
  }

  Future<void> createCategory(String branchId, String name) =>
      api.post('/admin/product-categories', body: {'name': name, 'branchId': branchId});
  Future<void> updateCategory(String id, String name) =>
      api.patch('/admin/product-categories/$id', body: {'name': name});
  Future<void> deleteCategory(String id) => api.delete('/admin/product-categories/$id');

  Future<List<AdminSize>> sizesAdmin() async {
    final data = await api.get('/admin/sizes');
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => AdminSize.fromJson(e as Map)).toList();
  }

  Future<void> createSize(String code, String name) =>
      api.post('/admin/sizes', body: {'code': code, 'name': name});
  Future<void> updateSize(String id, String code, String name) =>
      api.patch('/admin/sizes/$id', body: {'code': code, 'name': name});
  Future<void> deleteSize(String id) => api.delete('/admin/sizes/$id');

  Future<List<AdminTopping>> toppingsAdmin(String branchId) async {
    final data = await api.get('/admin/toppings', query: {'branchId': branchId});
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => AdminTopping.fromJson(e as Map)).toList();
  }

  Future<void> createTopping(String name, int price) =>
      api.post('/admin/toppings', body: {'name': name, 'price': price});
  Future<void> updateTopping(String id, String name, int price) =>
      api.patch('/admin/toppings/$id', body: {'name': name, 'price': price});
  Future<void> deleteTopping(String id) => api.delete('/admin/toppings/$id');

  // ---- admin bills (MANAGER+, report.view) --------------------------------
  /// Paged list of bills + summary — GET /admin/bills.
  Future<({List<AdminBill> items, AdminBillSummary summary, int total})> adminBills({
    String? status,
    String? serviceType,
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{'page': '$page', 'limit': '$limit'};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (serviceType != null && serviceType.isNotEmpty) query['serviceType'] = serviceType;
    if (q != null && q.isNotEmpty) query['q'] = q;
    final data = await api.get('/admin/bills', query: query);
    final m = Map<String, dynamic>.from(data as Map);
    final list = (m['items'] ?? const []) as List;
    final pg = (m['pagination'] as Map?) ?? const {};
    final total = (pg['total'] ?? m['total'] as num?) as num?;
    return (
      items: list.map((e) => AdminBill.fromJson(e as Map)).toList(),
      summary: m['summary'] is Map ? AdminBillSummary.fromJson(m['summary'] as Map) : AdminBillSummary.empty(),
      total: total?.toInt() ?? list.length,
    );
  }

  /// Full bill (items + toppings) — GET /admin/bills/:id (reuses the Bill model).
  Future<Bill> adminBillDetail(String id) async {
    final data = await api.get('/admin/bills/$id');
    return Bill.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ---- cash movements (MANAGER+, report.view / cashout.approve) -----------
  Future<List<CashMovement>> cashMovements({String? status, String? type}) async {
    final q = <String, dynamic>{};
    if (status != null) q['status'] = status;
    if (type != null) q['type'] = type;
    final data = await api.get('/admin/cash-movements', query: q.isEmpty ? null : q);
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => CashMovement.fromJson(e as Map)).toList();
  }

  Future<void> approveCashMovement(String id) => api.post('/admin/cash-movements/$id/approve');
  Future<void> rejectCashMovement(String id) => api.post('/admin/cash-movements/$id/reject');

  // ---- floor areas + tables (MANAGER+, table.manage) ----------------------
  Future<List<FloorArea>> floorAreas(String branchId) async {
    final data = await api.get('/admin/branches/$branchId/floor-areas');
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => FloorArea.fromJson(e as Map)).toList();
  }

  Future<void> createFloorArea(String branchId, {required String name, int level = 1}) =>
      api.post('/admin/branches/$branchId/floor-areas', body: {'name': name, 'level': level});

  Future<void> updateFloorArea(String id, {String? name, int? level}) =>
      api.patch('/admin/floor-areas/$id', body: {'name': ?name, 'level': ?level});

  Future<void> deleteFloorArea(String id) => api.delete('/admin/floor-areas/$id');

  Future<List<AdminTable>> areaTables(String areaId) async {
    final data = await api.get('/admin/floor-areas/$areaId/tables');
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => AdminTable.fromJson(e as Map)).toList();
  }

  Future<void> createTable(String areaId, {required String code, String? name, int seats = 2}) =>
      api.post('/admin/floor-areas/$areaId/tables', body: {'code': code, 'name': ?name, 'seats': seats});

  Future<void> updateTable(String id, {String? code, String? name, int? seats, String? status}) =>
      api.patch('/admin/tables/$id', body: {'code': ?code, 'name': ?name, 'seats': ?seats, 'status': ?status});

  Future<void> deleteTable(String id) => api.delete('/admin/tables/$id');

  // ---- vouchers (MANAGER+, voucher.manage) --------------------------------
  Future<List<Voucher>> vouchers() async {
    final data = await api.get('/admin/vouchers');
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => Voucher.fromJson(e as Map)).toList();
  }

  Future<void> createVoucher({
    required String code,
    required String name,
    required String discountType,
    required int discountValue,
    int minOrderAmount = 0,
    int? maxDiscount,
    int? usageLimit,
    String? startsAt,
    String? endsAt,
  }) =>
      api.post('/admin/vouchers', body: {
        'code': code,
        'name': name,
        'discountType': discountType,
        'discountValue': discountValue,
        'minOrderAmount': minOrderAmount,
        'maxDiscount': ?maxDiscount,
        'usageLimit': ?usageLimit,
        'startsAt': ?startsAt,
        'endsAt': ?endsAt,
      });

  Future<void> updateVoucher(
    String id, {
    String? name,
    int? discountValue,
    int? minOrderAmount,
    int? maxDiscount,
    int? usageLimit,
    String? status,
    String? startsAt,
    String? endsAt,
  }) =>
      api.patch('/admin/vouchers/$id', body: {
        'name': ?name,
        'discountValue': ?discountValue,
        'minOrderAmount': ?minOrderAmount,
        'maxDiscount': ?maxDiscount,
        'usageLimit': ?usageLimit,
        'status': ?status,
        'startsAt': ?startsAt,
        'endsAt': ?endsAt,
      });

  Future<void> deleteVoucher(String id) => api.delete('/admin/vouchers/$id');

  /// Void/refund requests awaiting review — GET /admin/void-refund-requests.
  Future<List<VoidRefundRequest>> voidRefundRequests({String? status}) async {
    final data = await api.get('/admin/void-refund-requests', query: status != null ? {'status': status} : null);
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => VoidRefundRequest.fromJson(e as Map)).toList();
  }

  /// Approve a request (deducts revenue, restocks, claws back points) —
  /// POST /admin/void-refund-requests/:id/approve. MANAGER+ / bill.void_approve.
  Future<void> approveVoidRefund(String id) =>
      api.post('/admin/void-refund-requests/$id/approve');

  /// Reject a request — POST /admin/void-refund-requests/:id/reject {reason?}.
  Future<void> rejectVoidRefund(String id, {String? reason}) => api.post(
        '/admin/void-refund-requests/$id/reject',
        body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      );

  // ---- writes (MANAGER+, menu.manage) -------------------------------------

  /// Toggle a product on/off the menu (available = status ACTIVE).
  Future<void> setProductStatus(String id, bool active) =>
      api.patch('/admin/products/$id', body: {'status': active ? 'ACTIVE' : 'INACTIVE'});

  /// Create a product with a single default variant priced at [basePrice].
  Future<void> createProduct({
    required String categoryId,
    required String name,
    required int basePrice,
    bool active = true,
  }) =>
      api.post('/admin/products', body: {
        'categoryId': categoryId,
        'name': name,
        'basePrice': basePrice,
        'status': active ? 'ACTIVE' : 'INACTIVE',
        'hasModifiers': false,
        'variants': [
          {'price': basePrice, 'isDefault': true},
        ],
      });

  /// Create a staff account — POST /admin/users. MANAGER+ / staff.manage.
  Future<void> createStaff({
    required String username,
    required String password,
    required String fullName,
    required String staffRole,
    String? branchId,
  }) =>
      api.post('/admin/users', body: {
        'username': username,
        'password': password,
        'fullName': fullName,
        'staffRole': staffRole,
        'branchId': ?branchId,
      });

  /// Lock (deactivate) a staff account — POST /admin/users/:id/deactivate.
  Future<void> deactivateStaff(String id) => api.post('/admin/users/$id/deactivate');

  /// Unlock a staff account — PATCH /admin/users/:id {status: ACTIVE}.
  Future<void> reactivateStaff(String id) => api.patch('/admin/users/$id', body: {'status': 'ACTIVE'});

  /// Stock-in: add quantity to an ingredient — POST /admin/inventory/stock-in.
  Future<void> stockIn({
    required String branchId,
    required String ingredientId,
    required num quantity,
    String? reason,
  }) =>
      api.post('/admin/inventory/stock-in', body: {
        'branchId': branchId,
        'reason': ?reason,
        'items': [
          {'ingredientId': ingredientId, 'quantity': quantity},
        ],
      });

  /// Adjustment: apply a signed delta to on-hand (correction) — POST
  /// /admin/inventory/adjustments. [quantity] may be negative; [reason] required.
  Future<void> adjustStock({
    required String branchId,
    required String ingredientId,
    required num quantity,
    required String reason,
  }) =>
      api.post('/admin/inventory/adjustments', body: {
        'branchId': branchId,
        'reason': reason,
        'items': [
          {'ingredientId': ingredientId, 'quantity': quantity},
        ],
      });

  /// Patch a product's editable fields (only non-null entries are sent).
  Future<void> updateProduct(
    String id, {
    String? name,
    String? categoryId,
    int? basePrice,
    bool? active,
  }) =>
      api.patch('/admin/products/$id', body: {
        'name': ?name,
        'categoryId': ?categoryId,
        'basePrice': ?basePrice,
        if (active != null) 'status': active ? 'ACTIVE' : 'INACTIVE',
      });
}
