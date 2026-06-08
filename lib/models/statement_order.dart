class StatementOrderResponse {
  final int count;
  final List<StatementOrder> orders;

  StatementOrderResponse({required this.count, required this.orders});

  factory StatementOrderResponse.fromJson(Map<String, dynamic> json) {
    final list = json['orders'] as List? ?? [];
    final parsedOrders = list.map((item) => StatementOrder.fromJson(item)).toList();
    return StatementOrderResponse(
      count: json['count'] as int? ?? 0,
      orders: parsedOrders,
    );
  }
}

class StatementOrder {
  final int id;
  final String invoiceReferenceNo;
  final String invoiceDate;
  final String platform;
  final String currency;
  final String customerName;
  final String salespersonName;
  final String companyName;
  final bool isApproved;
  final double commissionAmountTotal;
  final double defaultCommissionPercentage;
  final String createdAt;
  final String updatedAt;
  final List<StatementInvoiceDetail> invoiceDetails;

  StatementOrder({
    required this.id,
    required this.invoiceReferenceNo,
    required this.invoiceDate,
    required this.platform,
    required this.currency,
    required this.customerName,
    required this.salespersonName,
    required this.companyName,
    required this.isApproved,
    required this.commissionAmountTotal,
    required this.defaultCommissionPercentage,
    required this.createdAt,
    required this.updatedAt,
    required this.invoiceDetails,
  });

  factory StatementOrder.fromJson(Map<String, dynamic> json) {
    final detailsList = json['invoice_details'] as List? ?? [];
    final parsedDetails = detailsList.map((d) => StatementInvoiceDetail.fromJson(d)).toList();

    return StatementOrder(
      id: json['id'] as int? ?? 0,
      invoiceReferenceNo: json['invoice_reference_no']?.toString() ?? '',
      invoiceDate: json['invoice_date']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      salespersonName: json['salesperson_name']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      isApproved: json['is_approved'] as bool? ?? false,
      commissionAmountTotal: _parseDouble(json['commission_amount_total']),
      defaultCommissionPercentage: _parseDouble(json['default_commission_percentage']),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      invoiceDetails: parsedDetails,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class StatementInvoiceDetail {
  final int id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final double commissionPercentage;
  final double commissionAmount;
  final bool isApproved;

  StatementInvoiceDetail({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.commissionPercentage,
    required this.commissionAmount,
    required this.isApproved,
  });

  factory StatementInvoiceDetail.fromJson(Map<String, dynamic> json) {
    return StatementInvoiceDetail(
      id: json['id'] as int? ?? 0,
      productName: json['product_name']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: _parseDouble(json['unit_price']),
      subtotal: _parseDouble(json['subtotal']),
      commissionPercentage: _parseDouble(json['commission_percentage']),
      commissionAmount: _parseDouble(json['commission_amount']),
      isApproved: json['is_approved'] as bool? ?? false,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
