import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';
import 'api_config.dart';

// ---------------------------------------------------------------------------
// Exception types
// ---------------------------------------------------------------------------

/// Thrown when the server responds with a permission-denied error body,
/// e.g. {"error": "You do not have permission to view ..."}
class PermissionDeniedException implements Exception {
  const PermissionDeniedException(this.message);

  final String message;

  @override
  String toString() => 'PermissionDeniedException: $message';
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Service for all Admin-specific API endpoints.
/// All requests go to [ApiConfig.adminBaseUrl].
class AdminService {
  AdminService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  // --------------------------------------------------------------------------
  // 1. All Salesperson Orders
  //    GET /api/v1/dashboard/all-salesperson-orders/?salesperson_id=<id>
  // --------------------------------------------------------------------------

  Future<AllSalespersonOrdersResponse> fetchAllSalespersonOrders(
    String accessToken, {
    String? salespersonId,
  }) async {
    try {
      final url = await ApiConfig.getAdminFullUrl(
        '/api/v1/dashboard/all-salesperson-orders/',
      );

      final queryParams = <String, dynamic>{};
      if (salespersonId != null && salespersonId.isNotEmpty) {
        queryParams['salesperson_id'] = salespersonId;
      }

      final response = await _dio.get<dynamic>(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      dynamic rawData = response.data;
      if (rawData is String) rawData = jsonDecode(rawData);

      // Check for permission-denied inside a 200 body
      _checkPermissionError(rawData);

      final normalized = _normalizeMap(rawData);
      if (normalized == null) {
        throw Exception('Invalid response format from server');
      }
      return AllSalespersonOrdersResponse.fromJson(normalized);
    } on PermissionDeniedException {
      rethrow;
    } on DioException catch (e) {
      _checkPermissionErrorFromDio(e);
      throw Exception(
        _extractDioError(e, 'Failed to load salesperson orders'),
      );
    } catch (e) {
      if (e is PermissionDeniedException) rethrow;
      throw Exception('Failed to load salesperson orders: $e');
    }
  }

  // --------------------------------------------------------------------------
  // 2. Sales Report (Incentive Report)
  //    GET /api/v1/sales-agent-management/sales-report/?salesperson_id=<id>
  // --------------------------------------------------------------------------

  Future<SalesReportResponse> fetchSalesReport(
    String accessToken, {
    String? salespersonId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final String path =
          '/api/v1/sales-agent-management/sales-report-no-balance/';

      final url = await ApiConfig.getAdminFullUrl(path);

      final Map<String, dynamic> queryParams = {};
      if (salespersonId != null && salespersonId.isNotEmpty) {
        queryParams['salesperson_id'] = salespersonId;
      }
      if (fromDate != null && toDate != null) {
        queryParams['from_date'] = fromDate;
        queryParams['to_date'] = toDate;
      }

      final response = await _dio.get<dynamic>(
        url,
        queryParameters: queryParams,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      dynamic rawData = response.data;
      if (rawData is String) rawData = jsonDecode(rawData);

      _checkPermissionError(rawData);

      final normalized = _normalizeMap(rawData);
      if (normalized == null) {
        throw Exception('Invalid response format from server');
      }
      return SalesReportResponse.fromJson(normalized);
    } on PermissionDeniedException {
      rethrow;
    } on DioException catch (e) {
      _checkPermissionErrorFromDio(e);
      throw Exception(_extractDioError(e, 'Failed to load sales report'));
    } catch (e) {
      if (e is PermissionDeniedException) rethrow;
      throw Exception('Failed to load sales report: $e');
    }
  }

  // --------------------------------------------------------------------------
  // 3. All Referral Orders
  //    GET /api/v1/dashboard/all-referral-orders/
  // --------------------------------------------------------------------------

  Future<AllReferralOrdersResponse> fetchAllReferralOrders(
    String accessToken, {
    String? salespersonId,
  }) async {
    try {
      final url = await ApiConfig.getAdminFullUrl(
        '/api/v1/dashboard/all-referral-orders/',
      );

      final queryParams = <String, dynamic>{};
      if (salespersonId != null && salespersonId.isNotEmpty) {
        queryParams['salesperson_id'] = salespersonId;
      }

      final response = await _dio.get<dynamic>(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      dynamic rawData = response.data;
      if (rawData is String) rawData = jsonDecode(rawData);

      _checkPermissionError(rawData);

      List<dynamic> ordersList = [];
      double? totalDebit;
      double? totalCredit;
      double? totalBalance;
      List<Salesperson> salespersons = [];
      String? selectedSalespersonId;

      if (rawData is List) {
        ordersList = rawData;
      } else if (rawData is Map) {
        final normalized = _normalizeMap(rawData);
        final key = normalized?.containsKey('orders') == true
            ? 'orders'
            : normalized?.containsKey('referral_orders') == true
                ? 'referral_orders'
                : null;
        if (key != null) {
          ordersList = normalized![key] as List? ?? [];
        }
        totalDebit = _parseNullableDouble(normalized?['total_debit']);
        totalCredit = _parseNullableDouble(normalized?['total_credit']);
        totalBalance = _parseNullableDouble(normalized?['total_balance']);

        final salespersonsRaw = (normalized?['ref_salespersons'] ?? normalized?['salespersons']) as List? ?? [];
        salespersons = salespersonsRaw
            .map((e) {
              if (e is Map<String, dynamic>) return Salesperson.fromJson(e);
              if (e is Map) {
                return Salesperson.fromJson(
                  e.map((k, v) => MapEntry(k.toString(), v)),
                );
              }
              return null;
            })
            .whereType<Salesperson>()
            .toList();

        selectedSalespersonId = normalized?['selected_salesperson_id']?.toString();
      }

      final orders = ordersList
          .map((e) {
            final m = e is Map<String, dynamic>
                ? e
                : (e is Map
                    ? e.map((k, v) => MapEntry(k.toString(), v))
                    : null);
            return m != null ? AdminReferralOrder.fromJson(m) : null;
          })
          .whereType<AdminReferralOrder>()
          .toList();

      return AllReferralOrdersResponse(
        orders: orders,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        totalBalance: totalBalance,
        salespersons: salespersons,
        selectedSalespersonId: selectedSalespersonId,
      );
    } on PermissionDeniedException {
      rethrow;
    } on DioException catch (e) {
      _checkPermissionErrorFromDio(e);
      throw Exception(_extractDioError(e, 'Failed to load referral orders'));
    } catch (e) {
      if (e is PermissionDeniedException) rethrow;
      throw Exception('Failed to load referral orders: $e');
    }
  }

  double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // --------------------------------------------------------------------------
  // 4. Submit Selected Invoices (Approve Invoices)
  //    POST /api/v1/dashboard/submit-selected-invoices/
  // --------------------------------------------------------------------------

  Future<void> submitSelectedInvoices(
    String accessToken,
    List<Map<String, dynamic>> selectedInvoices,
  ) async {
    try {
      final url = await ApiConfig.getAdminFullUrl(
        '/api/v1/dashboard/submit-selected-invoices/',
      );

      final response = await _dio.post<dynamic>(
        url,
        data: {
          'selectedInvoices': selectedInvoices,
        },
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      dynamic rawData = response.data;
      if (rawData is String) rawData = jsonDecode(rawData);

      _checkPermissionError(rawData);
    } on PermissionDeniedException {
      rethrow;
    } on DioException catch (e) {
      _checkPermissionErrorFromDio(e);
      throw Exception(
        _extractDioError(e, 'Failed to approve selected invoices'),
      );
    } catch (e) {
      if (e is PermissionDeniedException) rethrow;
      throw Exception('Failed to approve selected invoices: $e');
    }
  }

  // --------------------------------------------------------------------------
  // 5. Submit Referral Approvals (Approve Referral Orders)
  //    POST /api/v1/dashboard/submit-referral-approvals/
  // --------------------------------------------------------------------------

  Future<void> submitReferralApprovals(
    String accessToken,
    List<Map<String, dynamic>> selectedReferrals,
  ) async {
    try {
      final url = await ApiConfig.getAdminFullUrl(
        '/api/v1/dashboard/submit-referral-approvals/',
      );

      final response = await _dio.post<dynamic>(
        url,
        data: {
          'selectedReferrals': selectedReferrals,
        },
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      dynamic rawData = response.data;
      if (rawData is String) rawData = jsonDecode(rawData);

      _checkPermissionError(rawData);
    } on PermissionDeniedException {
      rethrow;
    } on DioException catch (e) {
      _checkPermissionErrorFromDio(e);
      throw Exception(
        _extractDioError(e, 'Failed to approve selected referrals'),
      );
    } catch (e) {
      if (e is PermissionDeniedException) rethrow;
      throw Exception('Failed to approve selected referrals: $e');
    }
  }

  /// Checks whether a successful (2xx) response body contains a
  /// `{"error": "You do not have permission ..."}` field and throws
  /// [PermissionDeniedException] if so.
  void _checkPermissionError(dynamic rawData) {
    if (rawData is! Map) return;
    final body = _normalizeMap(rawData);
    final error = body?['error']?.toString() ?? '';
    if (error.isNotEmpty) {
      debugPrint('🚫 [AdminService] Permission denied: $error');
      throw PermissionDeniedException(error);
    }
  }

  /// Same check but for DioException error response bodies
  /// (e.g. HTTP 403 with {"error": "..."}).
  void _checkPermissionErrorFromDio(DioException e) {
    dynamic errorData = e.response?.data;
    if (errorData is String) {
      try {
        errorData = jsonDecode(errorData);
      } catch (_) {}
    }
    final body = _normalizeMap(errorData);
    final error = body?['error']?.toString() ?? '';
    if (error.isNotEmpty) {
      debugPrint('🚫 [AdminService] Permission denied (Dio): $error');
      throw PermissionDeniedException(error);
    }
  }

  Map<String, dynamic>? _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  String _extractDioError(DioException e, String fallback) {
    dynamic errorData = e.response?.data;
    if (errorData is String) {
      try {
        errorData = jsonDecode(errorData);
      } catch (_) {}
    }
    final body = _normalizeMap(errorData);
    return body?['error']?.toString() ??
        body?['message']?.toString() ??
        (e.response != null
            ? '$fallback. Status ${e.response?.statusCode}.'
            : e.message ?? fallback);
  }
}
