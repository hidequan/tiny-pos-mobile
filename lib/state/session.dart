import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/token_store.dart';
import '../models/auth_user.dart';

enum SessionStatus { loading, signedOut, signedIn }

/// Owns authentication for the whole app: the API client, the token pair, and
/// the current [AuthUser]. Screens read this to gate UI by role/permission.
class SessionState extends ChangeNotifier {
  final TokenStore tokens = TokenStore();
  late final ApiClient api;

  SessionStatus status = SessionStatus.loading;
  AuthUser? user;
  String? lastError;

  SessionState() {
    api = ApiClient(tokens: tokens, onUnauthorized: _onUnauthorized);
  }

  /// Restore a persisted session on startup (validates via /auth/me).
  Future<void> restore() async {
    await tokens.load();
    if (!tokens.hasSession) {
      _set(SessionStatus.signedOut);
      return;
    }
    try {
      final me = await api.get('/auth/me');
      user = AuthUser.fromJson(Map<String, dynamic>.from(me as Map));
      _set(SessionStatus.signedIn);
    } catch (_) {
      await tokens.clear();
      _set(SessionStatus.signedOut);
    }
  }

  Future<bool> login(String username, String password) async {
    lastError = null;
    try {
      final data = await api.post('/auth/login', body: {
        'username': username.trim(),
        'password': password,
      });
      final m = Map<String, dynamic>.from(data as Map);
      await tokens.save(m['accessToken'] as String, m['refreshToken'] as String);
      user = AuthUser.fromJson(Map<String, dynamic>.from(m['user'] as Map));
      _set(SessionStatus.signedIn);
      return true;
    } on ApiException catch (e) {
      lastError = e.code == 'UNAUTHORIZED' || (e.status == 401)
          ? 'Sai tài khoản hoặc mật khẩu'
          : e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout');
    } catch (_) {/* best effort */}
    await tokens.clear();
    user = null;
    _set(SessionStatus.signedOut);
  }

  void _onUnauthorized() {
    // Token expired and refresh failed — drop to the login screen.
    user = null;
    _set(SessionStatus.signedOut);
  }

  void _set(SessionStatus s) {
    status = s;
    notifyListeners();
  }

  /// Test-only: pretend a user is signed in (no network).
  @visibleForTesting
  void debugSignIn(AuthUser u) {
    user = u;
    status = SessionStatus.signedIn;
    notifyListeners();
  }
}
