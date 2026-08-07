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
    this.id,
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

  final int? id;
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

    double commSum = 0.0;
    for (var d in parsedDetails) {
      commSum += d.commissionAmount;
    }
    double parsedComm = _parseDouble(json['commission_amount_total'] ?? json['total_commission'] ?? json['commission'] ?? json['approved_total'] ?? json['commission_amount'] ?? json['commission_earned'] ?? json['earned_commission'] ?? json['approved_commission']);
    if (parsedComm == 0.0) {
      parsedComm = commSum;
    }

    String refNo = json['invoice_reference_no']?.toString() ?? json['name']?.toString() ?? '';
    if (refNo.isEmpty && json['id'] != null) {
      refNo = 'Ref #${json['id']}';
    }

    return DashboardOrder(
      id: json['id'] is int ? json['id'] as int : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      invoiceDate: json['invoice_date']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      invoiceReferenceNo: refNo,
      customerName: json['customer_name']?.toString() ?? '',
      salespersonName: json['salesperson_name']?.toString() ?? json['salesperson_email']?.toString() ?? json['salesperson_id']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      invoiceDetails: parsedDetails,
      referralDetails: parsedReferrals,
      commissionAmountTotal: parsedComm,
      isApproved: json['is_approved'] as bool? ?? json['is_approve'] as bool? ?? false,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      String cleaned = value.replaceAll('%', '').replaceAll(',', '').trim();
      return double.tryParse(cleaned) ?? 0.0;
    }
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
    this.id,
    this.invoiceName,
    this.invoiceDate,
    this.paymentState,
    this.amountTotal,
    this.commissionPercentage,
    this.commissionAmount = 0.0,
  });

  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final bool isApproved;
  final int? id;
  final String? invoiceName;
  final String? invoiceDate;
  final String? paymentState;
  final double? amountTotal;
  final double? commissionPercentage;
  final double commissionAmount;

  factory InvoiceDetail.fromJson(Map<dynamic, dynamic> json) {
    final double commAmount = _parseDouble(json['commission_amount'] ?? json['commission'] ?? json['approved_commission'] ?? json['total_commission']);
    final double amtTotal = _parseDouble(json['amount_total']);
    return InvoiceDetail(
      productName: json['product_name']?.toString() ?? json['invoice_name']?.toString() ?? '',
      quantity: _parseInt(json['quantity'] ?? 1),
      unitPrice: _parseDouble(json['unit_price'] ?? json['amount_total']),
      subtotal: _parseDouble(json['subtotal'] ?? json['amount_total']),
      isApproved: json['is_approved'] as bool? ?? json['is_approve'] as bool? ?? false,
      id: _parseInt(json['id']),
      invoiceName: json['invoice_name']?.toString(),
      invoiceDate: json['invoice_date']?.toString(),
      paymentState: json['payment_state']?.toString(),
      amountTotal: amtTotal,
      commissionPercentage: _parseDouble(json['commission_percentage']),
      commissionAmount: commAmount,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      String cleaned = value.replaceAll('%', '').replaceAll(',', '').trim();
      return double.tryParse(cleaned) ?? 0.0;
    }
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
