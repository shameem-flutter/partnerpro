import 'auth_user.dart';

enum AppUserType {
  manager,
  internal,
  publicUser,
  unknown
}

extension AppUserTypeMapper on AppUserType {
  static AppUserType fromString(String userType) {
    switch (userType) {
      case 'manager':
        return AppUserType.manager;
      case 'sales_person':
        return AppUserType.internal;
      case 'referral_salesperson':
        return AppUserType.publicUser;
      default:
        return AppUserType.unknown;
    }
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.userType,
    this.permissions = const [],
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
  final List<String> permissions;
  final AppUserType userType;
}
