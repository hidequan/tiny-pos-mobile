import '../models/admin.dart';
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
