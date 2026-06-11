/// The authenticated user, as returned by /auth/login and /auth/me.
class AuthUser {
  final String id;
  final String username;
  final String fullName;
  final String staffRole; // CASHIER | BARISTA | MANAGER | ADMIN | SUPER_ADMIN ...
  final String? branchId;
  final List<String> roles;
  final List<String> permissions;

  AuthUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.staffRole,
    required this.branchId,
    required this.roles,
    required this.permissions,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] as String,
        username: j['username'] as String,
        fullName: (j['fullName'] as String?) ?? (j['username'] as String),
        staffRole: (j['staffRole'] as String?) ?? '',
        branchId: j['branchId'] as String?,
        roles: ((j['roles'] as List?) ?? const []).map((e) => e.toString()).toList(),
        permissions: ((j['permissions'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );

  bool can(String permission) => permissions.contains(permission);
  bool get isBarista => staffRole == 'BARISTA';
  bool get isCashier => staffRole == 'CASHIER';
  bool get isManagerUp =>
      staffRole == 'MANAGER' || staffRole == 'ADMIN' || staffRole == 'SUPER_ADMIN';

  /// Two initials for the avatar.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return username.substring(0, 1).toUpperCase();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[parts.length - 2][0] + parts.last[0]).toUpperCase();
  }
}
