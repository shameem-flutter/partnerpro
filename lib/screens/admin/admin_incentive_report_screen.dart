import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../../models/admin_models.dart';
import '../../theme/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/admin_currency_dropdown.dart';

class AdminIncentiveReportScreen extends ConsumerWidget {
  const AdminIncentiveReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesReportAsync = ref.watch(salesReportProvider);
    final selectedCurrency = ref.watch(adminCurrencyProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
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
            child: AdminCurrencyDropdown(
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
          ref.refresh(salesReportProvider.future);
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
                  onRetry: () => ref.refresh(salesReportProvider.future),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('More options tapped'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        backgroundColor: const Color(0xFF032267),
        shape: const CircleBorder(),
        child: const Icon(Icons.more_horiz, color: Colors.white),
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
    final dateRange = ref.watch(salesReportDateRangeProvider);

    // Filter entries by date range
    final entries = report.entries.where((entry) {
      if (dateRange != null) {
        final parsed = DateTime.tryParse(entry.invoiceDate);
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

    // Sort entries by ID descending (latest first: 6, 3, 1...)
    entries.sort((a, b) => b.id.compareTo(a.id));

    final displayCurrency = selectedCurrency == '-- Select Currency --'
        ? 'AED'
        : selectedCurrency;

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

    return RefreshIndicator(
      onRefresh: () async {
        // ignore: unused_result
        ref.refresh(salesReportProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: SummaryRowWidget(
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
                              'RADEEMED',
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
                onRefresh: () => ref.refresh(salesReportProvider.future),
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

  const SummaryRowWidget({
    super.key,
    required this.totalCredit,
    required this.totalDebit,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
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
      child: Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: c,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class DateFilterRow extends ConsumerWidget {
  const DateFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(salesReportDateRangeProvider);

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
                ref.invalidate(salesReportDateRangeProvider);
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
          ElevatedButton.icon(
            onPressed: () async {
              final reportAsync = ref.read(salesReportProvider);
              final reportData = reportAsync.value;
              if (reportData == null || reportData.entries.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No data available to export.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
                return;
              }

              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Generating Excel sheet...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }

                // Get date range and apply local filtering (same as UI)
                final dateRange = ref.read(salesReportDateRangeProvider);
                final entries = reportData.entries.where((entry) {
                  if (dateRange != null) {
                    final parsed = DateTime.tryParse(entry.invoiceDate);
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

                // Apply local sorting (same as UI)
                entries.sort((a, b) => b.id.compareTo(a.id));

                // Get currency and conversion target (same as UI)
                final selectedCurrency = ref.read(adminCurrencyProvider);
                final targetCurrency = (selectedCurrency == '-- Select Currency --' || selectedCurrency.isEmpty)
                    ? 'AED'
                    : selectedCurrency;

                final bytes = await ExcelReportGenerator.generateIncentiveReport(
                  entries: entries,
                  reportData: reportData,
                  targetCurrency: targetCurrency,
                );

                Directory? dir;
                if (Platform.isAndroid) {
                  try {
                    final publicDownloadDir = Directory('/storage/emulated/0/Download');
                    if (await publicDownloadDir.exists()) {
                      final testFile = File('${publicDownloadDir.path}/.test_write');
                      await testFile.writeAsString('test');
                      await testFile.delete();
                      dir = publicDownloadDir;
                    }
                  } catch (_) {}
                }

                if (dir == null) {
                  try {
                    dir = await getDownloadsDirectory();
                  } catch (_) {}
                }

                if (dir == null && Platform.isAndroid) {
                  try {
                    final dirs = await getExternalStorageDirectories(
                      type: StorageDirectory.downloads,
                    );
                    if (dirs != null && dirs.isNotEmpty) {
                      dir = dirs.first;
                    }
                  } catch (_) {}
                }

                dir ??= await getTemporaryDirectory();

                final file = File(
                  '${dir.path}/Incentive_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
                );
                await file.writeAsBytes(bytes);

                await OpenFilex.open(file.path);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Excel saved to Downloads/Files: ${file.path.split(Platform.pathSeparator).last}',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error generating Excel: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            icon: Image.network(
              'https://img.icons8.com/color/48/microsoft-excel-2019--v1.png',
              width: 18,
              height: 18,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.table_view, color: Colors.green, size: 18),
            ),
            label: const Text(
              'Export',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF032267),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
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
      ref.read(salesReportDateRangeProvider.notifier).state = picked;
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
    String formattedDate = widget.entry.invoiceDate;
    final parsedDate = DateTime.tryParse(widget.entry.invoiceDate);
    if (parsedDate != null) {
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
      formattedDate =
          '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
    }

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
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 14,
                              color: Color(0xFF032267),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formattedDate,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
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
                          color: convertedCredit > 0
                              ? const Color(0xFFF0F9EB)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: convertedCredit > 0
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    '$displayCurrency ${convertedCredit.toStringAsFixed(2)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF67C23A),
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
                      _buildDetailRow('Invoice Date', formattedDate),
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

class ExcelReportGenerator {
  static Future<List<int>> generateIncentiveReport({
    required List<SalesReportEntry> entries,
    required SalesReportResponse reportData,
    required String targetCurrency,
  }) async {
    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];
    sheet.showGridlines = true;

    // Apply Page Settings
    _applyPageSettings(sheet);

    // Create Report Header
    _createReportHeader(sheet, workbook, targetCurrency);

    // Create Table Header
    _createTableHeader(sheet, workbook);

    // Populate Data Rows
    final int lastDataRow = _populateDataRows(sheet, workbook, entries, targetCurrency);

    // Create Summary Section
    final int summaryStartRow = lastDataRow + 2;
    _createSummarySection(sheet, workbook, summaryStartRow, reportData, targetCurrency);

    // Apply Auto Filter
    sheet.autoFilters.filterRange = sheet.getRangeByIndex(5, 1, lastDataRow, 9);

    // Freeze Headers
    sheet.getRangeByIndex(6, 1).freezePanes();

    // Auto Fit Columns
    _autoFitWorksheet(sheet);

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  static void _applyPageSettings(xlsio.Worksheet sheet) {
    final xlsio.PageSetup pageSetup = sheet.pageSetup;
    pageSetup.orientation = xlsio.ExcelPageOrientation.landscape;
    pageSetup.paperSize = xlsio.ExcelPaperSize.paperA4;
    pageSetup.isFitToPage = true;
    pageSetup.fitToPagesWide = 1;
    pageSetup.fitToPagesTall = 0;
    pageSetup.isCenterHorizontally = true;
    pageSetup.isCenterVertically = false;
    pageSetup.leftMargin = 0.5;
    pageSetup.rightMargin = 0.5;
    pageSetup.topMargin = 0.5;
    pageSetup.bottomMargin = 0.5;
  }

  static void _createReportHeader(xlsio.Worksheet sheet, xlsio.Workbook workbook, String targetCurrency) {
    // Merge cells for the title: A1 to I2
    sheet.getRangeByIndex(1, 1, 2, 9).merge();
    
    final xlsio.Range titleCell = sheet.getRangeByIndex(1, 1);
    titleCell.setText('INCENTIVE REPORT');
    
    final xlsio.Style titleStyle = workbook.styles.add('titleStyle');
    titleStyle.backColor = '#1E3A8A';
    titleStyle.fontColor = '#FFFFFF';
    titleStyle.fontSize = 18;
    titleStyle.bold = true;
    titleStyle.hAlign = xlsio.HAlignType.center;
    titleStyle.vAlign = xlsio.VAlignType.center;
    
    sheet.getRangeByIndex(1, 1, 2, 9).cellStyle = titleStyle;
    sheet.getRangeByIndex(1, 1).rowHeight = 22;
    sheet.getRangeByIndex(2, 1).rowHeight = 22;

    // Metadata: Generated On and Currency
    final xlsio.Style metaLabelStyle = workbook.styles.add('metaLabelStyle');
    metaLabelStyle.fontSize = 10;
    metaLabelStyle.bold = true;
    metaLabelStyle.vAlign = xlsio.VAlignType.center;

    final xlsio.Style metaValueStyle = workbook.styles.add('metaValueStyle');
    metaValueStyle.fontSize = 10;
    metaValueStyle.vAlign = xlsio.VAlignType.center;

    // Row 3: Generated On
    sheet.getRangeByIndex(3, 1).setText('Generated On :');
    sheet.getRangeByIndex(3, 1).cellStyle = metaLabelStyle;
    
    sheet.getRangeByIndex(3, 2).setText(_formatDateTime(DateTime.now()));
    sheet.getRangeByIndex(3, 2).cellStyle = metaValueStyle;
    sheet.getRangeByIndex(3, 1).rowHeight = 20;

    // Row 4: Currency
    sheet.getRangeByIndex(4, 1).setText('Currency :');
    sheet.getRangeByIndex(4, 1).cellStyle = metaLabelStyle;
    
    sheet.getRangeByIndex(4, 2).setText(targetCurrency);
    sheet.getRangeByIndex(4, 2).cellStyle = metaValueStyle;
    sheet.getRangeByIndex(4, 1).rowHeight = 20;
  }

  static void _createTableHeader(xlsio.Worksheet sheet, xlsio.Workbook workbook) {
    final headers = [
      'ID',
      'Invoice Date',
      'Invoice Reference',
      'Customer Name',
      'Platform',
      'Currency',
      'Debit',
      'Credit',
      'Balance'
    ];

    final xlsio.Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.backColor = '#1E3A8A';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.bold = true;
    headerStyle.fontSize = 11;
    headerStyle.hAlign = xlsio.HAlignType.center;
    headerStyle.vAlign = xlsio.VAlignType.center;
    headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    headerStyle.borders.all.color = '#D3D3D3';

    for (int col = 1; col <= headers.length; col++) {
      final xlsio.Range cell = sheet.getRangeByIndex(5, col);
      cell.setText(headers[col - 1]);
      cell.cellStyle = headerStyle;
    }
    sheet.getRangeByIndex(5, 1).rowHeight = 25;
  }

  static int _populateDataRows(
    xlsio.Worksheet sheet,
    xlsio.Workbook workbook,
    List<SalesReportEntry> entries,
    String targetCurrency,
  ) {
    // Create shared styles
    final leftOdd = _createCellStyle(workbook, 'leftOdd', null, xlsio.HAlignType.left);
    final leftEven = _createCellStyle(workbook, 'leftEven', '#F7F9FC', xlsio.HAlignType.left);

    final centerOdd = _createCellStyle(workbook, 'centerOdd', null, xlsio.HAlignType.center);
    final centerEven = _createCellStyle(workbook, 'centerEven', '#F7F9FC', xlsio.HAlignType.center);

    final dateOdd = _createCellStyle(workbook, 'dateOdd', null, xlsio.HAlignType.center, numberFormat: 'dd-mmm-yyyy');
    final dateEven = _createCellStyle(workbook, 'dateEven', '#F7F9FC', xlsio.HAlignType.center, numberFormat: 'dd-mmm-yyyy');

    final rightOdd = _createCellStyle(workbook, 'rightOdd', null, xlsio.HAlignType.right, numberFormat: '#,##0.00');
    final rightEven = _createCellStyle(workbook, 'rightEven', '#F7F9FC', xlsio.HAlignType.right, numberFormat: '#,##0.00');

    int currentRow = 6;
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isEven = i % 2 == 1;

      final styleL = isEven ? leftEven : leftOdd;
      final styleC = isEven ? centerEven : centerOdd;
      final styleD = isEven ? dateEven : dateOdd;
      final styleR = isEven ? rightEven : rightOdd;

      final convertedDebit = CurrencyUtils.convertAmount(entry.debit, entry.currency, targetCurrency);
      final convertedCredit = CurrencyUtils.convertAmount(entry.commissionAmount, entry.currency, targetCurrency);
      final convertedBalance = CurrencyUtils.convertAmount(entry.balance, entry.currency, targetCurrency);

      // 1. ID
      final c1 = sheet.getRangeByIndex(currentRow, 1);
      c1.setNumber((i + 1).toDouble());
      c1.cellStyle = styleC;

      // 2. Invoice Date
      final c2 = sheet.getRangeByIndex(currentRow, 2);
      final parsedDate = DateTime.tryParse(entry.invoiceDate);
      if (parsedDate != null) {
        c2.setDateTime(parsedDate);
        c2.cellStyle = styleD;
      } else {
        c2.setText(entry.invoiceDate);
        c2.cellStyle = styleC;
      }

      // 3. Invoice Reference
      final c3 = sheet.getRangeByIndex(currentRow, 3);
      c3.setText(entry.invoiceReferenceNo);
      c3.cellStyle = styleL;

      // 4. Customer Name
      final c4 = sheet.getRangeByIndex(currentRow, 4);
      c4.setText(entry.customerName);
      c4.cellStyle = styleL;

      // 5. Platform
      final c5 = sheet.getRangeByIndex(currentRow, 5);
      c5.setText(entry.platform);
      c5.cellStyle = styleL;

      // 6. Currency
      final c6 = sheet.getRangeByIndex(currentRow, 6);
      c6.setText(targetCurrency);
      c6.cellStyle = styleC;

      // 7. Debit
      final c7 = sheet.getRangeByIndex(currentRow, 7);
      c7.setNumber(convertedDebit);
      c7.cellStyle = styleR;

      // 8. Credit
      final c8 = sheet.getRangeByIndex(currentRow, 8);
      c8.setNumber(convertedCredit);
      c8.cellStyle = styleR;

      // 9. Balance
      final c9 = sheet.getRangeByIndex(currentRow, 9);
      c9.setNumber(convertedBalance);
      c9.cellStyle = styleR;

      sheet.getRangeByIndex(currentRow, 1).rowHeight = 20;
      currentRow++;
    }
    return currentRow - 1;
  }

  static void _createSummarySection(
    xlsio.Worksheet sheet,
    xlsio.Workbook workbook,
    int summaryStartRow,
    SalesReportResponse reportData,
    String targetCurrency,
  ) {
    // 1. Create styles
    final xlsio.Style summaryLabelStyle = workbook.styles.add('summaryLabelStyle');
    summaryLabelStyle.backColor = '#EEEEEE';
    summaryLabelStyle.bold = true;
    summaryLabelStyle.fontSize = 10;
    summaryLabelStyle.hAlign = xlsio.HAlignType.left;
    summaryLabelStyle.vAlign = xlsio.VAlignType.center;
    summaryLabelStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryLabelStyle.borders.all.color = '#D3D3D3';
    summaryLabelStyle.borders.top.lineStyle = xlsio.LineStyle.medium;

    final xlsio.Style summaryValueStyle = workbook.styles.add('summaryValueStyle');
    summaryValueStyle.backColor = '#EEEEEE';
    summaryValueStyle.bold = true;
    summaryValueStyle.fontSize = 10;
    summaryValueStyle.hAlign = xlsio.HAlignType.right;
    summaryValueStyle.vAlign = xlsio.VAlignType.center;
    summaryValueStyle.numberFormat = '#,##0.00';
    summaryValueStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryValueStyle.borders.all.color = '#D3D3D3';
    summaryValueStyle.borders.top.lineStyle = xlsio.LineStyle.medium;

    final xlsio.Style summaryEmptyStyle = workbook.styles.add('summaryEmptyStyle');
    summaryEmptyStyle.backColor = '#EEEEEE';
    summaryEmptyStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryEmptyStyle.borders.all.color = '#D3D3D3';
    summaryEmptyStyle.borders.top.lineStyle = xlsio.LineStyle.medium;

    // Styles for rows 2 and 3 of summary (no thick top border)
    final xlsio.Style summaryLabelStyleSub = workbook.styles.add('summaryLabelStyleSub');
    summaryLabelStyleSub.backColor = '#EEEEEE';
    summaryLabelStyleSub.bold = true;
    summaryLabelStyleSub.fontSize = 10;
    summaryLabelStyleSub.hAlign = xlsio.HAlignType.left;
    summaryLabelStyleSub.vAlign = xlsio.VAlignType.center;
    summaryLabelStyleSub.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryLabelStyleSub.borders.all.color = '#D3D3D3';

    final xlsio.Style summaryValueStyleSub = workbook.styles.add('summaryValueStyleSub');
    summaryValueStyleSub.backColor = '#EEEEEE';
    summaryValueStyleSub.bold = true;
    summaryValueStyleSub.fontSize = 10;
    summaryValueStyleSub.hAlign = xlsio.HAlignType.right;
    summaryValueStyleSub.vAlign = xlsio.VAlignType.center;
    summaryValueStyleSub.numberFormat = '#,##0.00';
    summaryValueStyleSub.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryValueStyleSub.borders.all.color = '#D3D3D3';

    final xlsio.Style summaryEmptyStyleSub = workbook.styles.add('summaryEmptyStyleSub');
    summaryEmptyStyleSub.backColor = '#EEEEEE';
    summaryEmptyStyleSub.borders.all.lineStyle = xlsio.LineStyle.thin;
    summaryEmptyStyleSub.borders.all.color = '#D3D3D3';

    // Convert totals
    final convertedTotalDebit = CurrencyUtils.convertAmount(reportData.totalDebit, 'AED', targetCurrency);
    final convertedTotalCredit = CurrencyUtils.convertAmount(reportData.totalCommission, 'AED', targetCurrency);
    final convertedTotalBalance = CurrencyUtils.convertAmount(reportData.totalAmount, 'AED', targetCurrency);

    // Row 1: Total Debit
    sheet.getRangeByIndex(summaryStartRow, 1, summaryStartRow, 5).merge();
    sheet.getRangeByIndex(summaryStartRow, 1).setText('Total Debit');
    for (int c = 1; c <= 9; c++) {
      final cell = sheet.getRangeByIndex(summaryStartRow, c);
      if (c <= 5) {
        cell.cellStyle = summaryLabelStyle;
      } else if (c == 6) {
        cell.setText(targetCurrency);
        cell.cellStyle = summaryLabelStyle;
      } else if (c == 7) {
        cell.setNumber(convertedTotalDebit);
        cell.cellStyle = summaryValueStyle;
      } else {
        cell.cellStyle = summaryEmptyStyle;
      }
    }
    sheet.getRangeByIndex(summaryStartRow, 1).rowHeight = 22;

    // Row 2: Total Credit
    final int summaryRow2 = summaryStartRow + 1;
    sheet.getRangeByIndex(summaryRow2, 1, summaryRow2, 5).merge();
    sheet.getRangeByIndex(summaryRow2, 1).setText('Total Credit');
    for (int c = 1; c <= 9; c++) {
      final cell = sheet.getRangeByIndex(summaryRow2, c);
      if (c <= 5) {
        cell.cellStyle = summaryLabelStyleSub;
      } else if (c == 6) {
        cell.setText(targetCurrency);
        cell.cellStyle = summaryLabelStyleSub;
      } else if (c == 8) {
        cell.setNumber(convertedTotalCredit);
        cell.cellStyle = summaryValueStyleSub;
      } else {
        cell.cellStyle = summaryEmptyStyleSub;
      }
    }
    sheet.getRangeByIndex(summaryRow2, 1).rowHeight = 22;

    // Row 3: Closing Balance
    final int summaryRow3 = summaryRow2 + 1;
    sheet.getRangeByIndex(summaryRow3, 1, summaryRow3, 5).merge();
    sheet.getRangeByIndex(summaryRow3, 1).setText('Closing Balance');
    for (int c = 1; c <= 9; c++) {
      final cell = sheet.getRangeByIndex(summaryRow3, c);
      if (c <= 5) {
        cell.cellStyle = summaryLabelStyleSub;
      } else if (c == 6) {
        cell.setText(targetCurrency);
        cell.cellStyle = summaryLabelStyleSub;
      } else if (c == 9) {
        cell.setNumber(convertedTotalBalance);
        cell.cellStyle = summaryValueStyleSub;
      } else {
        cell.cellStyle = summaryEmptyStyleSub;
      }
    }
    sheet.getRangeByIndex(summaryRow3, 1).rowHeight = 22;
  }

  static void _autoFitWorksheet(xlsio.Worksheet sheet) {
    for (int col = 1; col <= 9; col++) {
      sheet.autoFitColumn(col);
      // Ensure a reasonable minimum width so headers aren't cramped
      if (sheet.getRangeByIndex(1, col).columnWidth < 13.0) {
        sheet.getRangeByIndex(1, col).columnWidth = 13.0;
      }
    }
  }

  static xlsio.Style _createCellStyle(
    xlsio.Workbook wb,
    String name,
    String? backColor,
    xlsio.HAlignType hAlign, {
    String? numberFormat,
  }) {
    final xlsio.Style style = wb.styles.add(name);
    style.fontSize = 10;
    style.vAlign = xlsio.VAlignType.center;
    style.hAlign = hAlign;
    style.borders.all.lineStyle = xlsio.LineStyle.thin;
    style.borders.all.color = '#E0E0E0';
    if (backColor != null) {
      style.backColor = backColor;
    }
    if (numberFormat != null) {
      style.numberFormat = numberFormat;
    }
    return style;
  }

  static String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute:$second';
  }
}
