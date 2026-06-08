import 'dashboard_data.dart';

class ViewMoreMonth {
  const ViewMoreMonth({
    required this.monthName,
    required this.orders,
    required this.approvedTotal,
    required this.approvedCount,
  });

  final String monthName;
  final List<DashboardOrder> orders;
  final double approvedTotal;
  final int approvedCount;
}

class ViewMoreResponse {
  const ViewMoreResponse({
    required this.months,
    required this.availablePlatforms,
  });

  final List<ViewMoreMonth> months;
  final List<String> availablePlatforms;

  factory ViewMoreResponse.fromJson(Map<dynamic, dynamic> json) {
    final List<ViewMoreMonth> monthsList = [];
    final Map<dynamic, dynamic>? ordersByMonthRaw = json['orders_by_month'] as Map<dynamic, dynamic>?;

    if (ordersByMonthRaw != null) {
      ordersByMonthRaw.forEach((dynamic monthKey, dynamic value) {
        if (value is Map) {
          final ordersRaw = value['orders'] as List? ?? [];
          final orders = ordersRaw.map((o) {
            // Some keys might vary; we normalize them to DashboardOrder's expectations
            final Map<dynamic, dynamic> oMap = o is Map ? o : {};
            return DashboardOrder.fromJson(oMap);
          }).toList();

          final approvedTotal = _parseDouble(value['approved_total']);
          final approvedCount = _parseInt(value['approved_count']);

          monthsList.add(ViewMoreMonth(
            monthName: monthKey?.toString() ?? '',
            orders: orders,
            approvedTotal: approvedTotal,
            approvedCount: approvedCount,
          ));
        }
      });
    }

    final platformsRaw = json['available_platforms'] as List? ?? [];
    final availablePlatforms = platformsRaw.map((p) => p.toString()).toList();

    return ViewMoreResponse(
      months: monthsList,
      availablePlatforms: availablePlatforms,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
