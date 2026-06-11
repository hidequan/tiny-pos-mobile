/// Backend configuration. The shared tiny-pos API powering both the web
/// (pos.lptech.info.vn/pos) and this app — "app và web là 1, chung dữ liệu".
///
/// Override at build time WITHOUT touching production data, e.g. point at a
/// local backend while testing writes:
///   flutter run --dart-define=API_BASE=http://10.0.2.2:4000/api
class ApiConfig {
  /// Production by default (the live shared backend).
  static const String baseUrl =
      String.fromEnvironment('API_BASE', defaultValue: 'https://pos.lptech.info.vn/api');

  /// True when pointed at the live production backend — used to guard against
  /// accidental destructive test actions.
  static bool get isProduction => baseUrl.contains('pos.lptech.info.vn');
}
