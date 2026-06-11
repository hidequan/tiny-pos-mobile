import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/menu.dart';

/// Loads and caches the POS menu (GET /pos/menu) — the real catalog shared with
/// the web. Named PosMenuController to avoid Flutter's material MenuController.
class PosMenuController extends ChangeNotifier {
  final ApiClient api;
  PosMenuController(this.api);

  Menu? menu;
  bool loading = false;
  String? error;

  bool get isLoaded => menu != null;

  /// Test-only: preload a menu without hitting the network.
  @visibleForTesting
  void debugSetMenu(Menu m) {
    menu = m;
    loading = false;
    error = null;
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (menu != null && !force) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await api.get('/pos/menu');
      menu = Menu.fromJson(Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Không tải được thực đơn';
    }
    loading = false;
    notifyListeners();
  }
}
