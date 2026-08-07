import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/admin_models.dart';
import '../../theme/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/api_config.dart';
import '../../widgets/permission_denied_widget.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/admin_currency_dropdown.dart';

class ReferralMonthOrders {
  const ReferralMonthOrders({
    required this.monthName,
    required this.orders,
    required this.totalAmount,
    required this.orderCount,
  });

  final String monthName;
  final List<AdminReferralOrder> orders;
  final double totalAmount;
  final int orderCount;
}

/// Shows the referral orders with a salesperson dropdown filter.
/// Grouped by month.
class AdminReferralOrdersScreen extends ConsumerWidget {
  const AdminReferralOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allReferralOrdersProvider);
    final selectedId = ref.watch(allReferralOrdersSalespersonIdProvider);
    final selectedCurrency = ref.watch(adminCurrencyProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context, ref),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(allReferralOrdersProvider.future),
        child: Stack(
          children: [
            if (ordersAsync.hasValue)
              _buildBody(
                context,
                ref,
                ordersAsync.value!,
                selectedId,
                selectedCurrency,
              )
            else if (ordersAsync.isLoading)
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  ),
                ),
              )
            else
              _buildError(context, ref, ordersAsync.error!),

            if (ordersAsync.hasValue && ordersAsync.isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                  backgroundColor: Colors.transparent,
                  minHeight: 3,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, child) {
          final selectedSet = ref.watch(selectedReferralsProvider);
          if (selectedSet.isEmpty) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedSet.length} Referrals Selected',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ready for bulk approval',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedReferralsProvider.notifier).state = {};
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _showBulkApprovalConfirmDialog(context, ref, selectedSet);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.approvedGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Approve Bulk',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
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
            'Referral Orders',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AllReferralOrdersResponse data,
    String? selectedId,
    String selectedCurrency,
  ) {
    final orders = selectedId == null
        ? data.orders
        : data.orders
            .where(
              (o) => o.referralDetails.any((r) => r.salespersonId == selectedId),
            )
            .toList();

    final groupedOrders = _groupReferralsByMonth(orders);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(allReferralOrdersProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown Row
            Row(
              children: [
                Expanded(
                  child: _buildSalespersonDropdown(
                    context,
                    ref,
                    data.salespersons,
                    selectedId,
                  ),
                ),
                const SizedBox(width: 12),
                const AdminCurrencyDropdown(),
              ],
            ),
            const SizedBox(height: 20),

            // Summary
            _buildSummaryRow(
              orders,
              selectedCurrency,
              apiDebit: selectedId == null ? data.totalDebit : null,
              apiCredit: selectedId == null ? data.totalCredit : null,
              apiBalance: selectedId == null ? data.totalBalance : null,
            ),
            const SizedBox(height: 20),

            // Header
            _buildSectionHeader('Referral Orders (${orders.length})'),
            const SizedBox(height: 12),

            if (groupedOrders.isEmpty)
              _buildEmptyCard('No referral orders found.')
            else
              ...groupedOrders.map(
                (monthData) => _buildMonthGroupCard(context, ref, monthData, selectedCurrency),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    List<AdminReferralOrder> orders,
    String selectedCurrency, {
    double? apiDebit,
    double? apiCredit,
    double? apiBalance,
  }) {
    final double credit = apiCredit != null
        ? CurrencyUtils.convertAmount(apiCredit, 'AED', selectedCurrency)
        : orders
            .where((o) => o.isApproved)
            .fold(
              0.0,
              (sum, o) =>
                  sum +
                  CurrencyUtils.convertAmount(
                    o.commissionAmountTotal,
                    o.currency,
                    selectedCurrency,
                  ),
            );

    final double debit = apiDebit != null
        ? CurrencyUtils.convertAmount(apiDebit, 'AED', selectedCurrency)
        : orders
            .where((o) => !o.isApproved)
            .fold(
              0.0,
              (sum, o) =>
                  sum +
                  CurrencyUtils.convertAmount(
                    o.commissionAmountTotal,
                    o.currency,
                    selectedCurrency,
                  ),
            );

    final double balance = apiBalance != null
        ? CurrencyUtils.convertAmount(apiBalance, 'AED', selectedCurrency)
        : (credit - debit);

    final displayCurrency = selectedCurrency == '-- Select Currency --'
        ? 'AED'
        : selectedCurrency;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.trending_up,
            iconColor: AppColors.approvedGreen,
            title: '$displayCurrency ${credit.toStringAsFixed(2)}',
            subtitle: 'Total Credit',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.trending_down,
            iconColor: Colors.redAccent,
            title: '$displayCurrency ${debit.toStringAsFixed(2)}',
            subtitle: 'Total Debit',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.account_balance,
            iconColor: AppColors.accentBlue,
            title: '$displayCurrency ${balance.toStringAsFixed(2)}',
            subtitle: 'Total Balance',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildSalespersonDropdown(
    BuildContext context,
    WidgetRef ref,
    List<Salesperson> salespersons,
    String? selectedId,
  ) {
    final validSalespersons = salespersons
        .where((s) => s.validId != null)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedId,
          isExpanded: true,
          hint: const Text(
            'Select Salesperson',
            style: TextStyle(color: AppColors.textGrey),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.primaryBlue,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Select a Referral',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            ...validSalespersons.map(
              (s) => DropdownMenuItem<String?>(
                value: s.validId,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      s.validId ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (value) {
            ref.read(allReferralOrdersSalespersonIdProvider.notifier).state =
                value;
          },
        ),
      ),
    );
  }

  List<ReferralMonthOrders> _groupReferralsByMonth(List<AdminReferralOrder> orders) {
    final Map<String, List<AdminReferralOrder>> grouped = {};
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    for (final order in orders) {
      final date = DateTime.tryParse(order.invoiceDate);
      final String key;
      if (date != null) {
        key = '${monthNames[date.month - 1]} ${date.year}';
      } else {
        key = 'Unknown Month';
      }
      grouped.putIfAbsent(key, () => []).add(order);
    }

    final list = grouped.entries.map((entry) {
      final monthOrders = entry.value;
      final totalAmount = monthOrders.fold(0.0, (sum, o) => sum + o.commissionAmountTotal);
      return ReferralMonthOrders(
        monthName: entry.key,
        orders: monthOrders,
        totalAmount: totalAmount,
        orderCount: monthOrders.length,
      );
    }).toList();

    list.sort((a, b) {
      final firstA = a.orders.isNotEmpty ? DateTime.tryParse(a.orders.first.invoiceDate) : null;
      final firstB = b.orders.isNotEmpty ? DateTime.tryParse(b.orders.first.invoiceDate) : null;
      if (firstA == null && firstB == null) return 0;
      if (firstA == null) return 1;
      if (firstB == null) return -1;
      return firstB.compareTo(firstA);
    });

    return list;
  }

  Widget _buildMonthGroupCard(
    BuildContext context,
    WidgetRef ref,
    ReferralMonthOrders monthData,
    String selectedCurrency,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          shape: const Border(),
          iconColor: AppColors.primaryBlue,
          collapsedIconColor: AppColors.primaryBlue,
          backgroundColor: Colors.white,
          title: Text(
            monthData.monthName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.approvedGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Comm. Total: ${selectedCurrency == "-- Select Currency --" ? "AED" : selectedCurrency} ${CurrencyUtils.convertAmount(monthData.totalAmount, "AED", selectedCurrency).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.approvedGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${monthData.orderCount} Orders',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: monthData.orders
                    .map(
                      (order) => _buildOrderTile(
                        context,
                        ref,
                        order,
                        selectedCurrency,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(
    BuildContext context,
    WidgetRef ref,
    AdminReferralOrder order,
    String selectedCurrency,
  ) {
    final String platformText =
        order.platform == 'False' || order.platform.isEmpty
        ? 'Pending'
        : order.platform;

    Color badgeColor = AppColors.pendingYellow;
    if (platformText.toLowerCase().contains('subscription')) {
      badgeColor = AppColors.primaryBlue;
    } else if (platformText.toLowerCase().contains('project')) {
      badgeColor = AppColors.secondaryTeal;
    } else if (order.isApproved) {
      badgeColor = AppColors.approvedGreen;
    }

    String formattedDate = order.invoiceDate.isEmpty
        ? 'N/A'
        : order.invoiceDate;
    final parsedDate = DateTime.tryParse(order.invoiceDate);
    if (parsedDate != null) {
      final day = parsedDate.day.toString().padLeft(2, '0');
      final month = parsedDate.month.toString().padLeft(2, '0');
      formattedDate = '$day/$month/${parsedDate.year}';
    }

    final commVal = order.commissionAmountTotal;
    final commText = commVal.toStringAsFixed(2);
    final displayCurrency = order.currency;

    final selectedSet = ref.watch(selectedReferralsProvider);
    final bool isSelected = order.id != null && selectedSet.contains(order.id);
    final bool isApproved = order.isApproved;
    final bool showCheckbox = order.id != null && !isApproved;

    return GestureDetector(
      onTap: () => _showOrderDetailsBottomSheet(context, ref, order, selectedCurrency),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.5)
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCheckbox) ...[
              Padding(
                padding: const EdgeInsets.only(right: 12.0, top: 4.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (bool? checked) {
                      final current = ref.read(selectedReferralsProvider);
                      final newSet = Set<int>.from(current);
                      if (checked == true) {
                        newSet.add(order.id!);
                      } else {
                        newSet.remove(order.id!);
                      }
                      ref.read(selectedReferralsProvider.notifier).state =
                          newSet;
                    },
                  ),
                ),
              ),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inv Date:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          platformText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reference No:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.invoiceReferenceNo,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E2B7B),
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Commission:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$displayCurrency $commText',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (order.referralDetails.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                      'Referral Agents (${order.referralDetails.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGrey,
                      ),
                    ),
                    ...order.referralDetails.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 14,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                r.salespersonName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              '${r.currency} ${r.commissionAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.approvedGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetailsBottomSheet(
    BuildContext context,
    WidgetRef ref,
    AdminReferralOrder order,
    String selectedCurrency,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        String formattedDate = order.invoiceDate.isEmpty
            ? 'N/A'
            : order.invoiceDate;
        final parsedDate = DateTime.tryParse(order.invoiceDate);
        if (parsedDate != null) {
          final day = parsedDate.day.toString().padLeft(2, '0');
          final month = parsedDate.month.toString().padLeft(2, '0');
          formattedDate = '$day/$month/${parsedDate.year}';
        }

        final displayCurrency = selectedCurrency == '-- Select Currency --'
            ? order.currency
            : selectedCurrency;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (sheetScrollContext, scrollController) {
            return Consumer(
              builder: (consumerContext, sheetRef, child) {
                final selectedSet = sheetRef.watch(selectedReferralsProvider);
                final bool isSelected =
                    order.id != null && selectedSet.contains(order.id);
                final bool isApproved = order.isApproved;
                final bool canApprove = order.id != null && !isApproved;

                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          order.invoiceReferenceNo,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Invoice Date: $formattedDate',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        _detailRow(
                          Icons.person,
                          'Customer',
                          order.customerName,
                        ),
                        const SizedBox(height: 8),
                        _detailRow(
                          Icons.business,
                          'Company',
                          order.companyName.isNotEmpty
                              ? order.companyName
                              : 'N/A',
                        ),
                        const SizedBox(height: 8),
                        _detailRow(
                          Icons.badge,
                          'Salesperson',
                          order.salespersonName,
                        ),
                        const SizedBox(height: 16),
                        if (order.referralDetails.isNotEmpty) ...[
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          const Text(
                            'Referral Agents',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...order.referralDetails.map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.salespersonName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          r.salespersonEmail,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textGrey,
                                          ),
                                        ),
                                        Text(
                                          '${r.currency} ${r.commissionAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.approvedGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Commission:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.approvedGreen,
                              ),
                            ),
                            Text(
                              '$displayCurrency ${CurrencyUtils.convertAmount(order.commissionAmountTotal, order.currency, selectedCurrency).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.approvedGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (canApprove) ...[
                          const Divider(height: 1),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final current = sheetRef.read(
                                      selectedReferralsProvider,
                                    );
                                    final newSet = Set<int>.from(current);
                                    if (isSelected) {
                                      newSet.remove(order.id!);
                                    } else {
                                      newSet.add(order.id!);
                                    }
                                    sheetRef
                                        .read(
                                          selectedReferralsProvider
                                              .notifier,
                                        )
                                        .state =
                                    newSet;
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.primaryBlue,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: Icon(
                                    isSelected
                                        ? Icons.remove_circle_outline
                                        : Icons.add_circle_outline,
                                    color: AppColors.primaryBlue,
                                  ),
                                  label: Text(
                                    isSelected
                                        ? 'Remove Selection'
                                        : 'Select for Bulk',
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(bottomSheetContext);
                                    _showBulkApprovalConfirmDialog(
                                      context,
                                      ref,
                                      {order.id!},
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.approvedGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Approve Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textGrey,
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    if (error is PermissionDeniedException) {
      return PermissionDeniedWidget(
        message: error.message,
        onBack: () {
          Navigator.pop(context);
        },
      );
    }
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                    // ignore: unused_result
                    ref.refresh(allReferralOrdersProvider.future);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approveReferrals(
    BuildContext context,
    WidgetRef ref,
    Set<int> referralIdsToApprove,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
                SizedBox(height: 16),
                Text(
                  'Approving referrals...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final authState = ref.read(authNotifierProvider);
      final token = authState.session?.accessToken ?? '';
      final service = ref.read(adminServiceProvider);

      final payload = referralIdsToApprove.map((id) => {'id': id}).toList();

      // Find and detail the referrals being approved for logging
      final List<String> detailsLog = [];
      try {
        final referralData = ref.read(allReferralOrdersProvider).value;
        if (referralData != null) {
          for (final id in referralIdsToApprove) {
            AdminReferralOrder? matchedOrder;
            for (final order in referralData.orders) {
              if (order.id == id) {
                matchedOrder = order;
                break;
              }
            }

            if (matchedOrder != null) {
              final refsDetailsStr = matchedOrder.referralDetails.map((refD) {
                return '      * Partner: ${refD.salespersonName} (${refD.salespersonEmail})\n'
                    '        Type: ${refD.type}\n'
                    '        Percentage: ${refD.percentage}%\n'
                    '        Fixed Amount: ${refD.fixedAmount} ${refD.currency}\n'
                    '        Calculated Commission: ${refD.commissionAmount} ${refD.currency}';
              }).join('\n');

              detailsLog.add(
                '  - Referral Order ID: $id\n'
                '    - Invoice Ref: ${matchedOrder.invoiceReferenceNo}\n'
                '    - Customer: ${matchedOrder.customerName}\n'
                '    - Platform/Label: ${matchedOrder.platform}\n'
                '    - Company: ${matchedOrder.companyName}\n'
                '    - Total Commission: ${matchedOrder.commissionAmountTotal} ${matchedOrder.currency}\n'
                '    - Referral Details:\n$refsDetailsStr'
              );
            } else {
              detailsLog.add(
                '  - Referral Order ID: $id (Details not found in cached referral orders)'
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error compiling detailed referral approval log: $e');
      }

      final adminUrl = await ApiConfig.getAdminFullUrl('/api/v1/dashboard/submit-referral-approvals/');

      debugPrint('══════════════════════════════════════════════════════════════════════');
      debugPrint('📝 [ADMIN REFERRAL APPROVAL] Referral Order Approve Clicked');
      debugPrint('Timestamp: ${DateTime.now().toLocal()}');
      debugPrint('Total Referrals to Approve: ${referralIdsToApprove.length}');
      debugPrint('----------------------------------------------------------------------');
      if (detailsLog.isNotEmpty) {
        debugPrint(detailsLog.join('\n----------------------------------------------------------------------\n'));
      } else {
        debugPrint('Referral order IDs to approve: $referralIdsToApprove');
      }
      debugPrint('----------------------------------------------------------------------');
      debugPrint('API Request Details:');
      debugPrint('  - HTTP Method: POST');
      debugPrint('  - URL: $adminUrl');
      debugPrint('  - Payload: {"selectedReferrals": $payload}');
      debugPrint('══════════════════════════════════════════════════════════════════════');

      await service.submitReferralApprovals(token, payload);

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Referrals approved successfully!'),
              ],
            ),
            backgroundColor: AppColors.approvedGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final currentSelection = Set<int>.from(ref.read(selectedReferralsProvider));
      currentSelection.removeAll(referralIdsToApprove);
      ref.read(selectedReferralsProvider.notifier).state = currentSelection;

      ref.invalidate(allReferralOrdersProvider);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      final String errorStr = e.toString();
      final bool isReportError = errorStr.contains('SalesIncentiveReport');

      if (isReportError) {
        // Since the database update succeeded, handle it as a partial success
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Referrals approved, but server failed to update the incentive report.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Clear the selection for approved referrals
        final currentSelection = Set<int>.from(ref.read(selectedReferralsProvider));
        currentSelection.removeAll(referralIdsToApprove);
        ref.read(selectedReferralsProvider.notifier).state = currentSelection;

        // Refresh orders to show the approved status
        ref.invalidate(allReferralOrdersProvider);
      } else {
        if (context.mounted) {
          String displayMsg = errorStr;
          if (e is PermissionDeniedException) {
            displayMsg = e.message;
          } else {
            displayMsg = displayMsg.replaceAll('Exception: ', '').replaceAll('PermissionDeniedException: ', '');
          }

          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Approval Failed'),
              content: Text(displayMsg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _showBulkApprovalConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Set<int> referralIds,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirm Approval'),
          ],
        ),
        content: Text(
          referralIds.length == 1
              ? 'Are you sure you want to approve this referral order?'
              : 'Are you sure you want to approve ${referralIds.length} selected referral orders?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _approveReferrals(context, ref, referralIds);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.approvedGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}
