import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Added for compute
import '../models/dashboard_data.dart';
import '../models/view_more_data.dart';
import 'api_config.dart';

class DashboardService {
  DashboardService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<ViewMoreResponse> fetchViewMoreData(String accessToken) async {
    try {
      final viewMoreUrl = await ApiConfig.getFullUrl('/api/v1/dashboard/view-more/');
      final response = await _dio.get<dynamic>(
        viewMoreUrl,
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

      return ViewMoreResponse.fromJson(normalized);
    } on DioException catch (e) {
      String message = 'Failed to load view-more data. Please try again.';
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
        message = 'Failed to load view-more data. Server returned status code ${e.response?.statusCode}.';
      } else if (e.message != null) {
        message = e.message!;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to load view-more: $e');
    }
  }

  Future<DashboardData> fetchHomeData(String accessToken) async {
    try {
      final ordersUrl = await ApiConfig.getFullUrl('/api/v1/order-management/orders/');
      final referralOrdersUrl = await ApiConfig.getFullUrl('/api/v1/dashboard/referral-orders/');

      final headers = <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      final responses = await Future.wait([
        _dio.get<dynamic>(ordersUrl, options: Options(headers: headers)),
        _dio.get<dynamic>(referralOrdersUrl, options: Options(headers: headers)).catchError(
          (_) => Response(requestOptions: RequestOptions()),
        ),
      ]);

      dynamic rawOrdersData = responses[0].data;
      if (rawOrdersData is String) {
        rawOrdersData = jsonDecode(rawOrdersData);
      }
      final normalizedOrders = _normalizeMap(rawOrdersData) ?? {};

      dynamic rawRefData = responses[1].data;
      if (rawRefData is String) {
        rawRefData = jsonDecode(rawRefData);
      }
      final normalizedRef = _normalizeMap(rawRefData) ?? {};

      final combinedData = <String, dynamic>{
        ...normalizedOrders,
        ...normalizedRef,
      };

      // OFF-THREAD OPTIMIZATION:
      // Moving the heavy filtering, mapping, and object instantiation 
      // of 1,856+ items to a background isolate so the UI doesn't freeze.
      return await compute(_processDashboardData, combinedData);

    } on DioException catch (e) {
      String message = 'Failed to load dashboard data. Please try again.';
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
        message = 'Failed to load dashboard data. Server returned status code ${e.response?.statusCode}.';
      } else if (e.message != null) {
        message = e.message!;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to load dashboard: $e');
    }
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static Map<String, dynamic>? _normalizeMap(dynamic value) {
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

// Top-level function to run in a background isolate
DashboardData _processDashboardData(Map<String, dynamic> combinedData) {
  // Direct orders from /api/v1/order-management/orders/
  final ordersListRaw = combinedData['orders'] as List? ?? [];
  final List<Map<String, dynamic>> allOrdersJson = ordersListRaw
      .map((o) => DashboardService._normalizeMap(o))
      .whereType<Map<String, dynamic>>()
      .toList();

  final directOrdersJson = allOrdersJson.where((o) {
    final refs = o['referral_details'] as List? ?? [];
    return refs.isEmpty;
  }).toList();

  // Extract direct order metrics directly from API response if present
  final double totalCommission = combinedData.containsKey('total_commission')
      ? DashboardService._parseDouble(combinedData['total_commission'])
      : directOrdersJson
          .where((o) => o['is_approved'] == true)
          .fold(0.0, (sum, o) => sum + DashboardService._parseDouble(o['commission_amount_total']));

  final int approvedOrdersCount = combinedData.containsKey('approved_orders_count')
      ? (combinedData['approved_orders_count'] is int
          ? combinedData['approved_orders_count'] as int
          : int.tryParse(combinedData['approved_orders_count']?.toString() ?? '') ?? 0)
      : directOrdersJson.where((o) => o['is_approved'] == true).length;

  final int pendingOrdersCount = combinedData.containsKey('pending_orders_count')
      ? (combinedData['pending_orders_count'] is int
          ? combinedData['pending_orders_count'] as int
          : int.tryParse(combinedData['pending_orders_count']?.toString() ?? '') ?? 0)
      : directOrdersJson.where((o) => o['is_approved'] == false).length;

  // Referral orders from /api/v1/dashboard/referral-orders/
  final refOrdersListRaw = combinedData['referral_orders'] as List? ?? [];
  final List<Map<String, dynamic>> referralOrdersJson = refOrdersListRaw
      .map((o) => DashboardService._normalizeMap(o))
      .whereType<Map<String, dynamic>>()
      .toList();

  final double totalCommissionRef = DashboardService._parseDouble(
    combinedData['total_commission_ref'],
  );

  final int refApprovedOrdersCount = combinedData['ref_approved_orders_count'] is int
      ? combinedData['ref_approved_orders_count'] as int
      : int.tryParse(combinedData['ref_approved_orders_count']?.toString() ?? '') ?? 0;

  final int refPendingOrdersCount = combinedData['ref_pending_orders_count'] is int
      ? combinedData['ref_pending_orders_count'] as int
      : int.tryParse(combinedData['ref_pending_orders_count']?.toString() ?? '') ?? 0;

  final String todayDate = combinedData['today_date']?.toString().isNotEmpty == true
      ? combinedData['today_date'].toString()
      : DateTime.now().toIso8601String().split('T').first;

  final dashboardMap = <String, dynamic>{
    'orders': directOrdersJson,
    'referral_orders': referralOrdersJson,
    'today_date': todayDate,
    'total_commission': totalCommission,
    'approved_orders_count': approvedOrdersCount,
    'pending_orders_count': pendingOrdersCount,
    'total_commission_ref': totalCommissionRef,
    'ref_approved_orders_count': refApprovedOrdersCount,
    'ref_pending_orders_count': refPendingOrdersCount,
  };

  return DashboardData.fromJson(dashboardMap);
}
