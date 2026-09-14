import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart'; // Import to access authNotifierProvider

class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If the server returns 401 Unauthorized (e.g. token expired)
    final isLoginEndpoint = err.requestOptions.path.contains('/login/');
    
    if (err.response?.statusCode == 401 && !isLoginEndpoint) {
      // 1. Silently log the user out. This updates the auth state, 
      // causing the main app router to instantly redirect to LoginScreen.
      ref.read(authNotifierProvider.notifier).logout();
      
      // 2. We can optionally swallow the error here or pass it on.
      // Since the app instantly redirects to login, we pass it on so the 
      // current failing function aborts gracefully instead of returning null data.
    }
    return handler.next(err);
  }
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    
    // Don't retry if the request contains FormData (e.g., file uploads) 
    // because the internal data stream can only be read once and will crash on retry.
    if (requestOptions.data is FormData) {
      return handler.next(err);
    }

    // Do not retry 401 Unauthorized errors, as they require a new login/token
    if (err.response?.statusCode == 401) {
      return handler.next(err);
    }
    
    // Check if we should retry the request
    final extra = requestOptions.extra;
    final int currentRetryAttempt = (extra['retry_attempt'] ?? 0) as int;
    
    // Only retry if it's a network/timeout error or server error (5xx)
    final bool isTimeoutOrNetworkError = 
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown;

    final bool isServerError = err.response != null && 
        (err.response!.statusCode ?? 0) >= 500;

    if ((isTimeoutOrNetworkError || isServerError) && currentRetryAttempt < maxRetries) {
      final nextAttempt = currentRetryAttempt + 1;
      requestOptions.extra['retry_attempt'] = nextAttempt;
      
      // Exponential or incremental delay before retrying
      await Future<void>.delayed(retryDelay * nextAttempt);
      
      try {
        // Retry the request using the same requestOptions via dio.fetch
        final response = await dio.fetch<dynamic>(requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // If the retry also fails, let the error propagate or proceed to next error handler
        if (e is DioException) {
          return handler.next(e);
        }
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  
  // Use BackgroundTransformer to parse massive JSON payloads in a separate 
  // isolate (background thread) so the UI doesn't freeze (lag) on mobile.
  dio.transformer = BackgroundTransformer();
  
  // Add AuthInterceptor to handle 401s and token expiration
  dio.interceptors.add(AuthInterceptor(ref));
  
  dio.interceptors.add(RetryInterceptor(dio: dio));
  

  return dio;
});
