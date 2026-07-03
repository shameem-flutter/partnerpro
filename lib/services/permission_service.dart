import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Centralized service to manage JWT-decoded permissions.
///
/// Decodes the JWT access token, extracts the permissions list,
/// and exposes helper methods for checking access control.
class PermissionService {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  List<String> _permissions = [];
  bool _isAdmin = false;
  String _userType = '';

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initialise from a raw JWT access token string.
  void initFromToken(String accessToken) {
    try {
      final payload = _decodeJwtPayload(accessToken);

      debugPrint('🔑 [PermissionService] initFromToken – decoded payload:');
      debugPrint(const JsonEncoder.withIndent('  ').convert(payload));

      final perms = payload['permissions'];
      debugPrint(
        '🔑 [PermissionService] permissions field → type: ${perms.runtimeType}, value: $perms',
      );

      if (perms is List && perms.isNotEmpty) {
        _permissions = perms.map((e) => e.toString()).toList();
        _isAdmin = true;
        debugPrint(
          '🔑 [PermissionService] ✅ ${_permissions.length} permission(s) → role = ADMIN',
        );
      } else {
        _permissions = [];
        _isAdmin = false;
        debugPrint(
          '🔑 [PermissionService] ⚠️  no permissions → role = NORMAL USER',
        );
      }

      _userType = payload['user']?['user_type']?.toString() ?? '';
      debugPrint('🔑 [PermissionService] userType = $_userType');
    } catch (e, stack) {
      debugPrint('🔑 [PermissionService] ❌ initFromToken ERROR: $e');
      debugPrint('🔑 [PermissionService] Stack: $stack');
      _permissions = [];
      _isAdmin = false;
      _userType = '';
    }
  }

  /// Clear all stored permissions (e.g. on logout).
  void clear() {
    _permissions = [];
    _isAdmin = false;
    _userType = '';
    debugPrint('🔑 [PermissionService] cleared – user logged out');
  }

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  List<String> get permissions => List.unmodifiable(_permissions);
  bool get isAdmin => _isAdmin;
  String get userType => _userType;

  // ---------------------------------------------------------------------------
  // Permission checks
  // ---------------------------------------------------------------------------

  bool hasPermission(String permission) => _permissions.contains(permission);

  bool hasAnyPermission(List<String> permissions) =>
      permissions.any((p) => _permissions.contains(p));

  bool hasAllPermissions(List<String> permissions) =>
      permissions.every((p) => _permissions.contains(p));

  // ---------------------------------------------------------------------------
  // JWT helpers
  // ---------------------------------------------------------------------------

  /// Decode a JWT payload segment using Dart's built-in base64Url codec.
  ///
  /// Uses [base64Url.normalize] to automatically add missing `=` padding,
  /// then [base64Url.decode] which handles URL-safe `-` and `_` characters
  /// natively — no manual character replacement needed.
  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw FormatException(
        'Invalid JWT: expected 3 dot-separated parts, got ${parts.length}',
      );
    }

    final payloadSegment = parts[1];
    debugPrint(
      '🔑 [PermissionService] payload segment length: ${payloadSegment.length}',
    );
    debugPrint(
      '🔑 [PermissionService] payload segment (first 80 chars): '
      '${payloadSegment.substring(0, payloadSegment.length.clamp(0, 80))}…',
    );

    // base64Url.normalize adds missing padding automatically.
    // base64Url.decode handles the URL-safe alphabet (- and _) natively.
    final normalised = base64Url.normalize(payloadSegment);
    final bytes = base64Url.decode(normalised);
    final jsonString = utf8.decode(bytes);

    debugPrint('🔑 [PermissionService] decoded JSON string: $jsonString');

    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
    throw FormatException('JWT payload is not a JSON object: ${decoded.runtimeType}');
  }

  /// Decode a JWT and return the payload without storing anything.
  static Map<String, dynamic> decodeToken(String token) =>
      _decodeJwtPayload(token);

  /// Returns true if the token's `permissions` field is non-empty.
  static bool tokenHasPermissions(String token) {
    try {
      final payload = _decodeJwtPayload(token);
      final perms = payload['permissions'];
      return perms is List && perms.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
