import '../models/report.dart';
import 'api_client.dart';

/// Admin reporting reads (/admin/reports/...). Requires MANAGER/SUPER_ADMIN +
/// report.view. All READS — safe against any backend.
class ReportsRepository {
  final ApiClient api;
  ReportsRepository(this.api);

  Map<String, dynamic> _range(DateTime? from, DateTime? to) => {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      };

  Future<SalesSummary> salesSummary({DateTime? from, DateTime? to}) async {
    final data = await api.get('/admin/reports/sales-summary', query: _range(from, to));
    return SalesSummary.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<BestSeller>> bestSelling({DateTime? from, DateTime? to, int limit = 10}) async {
    final data = await api.get('/admin/reports/best-selling-products',
        query: {..._range(from, to), 'limit': limit});
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => BestSeller.fromJson(e as Map)).toList();
  }

  Future<List<PayMethodStat>> paymentMethods({DateTime? from, DateTime? to}) async {
    final data = await api.get('/admin/reports/payment-methods', query: _range(from, to));
    final list = data is List ? data : ((data as Map)['items'] ?? const []) as List;
    return list.map((e) => PayMethodStat.fromJson(e as Map)).toList();
  }
}
