import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partnerpro/providers/dio_provider.dart';

class MyMockAdapter implements HttpClientAdapter {
  int callCount = 0;
  final int failCount;
  final int statusCode;

  MyMockAdapter({this.failCount = 0, this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    if (callCount <= failCount) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'Connection failed',
      );
    }
    return ResponseBody.fromString(
      '{"success": true}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('RetryInterceptor tests', () {
    test('Should retry successfully and then return success response', () async {
      final dio = Dio();
      final adapter = MyMockAdapter(failCount: 2, statusCode: 200);
      dio.httpClientAdapter = adapter;
      
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          retryDelay: const Duration(milliseconds: 10),
        ),
      );

      final response = await dio.get<dynamic>('https://example.com/test');
      
      expect(response.statusCode, 200);
      expect(adapter.callCount, 3); // 1 initial + 2 retries
    });

    test('Should fail if retries exceed maxRetries', () async {
      final dio = Dio();
      final adapter = MyMockAdapter(failCount: 4, statusCode: 200);
      dio.httpClientAdapter = adapter;
      
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 2,
          retryDelay: const Duration(milliseconds: 10),
        ),
      );

      expect(
        () => dio.get<dynamic>('https://example.com/test'),
        throwsA(isA<DioException>()),
      );
      
      // Allow some time for all async retries to finish
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(adapter.callCount, 3); // 1 initial + 2 retries = 3 total calls
    });
  });
}
