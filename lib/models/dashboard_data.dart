class DashboardData {
  const DashboardData({
    required this.orders,
    required this.todayDate,
    required this.totalCommission,
    required this.approvedOrdersCount,
    required this.pendingOrdersCount,
    required this.totalCommissionRef,
    required this.refApprovedOrdersCount,
    required this.refPendingOrdersCount,
    required this.referralOrders,
  });

  final List<DashboardOrder> orders;
  final String todayDate;
  final double totalCommission;
  final int approvedOrdersCount;
  final int pendingOrdersCount;
  final double totalCommissionRef;
  final int refApprovedOrdersCount;
  final int refPendingOrdersCount;
  final List<DashboardOrder> referralOrders;

  factory DashboardData.fromJson(Map<dynamic, dynamic> json) {
    var ordersList = json['orders'] as List? ?? [];
    List<DashboardOrder> parsedOrders =
        ordersList.map((o) => DashboardOrder.fromJson(o)).toList();

    var refOrdersList = json['referral_orders'] as List? ?? [];
    List<DashboardOrder> parsedRefOrders =
        refOrdersList.map((o) => DashboardOrder.fromJson(o)).toList();

    return DashboardData(
      orders: parsedOrders,
      todayDate: json['today_date']?.toString() ?? '',
      totalCommission: _parseDouble(json['total_commission']),
      approvedOrdersCount: _parseInt(json['approved_orders_count']),
      pendingOrdersCount: _parseInt(json['pending_orders_count']),
      totalCommissionRef: _parseDouble(json['total_commission_ref']),
      refApprovedOrdersCount: _parseInt(json['ref_approved_orders_count']),
      refPendingOrdersCount: _parseInt(json['ref_pending_orders_count']),
      referralOrders: parsedRefOrders,
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

class DashboardOrder {
  const DashboardOrder({
    required this.invoiceDate,
    required this.platform,
    required this.invoiceReferenceNo,
    required this.customerName,
    required this.salespersonName,
    required this.companyName,
    required this.currency,
    required this.invoiceDetails,
    required this.referralDetails,
    required this.commissionAmountTotal,
    required this.isApproved,
  });

  final String invoiceDate;
  final String platform;
  final String invoiceReferenceNo;
  final String customerName;
  final String salespersonName;
  final String companyName;
  final String currency;
  final List<InvoiceDetail> invoiceDetails;
  final List<ReferralDetail> referralDetails;
  final double commissionAmountTotal;
  final bool isApproved;

  double get totalSubtotal {
    return invoiceDetails.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  factory DashboardOrder.fromJson(Map<dynamic, dynamic> json) {
    var detailsList = (json['invoice_details'] ?? json['invoice_delails']) as List? ?? [];
    List<InvoiceDetail> parsedDetails =
        detailsList.map((d) => InvoiceDetail.fromJson(d)).toList();

    var referralsList = json['referral_details'] as List? ?? [];
    List<ReferralDetail> parsedReferrals =
        referralsList.map((r) => ReferralDetail.fromJson(r)).toList();

    return DashboardOrder(
      invoiceDate: json['invoice_date']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      invoiceReferenceNo: json['invoice_reference_no']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      salespersonName: json['salesperson_name']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      invoiceDetails: parsedDetails,
      referralDetails: parsedReferrals,
      commissionAmountTotal: _parseDouble(json['commission_amount_total']),
      isApproved: json['is_approved'] as bool? ?? json['is_approve'] as bool? ?? false,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class InvoiceDetail {
  const InvoiceDetail({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.isApproved,
  });

  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final bool isApproved;

  factory InvoiceDetail.fromJson(Map<dynamic, dynamic> json) {
    return InvoiceDetail(
      productName: json['product_name']?.toString() ?? '',
      quantity: _parseInt(json['quantity']),
      unitPrice: _parseDouble(json['unit_price']),
      subtotal: _parseDouble(json['subtotal']),
      isApproved: json['is_approved'] as bool? ?? json['is_approve'] as bool? ?? false,
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

class ReferralDetail {
  const ReferralDetail({
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

  factory ReferralDetail.fromJson(Map<dynamic, dynamic> json) {
    return ReferralDetail(
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
