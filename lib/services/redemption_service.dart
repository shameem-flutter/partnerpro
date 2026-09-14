import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/redemption_response.dart';
import '../models/redemption_balance.dart';
import '../models/sales_report.dart';
import '../models/sales_agent_settings.dart';
import 'api_config.dart';

class RedemptionService {
  RedemptionService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<RedemptionResponse> convert({
    required String token,
    required double amount,
    required String currency,
  }) async {
    try {
      final convertUrl = await ApiConfig.getFullUrl('/api/v1/sales-agent-management/redemption/convert/');
      final response = await _dio.post<dynamic>(
        convertUrl,
        data: {
          'amount': amount.toStringAsFixed(2),
          'currency': currency,
        },
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $token',
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

      return RedemptionResponse.fromJson(normalized);
    } on DioException catch (e) {
      dynamic errorData = e.response?.data;
      if (errorData is String) {
        try {
          errorData = jsonDecode(errorData);
        } catch (_) {}
      }
      final responseBody = _normalizeMap(errorData);
      final defaultMsg = e.response != null
          ? 'Failed to convert redemption. Server returned status code ${e.response?.statusCode}.'
          : (e.message ?? 'Failed to convert redemption. Please try again.');
      final message = _extractErrorMessage(responseBody, defaultMsg);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to convert redemption: $e');
    }
  }

  Future<void> requestRedemption({
    required String token,
    required String accountNumber,
    required String accountName,
    required String country,
    required String ifscCode,
    required String amount,
    required String currency,
  }) async {
    try {
      final redemptionUrl = await ApiConfig.getFullUrl('/api/v1/sales-agent-management/redemption/');
      final parsedAmount = double.tryParse(amount) ?? 0.0;
      await _dio.post<dynamic>(
        redemptionUrl,
        data: {
          'account_number': accountNumber,
          'account_name': accountName,
          'country': country,
          'ifsc_code': ifscCode,
          'amount': parsedAmount,
          'currency': currency,
        },
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
    } on DioException catch (e) {
      dynamic errorData = e.response?.data;
      if (errorData is String) {
        try {
          errorData = jsonDecode(errorData);
        } catch (_) {}
      }
      final responseBody = _normalizeMap(errorData);
      final defaultMsg = e.response != null
          ? 'Failed to submit redemption request. Server returned status code ${e.response?.statusCode}.'
          : (e.message ?? 'Failed to submit redemption request. Please try again.');
      final message = _extractErrorMessage(responseBody, defaultMsg);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to submit redemption request: $e');
    }
  }

  Future<RedemptionBalanceResponse> getBalance({
    required String accessToken,
  }) async {
    try {
      final balanceUrl = await ApiConfig.getFullUrl('/api/v1/sales-agent-management/redemption/balance/');
      final response = await _dio.get<dynamic>(
        balanceUrl,
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

      return RedemptionBalanceResponse.fromJson(normalized);
    } on DioException catch (e) {
      dynamic errorData = e.response?.data;
      if (errorData is String) {
        try {
          errorData = jsonDecode(errorData);
        } catch (_) {}
      }
      final responseBody = _normalizeMap(errorData);
      final defaultMsg = e.response != null
          ? 'Failed to fetch redemption balance. Server returned status code ${e.response?.statusCode}.'
          : (e.message ?? 'Failed to fetch redemption balance. Please try again.');
      final message = _extractErrorMessage(responseBody, defaultMsg);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to fetch redemption balance: $e');
    }
  }

  Future<SalesReportResponse> getSalesReport({
    required String accessToken,
  }) async {
    try {
      final salesReportUrl = await ApiConfig.getFullUrl(
        '/api/v1/sales-agent-management/sales-report-no-balance/',
      );
      final response = await _dio.get<dynamic>(
        salesReportUrl,
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

      return SalesReportResponse.fromJson(normalized);
    } on DioException catch (e) {
      dynamic errorData = e.response?.data;
      if (errorData is String) {
        try {
          errorData = jsonDecode(errorData);
        } catch (_) {}
      }
      final responseBody = _normalizeMap(errorData);
      final defaultMsg = e.response != null
          ? 'Failed to fetch sales report. Server returned status code ${e.response?.statusCode}.'
          : (e.message ?? 'Failed to fetch sales report. Please try again.');
      final message = _extractErrorMessage(responseBody, defaultMsg);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to fetch sales report: $e');
    }
  }

  Future<SalesAgentSettings> getSettings({
    required String accessToken,
  }) async {
    try {
      final settingsUrl = await ApiConfig.getFullUrl('/api/v1/sales-agent-management/settings/');
      final response = await _dio.get<dynamic>(
        settingsUrl,
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

      return SalesAgentSettings.fromJson(normalized);
    } on DioException catch (e) {
      dynamic errorData = e.response?.data;
      if (errorData is String) {
        try {
          errorData = jsonDecode(errorData);
        } catch (_) {}
      }
      final responseBody = _normalizeMap(errorData);
      final defaultMsg = e.response != null
          ? 'Failed to fetch settings. Server returned status code ${e.response?.statusCode}.'
          : (e.message ?? 'Failed to fetch settings. Please try again.');
      final message = _extractErrorMessage(responseBody, defaultMsg);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to fetch settings: $e');
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

  String _extractErrorMessage(Map<String, dynamic>? responseBody, String defaultMessage) {
    if (responseBody == null) return defaultMessage;
    if (responseBody.containsKey('message')) {
      return responseBody['message'].toString();
    }
    if (responseBody.containsKey('error')) {
      return responseBody['error'].toString();
    }
    for (final entry in responseBody.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val is List && val.isNotEmpty) {
        return '$key: ${val.first}';
      }
      if (val is String && val.trim().isNotEmpty) {
        return '$key: $val';
      }
      if (val is Map) {
        return '$key: ${val.toString()}';
      }
    }
    return defaultMessage;
  }
}
