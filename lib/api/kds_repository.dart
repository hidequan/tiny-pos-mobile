import '../models/kds.dart';
import 'api_client.dart';

/// KDS / Bar operations against the shared backend (/kds/...).
class KdsRepository {
  final ApiClient api;
  KdsRepository(this.api);

  Future<List<KdsTicket>> tickets() async {
    final data = await api.get('/kds/tickets');
    final list = data is List ? data : ((data as Map)['items'] ?? (data)['tickets'] ?? []) as List;
    return list.map((e) => KdsTicket.fromJson(e as Map)).toList();
  }

  Future<KdsStats> stats() async {
    final data = await api.get('/kds/stats');
    return KdsStats.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // Item transitions.
  Future<void> startItem(String itemId) => api.post('/kds/ticket-items/$itemId/start');
  Future<void> readyItem(String itemId) => api.post('/kds/ticket-items/$itemId/ready');
  Future<void> servedItem(String itemId) => api.post('/kds/ticket-items/$itemId/served');

  // Ticket transitions.
  Future<void> startTicket(String id) => api.post('/kds/tickets/$id/start');
  Future<void> readyTicket(String id) => api.post('/kds/tickets/$id/ready');
  Future<void> completeTicket(String id) => api.post('/kds/tickets/$id/complete');
}
