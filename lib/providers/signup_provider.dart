import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_config.dart';
import 'dio_provider.dart';

class SignupState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const SignupState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });
}

class SignupNotifier extends StateNotifier<SignupState> {
  final Dio _dio;

  SignupNotifier({Dio? dio}) : _dio = dio ?? Dio(), super(const SignupState());

  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password1,
    required String password2,
  }) async {
    state = const SignupState(isLoading: true);
    try {
      final registerUrl = await ApiConfig.getFullUrl(
        '/api/v1/dashboard/register/',
      );
      await _dio.post(
        registerUrl,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'email': email,
          'password1': password1,
          'password2': password2,
        },
      );
      state = const SignupState(isSuccess: true);
      return true;
    } on DioException catch (e) {
      debugPrint('SignupNotifier.signup DioException: ${e.type} - ${e.message}');
      if (e.error != null) {
        debugPrint('SignupNotifier.signup underlying error: ${e.error}');
      }
      if (e.response != null) {
        debugPrint('SignupNotifier.signup response status: ${e.response?.statusCode}');
        debugPrint('SignupNotifier.signup response data: ${e.response?.data}');
      }

      String errorMessage = 'Registration failed. Please try again.';
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else {
            for (final entry in data.entries) {
              final val = entry.value;
              if (val is List && val.isNotEmpty) {
                errorMessage = '${entry.key}: ${val.first}';
                break;
              } else if (val is String) {
                errorMessage = '${entry.key}: $val';
                break;
              }
            }
          }
        }
      } else {
        final details = e.error?.toString() ?? e.message ?? e.type.name;
        errorMessage = 'Registration failed. Please check your connection and try again. [Detail: $details]';
      }
      state = SignupState(errorMessage: errorMessage);
      return false;
    } catch (e) {
      debugPrint('SignupNotifier.signup unexpected error: $e');
      state = SignupState(
        errorMessage: 'An unexpected error occurred. Please try again. [Detail: $e]',
      );
      return false;
    }
  }
}

final signupNotifierProvider =
    StateNotifierProvider<SignupNotifier, SignupState>((ref) {
      final dio = ref.watch(dioProvider);
      return SignupNotifier(dio: dio);
    });
