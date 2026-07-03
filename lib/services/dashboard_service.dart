import 'dart:convert';
import 'package:dio/dio.dart';
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

      final ordersListRaw = normalized['orders'] as List? ?? [];
      final List<Map<String, dynamic>> allOrdersJson = ordersListRaw
          .map((o) => _normalizeMap(o))
          .whereType<Map<String, dynamic>>()
          .toList();

      final directOrdersJson = allOrdersJson.where((o) {
        final refs = o['referral_details'] as List? ?? [];
        return refs.isEmpty;
      }).toList();

      final referralOrdersJson = allOrdersJson.where((o) {
        final refs = o['referral_details'] as List? ?? [];
        return refs.isNotEmpty;
      }).toList();

      double totalCommission = 0.0;
      for (final o in directOrdersJson) {
        totalCommission += _parseDouble(o['commission_amount_total']);
      }

      double totalCommissionRef = 0.0;
      for (final o in referralOrdersJson) {
        final refs = o['referral_details'] as List? ?? [];
        for (final r in refs) {
          totalCommissionRef += _parseDouble(r['commission_amount']);
        }
      }

      int approvedOrdersCount = directOrdersJson.where((o) => o['is_approved'] == true).length;
      int pendingOrdersCount = directOrdersJson.where((o) => o['is_approved'] == false).length;

      int refApprovedOrdersCount = referralOrdersJson.where((o) => o['is_approved'] == true).length;
      int refPendingOrdersCount = referralOrdersJson.where((o) => o['is_approved'] == false).length;

      final dashboardMap = <String, dynamic>{
        'orders': directOrdersJson,
        'referral_orders': referralOrdersJson,
        'today_date': DateTime.now().toIso8601String().split('T').first,
        'total_commission': totalCommission,
        'approved_orders_count': approvedOrdersCount,
        'pending_orders_count': pendingOrdersCount,
        'total_commission_ref': totalCommissionRef,
        'ref_approved_orders_count': refApprovedOrdersCount,
        'ref_pending_orders_count': refPendingOrdersCount,
      };

      return DashboardData.fromJson(dashboardMap);
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

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
