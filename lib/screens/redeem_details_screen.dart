import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../models/sales_report.dart';
import '../providers/redemption_provider.dart';
import '../providers/auth_provider.dart';
import 'redeem_request_screen.dart';

class RedeemDetailsScreen extends ConsumerWidget {
  const RedeemDetailsScreen({super.key});

  String _formatDate(String dateStr) {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = parsed.day.toString().padLeft(2, '0');
    final month = months[parsed.month - 1];
    final year = parsed.year;
    return '$day $month, $year';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesReportState = ref.watch(salesReportDataProvider);
    final redemptionBalanceState = ref.watch(redemptionBalanceProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(navigationProvider.notifier).state = ActiveScreen.dashboard;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => ref.read(navigationProvider.notifier).state = ActiveScreen.dashboard,
          ),
        title: const Text(
          'Redeem Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Teal accent band below AppBar
            Container(height: 8, color: AppColors.secondaryTeal),
            Expanded(
              child: (() {
                if (salesReportState.hasValue &&
                    redemptionBalanceState.hasValue) {
                  final salesReport = salesReportState.value!;
                  final redemptionBalance = redemptionBalanceState.value!;
                  final totalCredit =
                      double.tryParse(salesReport.totalCredit) ?? 0.0;
                  final totalDebit =
                      double.tryParse(salesReport.totalDebit) ?? 0.0;
                  final availableBalance =
                      double.tryParse(redemptionBalance.availableBalance) ??
                      0.0;
                  final hasPending = redemptionBalance.hasPendingRedemption;
                  final reportItems = salesReport.salesReport;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 750;

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: isMobile
                                  ? _buildMobileUnifiedCard(
                                      context,
                                      totalDebit,
                                      totalCredit,
                                      availableBalance,
                                      hasPending,
                                    )
                                  : _buildDesktopMetrics(
                                      context,
                                      totalDebit,
                                      totalCredit,
                                      availableBalance,
                                      hasPending,
                                    ),
                            ),

                            // Using the exact table format for ALL screen sizes
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: reportItems.isEmpty
                                  ? _buildEmptyState()
                                  : _buildTransactionTable(reportItems),
                            ),

                            const SizedBox(height: 40),
                            _buildFooter(),
                          ],
                        ),
                      );
                    },
                  );
                } else if (salesReportState.isLoading ||
                    redemptionBalanceState.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue,
                      ),
                    ),
                  );
                } else {
                  final error =
                      salesReportState.error ??
                      redemptionBalanceState.error ??
                      'Unknown error';
                  return _buildErrorState(error, ref);
                }
              })(),
            ),
          ],
        ),
      ),
    ),);
  }

  // --- Layout Builders ---

  Widget _buildMobileUnifiedCard(
    BuildContext context,
    double debit,
    double credit,
    double balance,
    bool hasPending,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Available Balance',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            balance.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          if (hasPending) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have a pending redemption request.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasPending
                  ? null
                  : () {
                      if (balance < 250.0) {
                        _showInsufficientBalanceDialog(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RedeemRequestScreen(),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPending
                    ? Colors.grey.shade300
                    : const Color(0xFF3F3D7A),
                foregroundColor: hasPending
                    ? Colors.grey.shade600
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Redeem',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      debit.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Debit',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      credit.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Credit',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMetrics(
    BuildContext context,
    double debit,
    double credit,
    double balance,
    bool hasPending,
  ) {
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildMetricCard(
              value: debit.toStringAsFixed(0),
              label: 'Total Debit',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMetricCard(
              value: credit.toStringAsFixed(2),
              label: 'Total Credit',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildBalanceCard(
              context: context,
              balance: balance,
              label: 'Available Balance',
              hasPending: hasPending,
            ),
          ),
        ],
      ),
    );
  }

  // --- Exact Table Design from Screenshot ---

  Widget _buildTransactionTable(List<SalesReportItem> items) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          4,
        ), // Slightly sharper corners `like the image
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal, // This enables swipe-to-scroll on mobile
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 800,
          ), // Forces the table to stay wide and readable
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(0.8), // Sl.No.
              1: FlexColumnWidth(1.5), // Date
              2: FlexColumnWidth(3.5), // Customer
              3: FlexColumnWidth(1.2), // Amount
              4: FlexColumnWidth(1.0), // Currency
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            children: [
              // Header Row matching the light gray image background
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF4F5F7)),
                children: [
                  _buildHeaderCell('Sl.No.'),
                  _buildHeaderCell('Date'),
                  _buildHeaderCell('Customer'),
                  _buildHeaderCell('Amount'),
                  _buildHeaderCell('Currency'),
                ],
              ),
              // Data Rows
              ...List.generate(items.length, (index) {
                final item = items[index];
                return TableRow(
                  children: [
                    _buildBodyCell('${index + 1}'),
                    _buildBodyCell(_formatDate(item.invoiceDate)),
                    _buildBodyCell(item.customerName),
                    _buildBodyCell(item.currencyAmount),
                    _buildBodyCell(item.currency),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // --- Components ---

  Widget _buildMetricCard({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required BuildContext context,
    required double balance,
    required String label,
    required bool hasPending,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            balance.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (hasPending) ...[
            Text(
              'Pending Request Active',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton(
            onPressed: hasPending
                ? null
                : () {
                    if (balance < 250.0) {
                      _showInsufficientBalanceDialog(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RedeemRequestScreen(),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPending
                  ? Colors.grey.shade300
                  : const Color(0xFF3F3D7A),
              foregroundColor: hasPending ? Colors.grey.shade600 : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Redeem',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildBodyCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textDark,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Text(
          'No redemption transactions found.',
          style: TextStyle(color: AppColors.textGrey, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final _ = ref.refresh(salesReportDataProvider);
              final _ = ref.refresh(redemptionBalanceProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 20),
      width: double.infinity,
      child: Center(
        child: RichText(
          text: const TextSpan(
            style: TextStyle(color: Colors.white70, fontSize: 12),
            children: [
              TextSpan(text: 'Copyright © 2026 | '),
              TextSpan(
                text: 'PartnerPro',
                style: TextStyle(
                  color: AppColors.secondaryTeal,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: ' | All rights reserved.'),
            ],
          ),
        ),
      ),
    );
  }

  void _showInsufficientBalanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 32.0,
              horizontal: 24.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red close icon in circle
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF27474),
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close,
                      color: Color(0xFFF27474),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Insufficient Balance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF595959),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'A minimum balance of 250.00 AED is required to request redemption.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF545454),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F3D7A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
