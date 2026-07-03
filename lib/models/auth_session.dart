import 'auth_user.dart';

enum UserRole { normal, admin }

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.permissions = const [],
    this.role = UserRole.normal,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
  final List<String> permissions;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;
}
