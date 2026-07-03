import 'dashboard_data.dart';

// ---------------------------------------------------------------------------
// Admin Month Orders
// ---------------------------------------------------------------------------

class AdminMonthOrders {
  const AdminMonthOrders({
    required this.monthName,
    required this.orders,
    required this.totalAmount,
    required this.orderCount,
  });

  final String monthName;
  final List<DashboardOrder> orders;
  final double totalAmount;
  final int orderCount;
}

// ---------------------------------------------------------------------------
// Salesperson
// ---------------------------------------------------------------------------

class Salesperson {
  const Salesperson({
    required this.salespersonId,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String? salespersonId; // can be null or "False"
  final String firstName;
  final String lastName;
  final String email;

  String get displayName => '$firstName $lastName'.trim();

  /// Returns the ID suitable for API query params. Returns null if not set.
  String? get validId {
    if (salespersonId == null ||
        salespersonId == 'null' ||
        salespersonId == 'False' ||
        salespersonId!.trim().isEmpty) {
      return null;
    }
    return salespersonId;
  }

  factory Salesperson.fromJson(Map<String, dynamic> json) {
    final rawName = json['salesperson_name']?.toString();
    String first = json['first_name']?.toString() ?? '';
    String last = json['last_name']?.toString() ?? '';
    if (first.isEmpty && last.isEmpty && rawName != null && rawName.isNotEmpty) {
      first = rawName;
    }
    return Salesperson(
      salespersonId: json['salesperson_id']?.toString(),
      firstName: first,
      lastName: last,
      email: json['email']?.toString() ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// All Salesperson Orders Response
// ---------------------------------------------------------------------------

class AllSalespersonOrdersResponse {
  const AllSalespersonOrdersResponse({
    required this.salespersons,
    required this.ordersByMonth,
    required this.selectedSalespersonId,
    required this.availablePlatforms,
    required this.totalDebit,
    required this.totalCredit,
    required this.totalBalance,
  });

  final List<Salesperson> salespersons;
  final List<AdminMonthOrders> ordersByMonth;
  final String selectedSalespersonId;
  final List<String> availablePlatforms;
  final double totalDebit;
  final double totalCredit;
  final double totalBalance;

  factory AllSalespersonOrdersResponse.fromJson(Map<String, dynamic> json) {
    final salespersonsRaw = json['salespersons'] as List? ?? [];
    final salespersons = salespersonsRaw
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

    final platformsRaw = json['available_platforms'] as List? ?? [];
    final platforms = platformsRaw.map((e) => e.toString()).toList();

    final List<AdminMonthOrders> ordersByMonthList = [];
    final Map<dynamic, dynamic>? ordersByMonthRaw = json['orders_by_month'] as Map<dynamic, dynamic>?;

    if (ordersByMonthRaw != null) {
      ordersByMonthRaw.forEach((dynamic monthKey, dynamic value) {
        if (value is Map) {
          final ordersRaw = value['orders'] as List? ?? [];
          final orders = ordersRaw.map((o) {
            final Map<dynamic, dynamic> oMap = o is Map ? o : {};
            return DashboardOrder.fromJson(oMap);
          }).toList();

          final totalAmount = _parseDouble(value['total_amount'] ?? value['approved_total']);
          final orderCount = _parseInt(value['order_count'] ?? value['approved_count']);

          ordersByMonthList.add(AdminMonthOrders(
            monthName: monthKey?.toString() ?? '',
            orders: orders,
            totalAmount: totalAmount,
            orderCount: orderCount,
          ));
        }
      });
    }

    return AllSalespersonOrdersResponse(
      salespersons: salespersons,
      ordersByMonth: ordersByMonthList,
      selectedSalespersonId:
          json['selected_salesperson_id']?.toString() ?? '',
      availablePlatforms: platforms,
      totalDebit: _parseDouble(json['total_debit']),
      totalCredit: _parseDouble(json['total_credit']),
      totalBalance: _parseDouble(json['total_balance']),
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

// ---------------------------------------------------------------------------
class AllReferralOrdersResponse {
  const AllReferralOrdersResponse({
    required this.orders,
    this.totalDebit,
    this.totalCredit,
    this.totalBalance,
    required this.salespersons,
    this.selectedSalespersonId,
  });

  final List<AdminReferralOrder> orders;
  final double? totalDebit;
  final double? totalCredit;
  final double? totalBalance;
  final List<Salesperson> salespersons;
  final String? selectedSalespersonId;
}

class AdminReferralOrder {
  const AdminReferralOrder({
    this.id,
    required this.invoiceDate,
    required this.platform,
    required this.invoiceReferenceNo,
    required this.customerName,
    required this.salespersonName,
    required this.companyName,
    required this.currency,
    required this.commissionAmountTotal,
    required this.isApproved,
    required this.referralDetails,
  });

  final int? id;
  final String invoiceDate;
  final String platform;
  final String invoiceReferenceNo;
  final String customerName;
  final String salespersonName;
  final String companyName;
  final String currency;
  final double commissionAmountTotal;
  final bool isApproved;
  final List<AdminReferralDetail> referralDetails;

  factory AdminReferralOrder.fromJson(Map<String, dynamic> json) {
    final refRaw = json['referral_details'] as List? ?? [];
    final refs = refRaw
        .map((e) {
          if (e is Map<String, dynamic>) return AdminReferralDetail.fromJson(e);
          if (e is Map) {
            return AdminReferralDetail.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            );
          }
          return null;
        })
        .whereType<AdminReferralDetail>()
        .toList();

    // Fallback parsing for fields that might have different names when filtering by salesperson
    double commissionTotal = _parseDouble(json['commission_amount_total']);
    if (commissionTotal == 0.0 && json.containsKey('commission_amount')) {
      commissionTotal = _parseDouble(json['commission_amount']);
    }

    final String salespersonId = json['salesperson_id']?.toString() ?? '';
    final String salespersonName = json['salesperson_name']?.toString() ?? '';
    final String salespersonEmail = json['salesperson_email']?.toString() ?? '';
    final String type = json['type']?.toString() ?? '';
    final String percentage = json['percentage']?.toString() ?? '';

    String refNo = json['invoice_reference_no']?.toString() ?? '';
    if (refNo.isEmpty && salespersonId.isNotEmpty) {
      refNo = salespersonId;
    }

    String customer = json['customer_name']?.toString() ?? '';
    if (customer.isEmpty && salespersonName.isNotEmpty) {
      customer = salespersonName;
    }

    String platformVal = json['platform']?.toString() ?? '';
    if (platformVal.isEmpty && type.isNotEmpty) {
      if (type == 'percentage' && percentage.isNotEmpty) {
        final double? pVal = double.tryParse(percentage);
        final String pStr = pVal != null ? (pVal % 1 == 0 ? pVal.toInt().toString() : pVal.toStringAsFixed(1)) : percentage;
        platformVal = 'Percentage ($pStr%)';
      } else {
        platformVal = type;
      }
    }

    // If referralDetails list is empty, but we have a valid salesperson commission detail here,
    // we can create a single fallback referral detail to show in the list/bottom-sheet.
    if (refs.isEmpty && salespersonId.isNotEmpty) {
      refs.add(
        AdminReferralDetail(
          salespersonId: salespersonId,
          salespersonName: salespersonName,
          salespersonEmail: salespersonEmail,
          type: type,
          percentage: _parseDouble(percentage),
          fixedAmount: _parseDouble(json['fixed_amount']),
          currency: json['currency']?.toString() ?? '',
          commissionAmount: commissionTotal,
        ),
      );
    }

    return AdminReferralOrder(
      id: json['id'] is int ? json['id'] as int : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      invoiceDate: json['invoice_date']?.toString() ?? '',
      platform: platformVal,
      invoiceReferenceNo: refNo,
      customerName: customer,
      salespersonName: salespersonName,
      companyName: json['company_name']?.toString() ?? salespersonEmail,
      currency: json['currency']?.toString() ?? '',
      commissionAmountTotal: commissionTotal,
      isApproved:
          json['is_approved'] as bool? ??
          json['is_approve'] as bool? ??
          false,
      referralDetails: refs,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class AdminReferralDetail {
  const AdminReferralDetail({
    required this.salespersonId,
    required this.salespersonName,
    required this.salespersonEmail,
    required this.type,
    required this.percentage,
    required this.fixedAmount,
    required this.currency,
    required this.commissionAmount,
  });

  final String salespersonId;
  final String salespersonName;
  final String salespersonEmail;
  final String type;
  final double percentage;
  final double fixedAmount;
  final String currency;
  final double commissionAmount;

  factory AdminReferralDetail.fromJson(Map<String, dynamic> json) {
    return AdminReferralDetail(
      salespersonId: json['salesperson_id']?.toString() ?? '',
      salespersonName: json['salesperson_name']?.toString() ?? '',
      salespersonEmail: json['salesperson_email']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      percentage: _parseDouble(json['percentage']),
      fixedAmount: _parseDouble(json['fixed_amount']),
      currency: json['currency']?.toString() ?? '',
      commissionAmount: _parseDouble(json['commission_amount']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// ---------------------------------------------------------------------------
// Sales Report (Incentive Report)
// ---------------------------------------------------------------------------

class SalesReportEntry {
  const SalesReportEntry({
    required this.invoiceDate,
    required this.invoiceReferenceNo,
    required this.customerName,
    required this.platform,
    required this.totalAmount,
    required this.commissionAmount,
    required this.currency,
    required this.isApproved,
    required this.debit,
    required this.balance,
  });

  final String invoiceDate;
  final String invoiceReferenceNo;
  final String customerName;
  final String platform;
  final double totalAmount;
  final double commissionAmount;
  final String currency;
  final bool isApproved;
  final double debit;
  final double balance;

  factory SalesReportEntry.fromJson(Map<String, dynamic> json) {
    final creditVal = _parseDouble(json['credit'] ?? json['commission_amount']);
    final isApp = json['is_approved'] as bool? ??
        json['is_approve'] as bool? ??
        (creditVal > 0);
    return SalesReportEntry(
      invoiceDate: json['invoice_date']?.toString() ?? '',
      invoiceReferenceNo: json['invoice_reference_no']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      totalAmount: _parseDouble(json['currency_amount'] ?? json['total_amount']),
      commissionAmount: creditVal,
      currency: json['currency']?.toString() ?? 'AED',
      isApproved: isApp,
      debit: _parseDouble(json['debit']),
      balance: _parseDouble(json['balance']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class SalesReportResponse {
  const SalesReportResponse({
    required this.entries,
    required this.totalCommission,
    required this.totalAmount,
    required this.totalDebit,
    required this.salespersonName,
    required this.salespersonId,
  });

  final List<SalesReportEntry> entries;
  final double totalCommission;
  final double totalAmount;
  final double totalDebit;
  final String salespersonName;
  final String salespersonId;

  factory SalesReportResponse.fromJson(Map<String, dynamic> json) {
    final ordersRaw = (json['sales_report'] ?? json['orders']) as List? ?? [];
    final entries = ordersRaw
        .map((e) {
          final m = e is Map<String, dynamic>
              ? e
              : (e is Map ? e.map((k, v) => MapEntry(k.toString(), v)) : null);
          return m != null ? SalesReportEntry.fromJson(m) : null;
        })
        .whereType<SalesReportEntry>()
        .toList();

    return SalesReportResponse(
      entries: entries,
      totalCommission: _parseDouble(json['total_credit'] ?? json['total_commission']),
      totalAmount: _parseDouble(json['total_balance'] ?? json['total_amount']),
      totalDebit: _parseDouble(json['total_debit']),
      salespersonName: json['salesperson_name']?.toString() ?? '',
      salespersonId: json['salesperson_id']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
