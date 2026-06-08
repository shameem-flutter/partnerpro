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

  final FlutterSecureStorage _storage;

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: accessTokenKey, value: session.accessToken);
    await _storage.write(key: refreshTokenKey, value: session.refreshToken);
    await _storage.write(
      key: userJsonKey,
      value: jsonEncode(session.user.toJson()),
    );
  }

  Future<AuthSession?> loadSession() async {
    final accessToken = await _storage.read(key: accessTokenKey);
    final refreshToken = await _storage.read(key: refreshTokenKey);
    final userJson = await _storage.read(key: userJsonKey);

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        userJson == null ||
        userJson.isEmpty) {
      return null;
    }

    try {
      final decodedUser = jsonDecode(userJson);
      if (decodedUser is! Map<String, dynamic>) {
        return null;
      }

      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: AuthUser.fromJson(decodedUser),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: userJsonKey);
  }
}
