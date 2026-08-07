import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session.dart';
import '../models/auth_user.dart';

class AuthStorage {
  AuthStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String accessTokenKey = 'auth_access_token';
  static const String refreshTokenKey = 'auth_refresh_token';
  static const String userJsonKey = 'auth_user_json';
  static const String permissionsKey = 'auth_permissions';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: accessTokenKey, value: session.accessToken);
    await _storage.write(key: refreshTokenKey, value: session.refreshToken);
    await _storage.write(
      key: userJsonKey,
      value: jsonEncode(session.user.toJson()),
    );
    await _storage.write(
      key: permissionsKey,
      value: jsonEncode(session.permissions),
    );
  }

  Future<AuthSession?> loadSession() async {
    try {
      final accessToken = await _storage.read(key: accessTokenKey);
      final refreshToken = await _storage.read(key: refreshTokenKey);
      final userJson = await _storage.read(key: userJsonKey);
      final permissionsJson = await _storage.read(key: permissionsKey);

      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty ||
          userJson == null ||
          userJson.isEmpty) {
        return null;
      }

      final decodedUser = jsonDecode(userJson);
      if (decodedUser is! Map<String, dynamic>) {
        return null;
      }

      List<String> permissions = [];
      if (permissionsJson != null && permissionsJson.isNotEmpty) {
        final decoded = jsonDecode(permissionsJson);
        if (decoded is List) {
          permissions = decoded.map((e) => e.toString()).toList();
        }
      }

      final userModel = AuthUser.fromJson(decodedUser);
      final appUserType = AppUserTypeMapper.fromString(userModel.userType);

      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: userModel,
        permissions: permissions,
        userType: appUserType,
      );
    } catch (e) {
      // In case of decryption errors (bad decrypt/bad padding due to Android keystore changes),
      // wipe the storage to allow a fresh login instead of crashing the app.
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: userJsonKey);
    await _storage.delete(key: permissionsKey);
  }
}
