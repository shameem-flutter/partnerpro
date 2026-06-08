import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import '../models/auth_session.dart';
import '../models/auth_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<AuthSession> login(String email, String password) async {
    try {
      final loginUrl = await ApiConfig.getFullUrl('/api/v1/dashboard/login/');
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
        ),
      );

      dynamic rawData = response.data;
      if (rawData is String) {
        rawData = jsonDecode(rawData);
      }

      final responseBody = _normalizeMap(rawData);
      final accessToken = responseBody?['access']?.toString() ?? '';
      final refreshToken = responseBody?['refresh']?.toString() ?? '';
      final userJson = _normalizeMap(responseBody?['user']);

      if (accessToken.isEmpty || refreshToken.isEmpty || userJson == null) {
        throw const AuthException('Login response was incomplete.');
      }

      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: AuthUser.fromJson(userJson),
      );
    } on DioException catch (error) {
      // Print detailed logs so developers can see the error in adb logcat/console
      debugPrint('AuthService.login DioException: ${error.type} - ${error.message}');
      if (error.error != null) {
        debugPrint('AuthService.login underlying error: ${error.error}');
      }
      if (error.response != null) {
        debugPrint('AuthService.login response status: ${error.response?.statusCode}');
        debugPrint('AuthService.login response data: ${error.response?.data}');
      }

      final response = error.response;
      final statusCode = response?.statusCode;
      
      // If the server attempted to redirect the login request
      if (statusCode != null && statusCode >= 300 && statusCode < 400) {
        final redirectUrl = response?.headers.value('location') ?? 'unknown location';
        throw AuthException(
          'Login failed because the server redirected the request (Status $statusCode) to: $redirectUrl. '
          'Please ensure that your base URL matches the server\'s canonical domain and configuration (e.g., matching trailing slashes and using HTTPS/HTTP appropriately).'
        );
      }

      dynamic errorData = response?.data;
      if (errorData is String) {
        try {
          errorData = jsonDecode(errorData);
        } catch (_) {}
      }
      final responseBody = _normalizeMap(errorData);
      
      var message =
          responseBody?['message']?.toString() ??
          _extractErrorMessage(responseBody);

      if (message == null) {
        final details = error.error?.toString() ?? error.message ?? error.type.name;
        message = 'Login failed. Please check your connection and try again. [Detail: $details]';
      }
      
      throw AuthException(message);
    }
  }

  Map<String, dynamic>? _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (dynamic key, dynamic val) => MapEntry(key.toString(), val),
      );
    }

    return null;
  }

  String? _extractErrorMessage(Map<String, dynamic>? responseBody) {
    if (responseBody == null) {
      return null;
    }

    for (final dynamic value in responseBody.values) {
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}
