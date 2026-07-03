import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/statement_order.dart';
import 'api_config.dart';

class StatementService {
  StatementService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<StatementOrderResponse> fetchOrders(String accessToken) async {
    try {
      final ordersUrl = await ApiConfig.getFullUrl('/api/v1/order-management/orders/');
      final response = await _dio.get<dynamic>(
        ordersUrl,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      dynamic rawData = response.data;
      if (rawData is String) {
        rawData = jsonDecode(rawData);
      }

      final normalized = _normalizeMap(rawData);
      if (normalized == null) {
        throw Exception('Received invalid response format from server');
      }

      return StatementOrderResponse.fromJson(normalized);
    } on DioException catch (e) {
      String message = 'Failed to load statement data. Please try again.';
      dynamic errorData = e.response?.data;
      if (errorData is String) {
        try {
          errorData = jsonDecode(errorData);
        } catch (_) {}
      }
      final responseBody = _normalizeMap(errorData);
      if (responseBody != null && responseBody.containsKey('message')) {
        message = responseBody['message'].toString();
      } else if (e.response != null) {
        message = 'Failed to load statement data. Server returned status code ${e.response?.statusCode}.';
      } else if (e.message != null) {
        message = e.message!;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to load statement: $e');
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
}
