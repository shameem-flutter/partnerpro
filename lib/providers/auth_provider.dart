import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/auth_session.dart';
import '../services/auth_service.dart';
import '../services/auth_storage.dart';
import '../services/permission_service.dart';
// import 'dio_provider.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showGlobalSnackBar(String message, {bool isSuccess = false}) {
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
      ),
      backgroundColor: isSuccess
          ? const Color(0xFF06D6A0)
          : const Color(0xFFE63946),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

// ---------------------------------------------------------------------------
// Auth State
// ---------------------------------------------------------------------------

class AuthState {
  final bool isInitializing;
  final bool isLoading;
  final String? errorMessage;
  final AuthSession? session;

  const AuthState({
    this.isInitializing = false,
    this.isLoading = false,
    this.errorMessage,
    this.session,
  });

  AuthState copyWith({
    bool? isInitializing,
    bool? isLoading,
    String? errorMessage,
    AuthSession? session,
    bool clearError = false,
  }) {
    return AuthState(
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      session: session ?? this.session,
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());
final authServiceProvider = Provider<AuthService>((ref) {
  // Use a separate Dio instance for AuthService to break the circular dependency.
  // This prevents Riverpod from throwing a CircularDependencyError when AuthInterceptor
  // (which belongs to dioProvider) tries to read authNotifierProvider on a 401 error.
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: false,
        error: true,
      ),
    );
  }
  return AuthService(dio: dio);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final AuthStorage _authStorage;

  AuthNotifier(this._authService, this._authStorage)
    : super(const AuthState(isInitializing: true)) {
    Future.microtask(() => _init());
  }

  Future<void> _init() async {
    state = state.copyWith(isInitializing: true);
    final session = await _authStorage.loadSession();
    if (session != null) {
      // Re-initialise PermissionService from the stored token
      PermissionService.instance.initFromToken(session.accessToken);
      unawaited(_registerDevice(session.accessToken));
    }
    state = AuthState(session: session, isInitializing: false);
  }

  Future<void> _registerDevice(String accessToken) async {
    try {
      final fcmToken = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 5));
      if (fcmToken != null) {
        await _authService.registerDeviceToken(accessToken, fcmToken);
      }
    } catch (e) {
      debugPrint('Failed to fetch/register FCM token: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _authService.login(email, password);
      await _authStorage.saveSession(session);
      state = AuthState(session: session);
      _registerDevice(session.accessToken);
      return true;
    } on AuthException catch (e) {
      state = AuthState(errorMessage: e.message);
      return false;
    } catch (_) {
      state = const AuthState(errorMessage: 'Login failed. Please try again.');
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    PermissionService.instance.clear();
    await _authStorage.clearSession();
    state = const AuthState();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  final authStorage = ref.watch(authStorageProvider);
  return AuthNotifier(authService, authStorage);
});

// ---------------------------------------------------------------------------
// Navigation (Normal User)
// ---------------------------------------------------------------------------

enum ActiveScreen {
  dashboard,
  statement,
  viewMore,
  redeemDetails,
  incentiveReport,
}

final navigationProvider = StateProvider<ActiveScreen>(
  (ref) => ActiveScreen.dashboard,
);
