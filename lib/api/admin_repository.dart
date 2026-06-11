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
}
