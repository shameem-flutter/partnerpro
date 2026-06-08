import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
  
  dio.interceptors.add(RetryInterceptor(dio: dio));
  
  return dio;
});
