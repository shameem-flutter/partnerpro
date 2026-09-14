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

    final calculatedItems = _calculateRunningBalances(reportItems);

    return SalesReportResponse(
      salesReport: calculatedItems,
      totalDebit: json['total_debit']?.toString() ?? '0.00',
      totalCredit: (json['historical_total_credit'] ?? json['total_credit'])?.toString() ?? '0.00',
      totalBalance: json['total_balance']?.toString() ?? '0.00',
    );
  }

  /// Calculates running balance starting from initial balance 0.0 at the first order (last item in raw response)
  /// and accumulating towards the latest order (first item in raw response), preserving the raw response display order.
  static List<SalesReportItem> _calculateRunningBalances(List<SalesReportItem> rawEntries) {
    if (rawEntries.isEmpty) return [];

    final bool allZero = rawEntries.every(
      (e) => e.balance.isEmpty || e.balance == '0' || e.balance == '0.00',
    );
    if (!allZero) {
      return rawEntries;
    }

    final balances = List<String>.filled(rawEntries.length, '0.00');
    double currentBalance = 0.0;
    for (int i = rawEntries.length - 1; i >= 0; i--) {
      final item = rawEntries[i];
      final credit = double.tryParse(item.credit) ?? 0.0;
      final debit = double.tryParse(item.debit) ?? 0.0;
      currentBalance += (credit - debit);
      final roundedBalance = double.parse(currentBalance.toStringAsFixed(2));
      balances[i] = roundedBalance.toStringAsFixed(2);
    }

    final List<SalesReportItem> result = [];
    for (int i = 0; i < rawEntries.length; i++) {
      result.add(rawEntries[i].copyWith(balance: balances[i]));
    }
    return result;
  }
}

class SalesReportItem {
  final int id;
  final String invoiceDate;
  final String approvedAt;
  final String invoiceReferenceNo;
  final String customerName;
  final String platform;
  final String currency;
  final String currencyAmount;
  final String debit;
  final String credit;
  final String balance;

  static String _cleanString(dynamic val) {
    if (val == null) return '';
    final str = val.toString().trim();
    if (str == 'null' || str == 'None' || str == 'False' || str == 'false') {
      return '';
    }
    return str;
  }

  /// Helper getter returning preferred date for display (approvedAt if available, otherwise invoiceDate)
  String get displayDate {
    final app = _cleanString(approvedAt);
    return app.isNotEmpty ? app : invoiceDate;
  }

  SalesReportItem({
    required this.id,
    required this.invoiceDate,
    required this.approvedAt,
    required this.invoiceReferenceNo,
    required this.customerName,
    required this.platform,
    required this.currency,
    required this.currencyAmount,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  SalesReportItem copyWith({
    int? id,
    String? invoiceDate,
    String? approvedAt,
    String? invoiceReferenceNo,
    String? customerName,
    String? platform,
    String? currency,
    String? currencyAmount,
    String? debit,
    String? credit,
    String? balance,
  }) {
    return SalesReportItem(
      id: id ?? this.id,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      approvedAt: approvedAt ?? this.approvedAt,
      invoiceReferenceNo: invoiceReferenceNo ?? this.invoiceReferenceNo,
      customerName: customerName ?? this.customerName,
      platform: platform ?? this.platform,
      currency: currency ?? this.currency,
      currencyAmount: currencyAmount ?? this.currencyAmount,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      balance: balance ?? this.balance,
    );
  }

  factory SalesReportItem.fromJson(Map<String, dynamic> json) {
    return SalesReportItem(
      id: json['id'] as int? ?? 0,
      invoiceDate: _cleanString(json['invoice_date']),
      approvedAt: _cleanString(json['approved_at']),
      invoiceReferenceNo: json['invoice_reference_no']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      platform: _cleanString(json['platform']),
      currency: json['currency']?.toString() ?? '',
      currencyAmount: json['currency_amount']?.toString() ?? '0.00',
      debit: json['debit']?.toString() ?? '0.00',
      credit: json['credit']?.toString() ?? '0.00',
      balance: json['balance']?.toString() ?? '0.00',
    );
  }
}
