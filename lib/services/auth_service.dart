import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import '../models/auth_session.dart';
import '../models/auth_user.dart';
import 'permission_service.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // Public login entry-point
  //
  // Strategy:
  //   1. Try the ADMIN server (cloudflare URL) first.
  //   2. If that returns a JWT with permissions → ADMIN session. Done.
  //   3. Otherwise try the NORMAL server (partnerpro.saasorder.com).
  //   4. Return whichever result we got (normal user if no permissions found).
  //
  // This handles the case where the same email exists on both servers but only
  // the admin server embeds `permissions` into the JWT.
  // ---------------------------------------------------------------------------

  Future<AuthSession> login(String email, String password) async {
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('🔐 [AUTH] Login attempt for: ${email.trim()}');
    debugPrint('═══════════════════════════════════════════════');

    // ── Step 1: Try admin server ─────────────────────────────────────────────
    debugPrint('🔐 [AUTH] Step 1: Trying ADMIN server…');
    try {
      final adminUrl = await ApiConfig.getAdminFullUrl(
        '/api/v1/dashboard/login/',
      );
      final adminSession = await _doLogin(adminUrl, email, password);

      if (adminSession.role == UserRole.admin) {
        debugPrint(
          '🔐 [AUTH] ✅ Admin server login successful → ADMIN 🛡️',
        );
        debugPrint('═══════════════════════════════════════════════');
        return adminSession;
      }

      debugPrint(
        '🔐 [AUTH] ⚠️  Admin server returned no permissions → trying normal server…',
      );

      // ── Step 2: Try normal server ──────────────────────────────────────────
      debugPrint('🔐 [AUTH] Step 2: Trying NORMAL server…');
      try {
        final normalUrl = await ApiConfig.getFullUrl(
          '/api/v1/dashboard/login/',
        );
        final normalSession = await _doLogin(normalUrl, email, password);
        debugPrint(
          '🔐 [AUTH] ✅ Normal server login successful → NORMAL USER 👤',
        );
        debugPrint('═══════════════════════════════════════════════');
        return normalSession;
      } catch (_) {
        // Normal server failed too – return the admin-server session (no perms)
        debugPrint(
          '🔐 [AUTH] ⚠️  Normal server also failed → using admin server result (no permissions)',
        );
        debugPrint('═══════════════════════════════════════════════');
        return adminSession;
      }
    } catch (adminError) {
      // Admin server login failed entirely – fall back to normal server
      debugPrint(
        '🔐 [AUTH] ⚠️  Admin server failed ($adminError) → trying normal server…',
      );

      // ── Step 2 (fallback): Normal server ──────────────────────────────────
      debugPrint('🔐 [AUTH] Step 2: Trying NORMAL server…');
      final normalUrl = await ApiConfig.getFullUrl(
        '/api/v1/dashboard/login/',
      );
      final normalSession = await _doLogin(normalUrl, email, password);
      debugPrint(
        '🔐 [AUTH] ✅ Normal server login successful → NORMAL USER 👤',
      );
      debugPrint('═══════════════════════════════════════════════');
      return normalSession;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal: single login attempt against one URL
  // ---------------------------------------------------------------------------

  Future<AuthSession> _doLogin(
    String loginUrl,
    String email,
    String password,
  ) async {
    debugPrint('🔐 [AUTH]   → POST $loginUrl');

    try {
      final response = await _dio.post<dynamic>(
        loginUrl,
        data: <String, String>{
          'email': email.trim(),
          'password': password,
        },
        options: Options(
          headers: const <String, String>{
            'Content-Type': 'application/json',
          },
          followRedirects: false,
          // Short timeout so admin-server failures don't block the user
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      debugPrint('🔐 [AUTH]   HTTP status : ${response.statusCode}');

      dynamic rawData = response.data;
      if (rawData is String) rawData = jsonDecode(rawData);

      debugPrint(
        '🔐 [AUTH]   Raw response: ${const JsonEncoder.withIndent('  ').convert(rawData)}',
      );

      final responseBody = _normalizeMap(rawData);
      final accessToken = responseBody?['access']?.toString() ?? '';
      final refreshToken = responseBody?['refresh']?.toString() ?? '';

      debugPrint(
        '🔐 [AUTH]   access token present  : ${accessToken.isNotEmpty}',
      );
      debugPrint(
        '🔐 [AUTH]   refresh token present : ${refreshToken.isNotEmpty}',
      );

      // ── JWT decode ──────────────────────────────────────────────────────────
      List<String> permissions = [];
      Map<String, dynamic>? jwtUser;

      if (accessToken.isNotEmpty) {
        debugPrint('🔐 [AUTH]   Decoding JWT…');
        try {
          final payload = PermissionService.decodeToken(accessToken);
          debugPrint(
            '🔐 [AUTH]   JWT payload: ${const JsonEncoder.withIndent('  ').convert(payload)}',
          );

          final perms = payload['permissions'];
          debugPrint(
            '🔐 [AUTH]   permissions → type: ${perms.runtimeType}, value: $perms',
          );

          if (perms is List && perms.isNotEmpty) {
            permissions = perms.map((e) => e.toString()).toList();
            debugPrint(
              '🔐 [AUTH]   ✅ ${permissions.length} permission(s) found',
            );
          } else {
            debugPrint('🔐 [AUTH]   ⚠️  no permissions in JWT');
          }

          if (payload['user'] is Map) {
            jwtUser = _normalizeMap(payload['user']);
          }
        } catch (e, stack) {
          debugPrint('🔐 [AUTH]   ❌ JWT decode error: $e');
          debugPrint('🔐 [AUTH]   Stack: $stack');
        }
      }

      // ── Build user ──────────────────────────────────────────────────────────
      var userJson = _normalizeMap(responseBody?['user']) ?? jwtUser;
      if (userJson == null && accessToken.isNotEmpty) {
        userJson = <String, dynamic>{
          'id': 0,
          'email': email.trim(),
          'username': email.split('@').first,
          'first_name': '',
          'last_name': '',
          'role': 0,
          'phone_number': '',
          'user_type': '',
        };
      }

      if (accessToken.isEmpty || refreshToken.isEmpty || userJson == null) {
        throw const AuthException('Login response was incomplete.');
      }

      PermissionService.instance.initFromToken(accessToken);
      final userModel = AuthUser.fromJson(userJson);
      var role = permissions.isNotEmpty ? UserRole.admin : UserRole.normal;
      if (userModel.userType == 'end_user') {
        role = UserRole.normal;
      }

      debugPrint(
        '🔐 [AUTH]   Final role: ${role == UserRole.admin ? "ADMIN 🛡️" : "NORMAL USER 👤"}',
      );

      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: userModel,
        permissions: permissions,
        role: role,
      );
    } on DioException catch (error) {
      debugPrint(
        '🔐 [AUTH]   ❌ DioException at $loginUrl: ${error.type} – ${error.message}',
      );
      if (error.response != null) {
        debugPrint(
          '🔐 [AUTH]   Status: ${error.response?.statusCode}  Data: ${error.response?.data}',
        );
      }

      final response = error.response;
      final statusCode = response?.statusCode;

      if (statusCode != null && statusCode >= 300 && statusCode < 400) {
        final redirectUrl =
            response?.headers.value('location') ?? 'unknown location';
        throw AuthException(
          'Login failed: server redirected (Status $statusCode) to: $redirectUrl.',
        );
      }

      dynamic errorData = response?.data;
      if (errorData is String) {
        try {
          errorData = jsonDecode(errorData);
        } catch (_) {}
      }
      final body = _normalizeMap(errorData);

      var message =
          body?['message']?.toString() ??
          body?['error']?.toString() ??
          _extractErrorMessage(body);

      if (message == null) {
        final details =
            error.error?.toString() ?? error.message ?? error.type.name;
        message =
            'Login failed. Please check your connection and try again. [Detail: $details]';
      }

      throw AuthException(message);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic val) => MapEntry(key.toString(), val),
      );
    }
    return null;
  }

  String? _extractErrorMessage(Map<String, dynamic>? responseBody) {
    if (responseBody == null) return null;
    for (final dynamic value in responseBody.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }
}
