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

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  final FlutterSecureStorage _storage;

  Future<void> saveSession(AuthSession session) async {
    await Future.wait([
      _storage.write(key: accessTokenKey, value: session.accessToken, aOptions: _androidOptions),
      _storage.write(key: refreshTokenKey, value: session.refreshToken, aOptions: _androidOptions),
      _storage.write(
        key: userJsonKey,
        value: jsonEncode(session.user.toJson()),
        aOptions: _androidOptions,
      ),
      _storage.write(
        key: permissionsKey,
        value: jsonEncode(session.permissions),
        aOptions: _androidOptions,
      ),
    ]);
  }

  Future<AuthSession?> loadSession() async {
    try {
      // Use single readAll IPC call to read all keys in one platform channel roundtrip
      final allData = await _storage.readAll(aOptions: _androidOptions);

      final accessToken = allData[accessTokenKey];
      final refreshToken = allData[refreshTokenKey];
      final userJson = allData[userJsonKey];
      final permissionsJson = allData[permissionsKey];

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
        await _storage.deleteAll(aOptions: _androidOptions);
      } catch (_) {}
      return null;
    }
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: accessTokenKey, aOptions: _androidOptions),
      _storage.delete(key: refreshTokenKey, aOptions: _androidOptions),
      _storage.delete(key: userJsonKey, aOptions: _androidOptions),
      _storage.delete(key: permissionsKey, aOptions: _androidOptions),
    ]);
  }
}
