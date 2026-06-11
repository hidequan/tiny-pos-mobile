import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_store.dart';

/// A failed API call — carries the backend's error code + message.
class ApiException implements Exception {
  final String code;
  final String message;
  final int? status;
  ApiException(this.code, this.message, {this.status});
  @override
  String toString() => message;
}

/// Thin wrapper over Dio for the tiny-pos API: injects the bearer token,
/// unwraps the {success, data, message} envelope, and transparently refreshes
/// the access token on a 401 (once) before retrying.
class ApiClient {
  final TokenStore tokens;
  final void Function()? onUnauthorized; // called when refresh fails -> sign out
  late final Dio _dio;
  bool _refreshing = false;

  ApiClient({required this.tokens, this.onUnauthorized}) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
      // We validate the envelope ourselves, so let 4xx through to the handler.
      validateStatus: (s) => s != null && s < 500,
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = tokens.accessToken;
        if (t != null) options.headers['Authorization'] = 'Bearer $t';
        handler.next(options);
      },
    ));
  }

  // ---- public verbs (return the unwrapped `data`) ----
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query), path);
  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post(path, data: body), path);
  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch(path, data: body), path);
  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put(path, data: body), path);
  Future<dynamic> delete(String path, {Object? body}) =>
      _send(() => _dio.delete(path, data: body), path);

  Future<dynamic> _send(Future<Response> Function() call, String path) async {
    try {
      var res = await call();
      // 401 -> try a single refresh then retry.
      if (res.statusCode == 401 && !path.contains('/auth/')) {
        if (await _refresh()) {
          res = await call();
        }
      }
      return _unwrap(res);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ApiException('NETWORK', 'Không có kết nối mạng. Vui lòng thử lại.');
      }
      throw ApiException('NETWORK', e.message ?? 'Lỗi kết nối', status: e.response?.statusCode);
    }
  }

  dynamic _unwrap(Response res) {
    final body = res.data;
    if (body is Map && body['success'] == true) return body['data'];
    if (body is Map && body['success'] == false) {
      final err = body['error'];
      final code = (err is Map ? err['code'] : null)?.toString() ?? 'ERROR';
      final msg = (err is Map ? err['message'] : null)?.toString() ?? 'Đã xảy ra lỗi';
      if (res.statusCode == 401) onUnauthorized?.call();
      throw ApiException(code, msg, status: res.statusCode);
    }
    // Non-enveloped success (rare) — return raw.
    if ((res.statusCode ?? 500) < 300) return body;
    throw ApiException('HTTP_${res.statusCode}', 'Lỗi máy chủ (${res.statusCode})', status: res.statusCode);
  }

  /// Exchanges the refresh token for a new access token. Returns false (and
  /// signs out) on failure.
  Future<bool> _refresh() async {
    if (_refreshing) return false;
    final rt = tokens.refreshToken;
    if (rt == null) {
      onUnauthorized?.call();
      return false;
    }
    _refreshing = true;
    try {
      final res = await _dio.post('/auth/refresh-token', data: {'refreshToken': rt});
      final body = res.data;
      if (res.statusCode == 200 && body is Map && body['success'] == true) {
        final d = body['data'] as Map;
        await tokens.save(
          d['accessToken'] as String,
          (d['refreshToken'] as String?) ?? rt,
        );
        return true;
      }
    } catch (_) {/* fall through */}
    finally {
      _refreshing = false;
    }
    await tokens.clear();
    onUnauthorized?.call();
    return false;
  }
}
