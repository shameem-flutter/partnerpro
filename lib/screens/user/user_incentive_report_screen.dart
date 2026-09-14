import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/admin_models.dart';
import '../../theme/app_colors.dart';
import '../../providers/statement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/currency_utils.dart';
import '../../utils/incentive_report_exporter.dart';
import '../../widgets/user_currency_dropdown.dart';

class UserIncentiveReportScreen extends ConsumerWidget {
  const UserIncentiveReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesReportAsync = ref.watch(userSalesReportProvider);
    final selectedCurrency = ref.watch(userCurrencyProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(navigationProvider.notifier).state = ActiveScreen.dashboard;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              ref.read(navigationProvider.notifier).state =
                  ActiveScreen.dashboard;
            },
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAASORDER',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Incentive Report',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: UserCurrencyDropdown(
                backgroundColor: AppColors.primaryBlue,
                textColor: Colors.white,
                borderColor: Colors.white.withValues(alpha: 0.3),
                height: 38,
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            // ignore: unused_result
            ref.refresh(userSalesReportProvider.future);
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: salesReportAsync.when(
              data: (report) => _SalesReportContent(
                report: report,
                selectedCurrency: selectedCurrency,
              ),
              loading: () => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: const LoadingSkeleton(),
              ),
              error: (err, stack) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: ErrorState(
                    error: err,
                    onRetry: () => ref.refresh(userSalesReportProvider.future),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesReportContent extends ConsumerWidget {
  final SalesReportResponse report;
  final String selectedCurrency;

  const _SalesReportContent({
    required this.report,
    required this.selectedCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(userSalesReportDateRangeProvider);

    // Filter entries by date range while keeping backend statement ledger array order intact
    final entries = report.entries.where((entry) {
      if (dateRange != null) {
        final parsed = DateTime.tryParse(entry.displayDate);
        if (parsed != null) {
          final start = DateTime(
            dateRange.start.year,
            dateRange.start.month,
            dateRange.start.day,
          );
          final end = DateTime(
            dateRange.end.year,
            dateRange.end.month,
            dateRange.end.day,
            23,
            59,
            59,
          );
          if (parsed.isBefore(start) || parsed.isAfter(end)) {
            return false;
          }
        }
      }
      return true;
    }).toList();

    final displayCurrency = selectedCurrency.isEmpty ? 'AED' : selectedCurrency;

    final convertedCredit = CurrencyUtils.convertAmount(
      report.totalCommission,
      'AED',
      selectedCurrency,
    );
    final convertedDebit = CurrencyUtils.convertAmount(
      report.totalDebit,
      'AED',
      selectedCurrency,
    );
    final convertedBalance = CurrencyUtils.convertAmount(
      report.totalBalance,
      'AED',
      selectedCurrency,
    );

    return RefreshIndicator(
      onRefresh: () async {
        // ignore: unused_result
        ref.refresh(userSalesReportProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: SummaryRowWidget(
                totalBalance:
                    '$displayCurrency ${convertedBalance.toStringAsFixed(2)}',
                totalCredit:
                    '$displayCurrency ${convertedCredit.toStringAsFixed(2)}',
                totalDebit:
                    '$displayCurrency ${convertedDebit.toStringAsFixed(2)}',
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(child: DateFilterRow()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    children: [
                      // const Expanded(
                      //   child: Divider(
                      //     color: Color(0xFFE0E0E0),
                      //     thickness: 1,
                      //   ),
                      // ),
                      // const SizedBox(width: 12),
                      // Container(
                      //   padding: const EdgeInsets.all(8),
                      //   decoration: const BoxDecoration(
                      //     color: Color(0xFF032267),
                      //     shape: BoxShape.circle,
                      //   ),
                      //   child: const Icon(
                      //     Icons.assignment,
                      //     color: Colors.white,
                      //     size: 20,
                      //   ),
                      // ),
                      // const SizedBox(width: 8),
                      const Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF032267),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '(${(entries.length)})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF032267),
                        ),
                      ),
                      // const SizedBox(width: 12),
                      // const Expanded(
                      //   child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                      // ),
                    ],
                  ),
                  // const SizedBox(height: 6),
                  // const Text(
                  //   'Detailed list of all your orders and earned commission',
                  //   style: TextStyle(
                  //     fontSize: 11,
                  //     color: Colors.grey,
                  //     fontWeight: FontWeight.w400,
                  //   ),
                  // ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ENTRIES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              'REDEEMED',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'COMMISSION',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                onRefresh: () => ref.refresh(userSalesReportProvider.future),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = entries[index];
                  return FadeInSlide(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: SalesReportCard(
                        entry: entry,
                        selectedCurrency: selectedCurrency,
                      ),
                    ),
                  );
                }, childCount: entries.length),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Sub-Widgets
// ---------------------------------------------------------------------------

class SummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color accentColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryRowWidget extends StatelessWidget {
  final String totalCredit;
  final String totalDebit;
  final String? totalBalance;

  const SummaryRowWidget({
    super.key,
    required this.totalCredit,
    required this.totalDebit,
    this.totalBalance,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      if (totalBalance != null)
        SummaryCard(
          title: 'Available Balance',
          subtitle: 'Available Balance',
          value: totalBalance!,
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF032267),
          accentColor: const Color(0xFF032267),
        ),
      SummaryCard(
        title: 'Total Credit',
        subtitle: 'Total Credit',
        value: totalCredit,
        icon: Icons.arrow_downward_rounded,
        iconColor: Colors.green.shade600,
        accentColor: Colors.green,
      ),
      SummaryCard(
        title: 'Total Debit',
        subtitle: 'Total Debit',
        value: totalDebit,
        icon: Icons.arrow_upward_rounded,
        iconColor: Colors.orange.shade700,
        accentColor: Colors.orange,
      ),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => SizedBox(
          width: 155,
          child: cards[index],
        ),
      ),
    );
  }
}

class DateFilterRow extends ConsumerWidget {
  const DateFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(userSalesReportDateRangeProvider);

    final fromText = dateRange != null ? _formatDate(dateRange.start) : 'All';
    final toText = dateRange != null ? _formatDate(dateRange.end) : 'All';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pickDateRange(context, ref, dateRange),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'From Date',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fromText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _pickDateRange(context, ref, dateRange),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To Date',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            toText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (dateRange != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                ref.invalidate(userSalesReportDateRangeProvider);
              },
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF032267),
                size: 20,
              ),
              tooltip: 'Reset Date Range',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF032267).withValues(alpha: 0.1),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Export Report',
            offset: const Offset(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            elevation: 4,
            onSelected: (type) {
              _handleExport(context, ref, isPdf: type == 'pdf');
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Image.network(
                      'https://img.icons8.com/color/48/microsoft-excel-2019--v1.png',
                      width: 22,
                      height: 22,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.table_view, color: Colors.green, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Excel Spreadsheet',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Export as .xlsx file',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Image.network(
                      'https://img.icons8.com/color/48/pdf.png',
                      width: 22,
                      height: 22,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PDF Document',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Export as printable .pdf file',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF032267),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_download_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Export',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref, {
    required bool isPdf,
  }) async {
    final reportAsync = ref.read(userSalesReportProvider);
    final reportData = reportAsync.value;
    if (reportData == null || reportData.entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No data available to export.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    final dateRange = ref.read(userSalesReportDateRangeProvider);
    final entries = reportData.entries.where((entry) {
      if (dateRange != null) {
        final parsed = DateTime.tryParse(entry.displayDate);
        if (parsed != null) {
          final start = DateTime(
            dateRange.start.year,
            dateRange.start.month,
            dateRange.start.day,
          );
          final end = DateTime(
            dateRange.end.year,
            dateRange.end.month,
            dateRange.end.day,
            23,
            59,
            59,
          );
          if (parsed.isBefore(start) || parsed.isAfter(end)) {
            return false;
          }
        }
      }
      return true;
    }).toList();

    final selectedCurrency = ref.read(userCurrencyProvider);
    final targetCurrency =
        selectedCurrency.isEmpty ? 'AED' : selectedCurrency;

    await IncentiveReportExporter.exportReport(
      context: context,
      entries: entries,
      reportData: reportData,
      targetCurrency: targetCurrency,
      isPdf: isPdf,
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDateRange(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange? currentRange,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange:
          currentRange ??
          DateTimeRange(
            start: DateTime(2024, 12, 1),
            end: DateTime(2024, 12, 31),
          ),
    );
    if (picked != null) {
      ref.read(userSalesReportDateRangeProvider.notifier).state = picked;
    }
  }
}

class PlatformChip extends StatelessWidget {
  final String platform;

  const PlatformChip({super.key, required this.platform});

  @override
  Widget build(BuildContext context) {
    if (platform.isEmpty || platform == 'False') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Text(
        platform.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class AmountTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color valueColor;

  const AmountTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SalesReportCard extends StatefulWidget {
  final SalesReportEntry entry;
  final String selectedCurrency;

  const SalesReportCard({
    super.key,
    required this.entry,
    required this.selectedCurrency,
  });

  @override
  State<SalesReportCard> createState() => _SalesReportCardState();
}

class _SalesReportCardState extends State<SalesReportCard> {
  bool _isExpanded = false;

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBoldValue = false,
    Color? valueColor,
    bool isBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isBadge
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            valueColor?.withValues(alpha: 0.1) ??
                            Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: valueColor ?? Colors.black87,
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isBoldValue
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: valueColor ?? Colors.black87,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawAppAt = widget.entry.approvedAt.trim();
    final bool hasApproved = rawAppAt.isNotEmpty &&
        rawAppAt != 'null' &&
        rawAppAt != 'None' &&
        rawAppAt != 'False' &&
        rawAppAt != 'false';

    // No fallback: only show approved date if it exists, otherwise empty
    String formattedApproved = '';
    if (hasApproved) {
      final parsed = DateTime.tryParse(rawAppAt);
      if (parsed != null) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        formattedApproved =
            '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
      } else {
        formattedApproved = rawAppAt;
      }
    }

    String formattedInvoiceDate = widget.entry.invoiceDate;
    final parsedInvoiceDate = DateTime.tryParse(widget.entry.invoiceDate);
    if (parsedInvoiceDate != null) {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      formattedInvoiceDate =
          '${parsedInvoiceDate.day} ${months[parsedInvoiceDate.month - 1]} ${parsedInvoiceDate.year}';
    }

    // formattedApproved already built above — reuse it for the detail row
    final String formattedApprovedDate = formattedApproved;

    final targetCurrency =
        (widget.selectedCurrency == '-- Select Currency --' ||
            widget.selectedCurrency.isEmpty)
        ? 'AED'
        : widget.selectedCurrency;

    final displayCurrency = targetCurrency;

    final convertedCredit = CurrencyUtils.convertAmount(
      widget.entry.commissionAmount,
      'AED',
      targetCurrency,
    );
    final convertedDebit = CurrencyUtils.convertAmount(
      widget.entry.debit,
      'AED',
      targetCurrency,
    );
    final convertedBalance = CurrencyUtils.convertAmount(
      widget.entry.balance,
      'AED',
      targetCurrency,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (formattedApproved.isNotEmpty) ...[
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 14,
                                color: Color(0xFF032267),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  formattedApproved,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  formattedInvoiceDate.isNotEmpty
                                      ? '$formattedInvoiceDate (Pending)'
                                      : 'Pending Approval',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF032267),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'BAL: $displayCurrency ${convertedBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right Columns Section
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // RADEEMED (Debit) Column
                      Container(
                        width: 100,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: convertedDebit > 0
                              ? const Color(0xFFFEF0F0)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: convertedDebit > 0
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    '$displayCurrency ${convertedDebit.toStringAsFixed(2)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF56C6C),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 10),
                      // COMMISSION (Credit) Column
                      Container(
                        width: 100,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: convertedCredit != 0
                              ? (convertedCredit < 0
                                  ? const Color(0xFFFEF0F0)
                                  : const Color(0xFFF0F9EB))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: convertedCredit != 0
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    '$displayCurrency ${convertedCredit.toStringAsFixed(2)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      // Red for negative amounts, green for positive
                                      color: convertedCredit < 0
                                          ? const Color(0xFFF56C6C)
                                          : const Color(0xFF67C23A),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Customer',
                        widget.entry.customerName,
                        isBoldValue: true,
                      ),
                      if (widget.entry.platform.isNotEmpty &&
                          widget.entry.platform != 'False')
                        _buildDetailRow('Platform', widget.entry.platform),
                      if (formattedInvoiceDate.isNotEmpty)
                        _buildDetailRow('Invoice Date', formattedInvoiceDate),
                      if (formattedApprovedDate.isNotEmpty)
                        _buildDetailRow('Approved Date', formattedApprovedDate),
                      _buildDetailRow(
                        'Invoice Ref',
                        widget.entry.invoiceReferenceNo,
                      ),
                      _buildDetailRow(
                        'Invoice Amount',
                        widget.entry.totalAmount == 0.0
                            ? 'No Incentive'
                            : '${widget.entry.currency} ${widget.entry.totalAmount.toStringAsFixed(2)}',
                        valueColor: widget.entry.totalAmount == 0.0
                            ? Colors.red
                            : null,
                      ),
                      _buildDetailRow(
                        'Status',
                        widget.entry.isApproved ? 'Approved' : 'Pending',
                        valueColor: widget.entry.isApproved
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        isBadge: true,
                      ),
                      _buildDetailRow(
                        'Running Balance',
                        '$displayCurrency ${convertedBalance.toStringAsFixed(2)}',
                        isBoldValue: true,
                        valueColor: const Color(0xFF032267),
                      ),
                      const SizedBox(height: 8),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE5E5E5),
                      ),
                      const SizedBox(height: 8),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.end,
                      //   children: [
                      //     TextButton.icon(
                      //       onPressed: () {
                      //         // View details action if any
                      //       },
                      //       icon: const Icon(
                      //         Icons.open_in_new,
                      //         size: 16,
                      //         color: AppColors.primaryBlue,
                      //       ),
                      //       label: const Text(
                      //         'View Full Invoice',
                      //         style: TextStyle(
                      //           fontSize: 12,
                      //           fontWeight: FontWeight.bold,
                      //           color: AppColors.primaryBlue,
                      //         ),
                      //       ),
                      //       style: TextButton.styleFrom(
                      //         padding: const EdgeInsets.symmetric(
                      //           horizontal: 12,
                      //           vertical: 8,
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FadeInSlide extends StatelessWidget {
  final Widget child;
  final int index;

  const FadeInSlide({super.key, required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 80).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({super.key});

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.4),
          child: Column(
            children: List.generate(3, (index) => const _SkeletonCard()),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: List.generate(
              4,
              (index) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const EmptyState({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No incentive reports found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any records matching your search queries or date filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error loading report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
