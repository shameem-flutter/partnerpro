class SalesReportResponse {
  final List<SalesReportItem> salesReport;
  final String totalDebit;
  final String totalCredit;
  final String totalBalance;

  SalesReportResponse({
    required this.salesReport,
    required this.totalDebit,
    required this.totalCredit,
    required this.totalBalance,
  });

  factory SalesReportResponse.fromJson(Map<String, dynamic> json) {
    var list = json['sales_report'] as List? ?? [];
    List<SalesReportItem> reportItems =
        list.map((i) => SalesReportItem.fromJson(i as Map<String, dynamic>)).toList();

    return SalesReportResponse(
      salesReport: reportItems,
      totalDebit: json['total_debit']?.toString() ?? '0.00',
      totalCredit: json['total_credit']?.toString() ?? '0.00',
      totalBalance: json['total_balance']?.toString() ?? '0.00',
    );
  }
}

class SalesReportItem {
  final int id;
  final String invoiceDate;
  final String invoiceReferenceNo;
  final String customerName;
  final String platform;
  final String currency;
  final String currencyAmount;
  final String debit;
  final String credit;
  final String balance;

  SalesReportItem({
    required this.id,
    required this.invoiceDate,
    required this.invoiceReferenceNo,
    required this.customerName,
    required this.platform,
    required this.currency,
    required this.currencyAmount,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  factory SalesReportItem.fromJson(Map<String, dynamic> json) {
    return SalesReportItem(
      id: json['id'] as int? ?? 0,
      invoiceDate: json['invoice_date']?.toString() ?? '',
      invoiceReferenceNo: json['invoice_reference_no']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      currencyAmount: json['currency_amount']?.toString() ?? '0.00',
      debit: json['debit']?.toString() ?? '0.00',
      credit: json['credit']?.toString() ?? '0.00',
      balance: json['balance']?.toString() ?? '0.00',
    );
  }
}
