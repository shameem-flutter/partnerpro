import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/admin_models.dart';
import '../../models/dashboard_data.dart';
import '../../theme/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/api_config.dart';
import '../../widgets/permission_denied_widget.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/admin_currency_dropdown.dart';

class AdminAllSalespersonOrdersScreen extends ConsumerWidget {
  const AdminAllSalespersonOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allSalespersonOrdersProvider);
    final selectedId = ref.watch(selectedSalespersonIdProvider);
    final selectedCurrency = ref.watch(adminCurrencyProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context, ref),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(allSalespersonOrdersProvider.future),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue,
                      ),
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
          final selectedMap = ref.watch(selectedInvoicesProvider);
          if (selectedMap.isEmpty) return const SizedBox.shrink();

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                          '${selectedMap.length} Invoices Selected',
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
                      ref.read(selectedInvoicesProvider.notifier).state = {};
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _showBulkApprovalConfirmDialog(context, ref, selectedMap);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.approvedGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Approve Bulk',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
            'All Salesperson Orders',
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
    AllSalespersonOrdersResponse data,
    String? selectedId,
    String selectedCurrency,
  ) {
    // Only salespersons with a valid ID
    final validSalespersons = data.salespersons
        .where((s) => s.validId != null)
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref.refresh(allSalespersonOrdersProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // Dropdown Row
            // ----------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: _buildSalespersonDropdown(
                    context,
                    ref,
                    validSalespersons,
                    selectedId,
                  ),
                ),
                const SizedBox(width: 12),
                const AdminCurrencyDropdown(),
              ],
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // Summary Cards
            // ----------------------------------------------------------------
            _buildSummaryRow(data, selectedCurrency),
            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // Orders by Month
            // ----------------------------------------------------------------
            _buildSectionHeader('Orders Summary'),
            const SizedBox(height: 12),
            if (data.ordersByMonth.isEmpty)
              _buildEmptyCard(
                'No order data available for the selected salesperson.',
              )
            else
              ...data.ordersByMonth.map(
                (monthData) => _buildMonthGroupCard(
                  context,
                  ref,
                  monthData,
                  selectedCurrency,
                ),
              ),
          ],
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
            'Select a Salesperson',
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
                'Select Salesperson',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            ...salespersons.map(
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
            ref.read(selectedSalespersonIdProvider.notifier).state = value;
          },
        ),
      ),
    );
  }



  Widget _buildSummaryRow(
    AllSalespersonOrdersResponse data,
    String selectedCurrency,
  ) {
    final convertedCredit = CurrencyUtils.convertAmount(
      data.totalCredit,
      'AED',
      selectedCurrency,
    );
    final convertedDebit = CurrencyUtils.convertAmount(
      data.totalDebit,
      'AED',
      selectedCurrency,
    );
    final convertedBalance = CurrencyUtils.convertAmount(
      data.totalBalance,
      'AED',
      selectedCurrency,
    );
    final displayCurrency = selectedCurrency == '-- Select Currency --'
        ? 'AED'
        : selectedCurrency;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.trending_up,
            iconColor: AppColors.approvedGreen,
            title: '$displayCurrency ${convertedCredit.toStringAsFixed(2)}',
            subtitle: 'Total Credit',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.trending_down,
            iconColor: Colors.redAccent,
            title: '$displayCurrency ${convertedDebit.toStringAsFixed(2)}',
            subtitle: 'Total Debit',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.account_balance,
            iconColor: AppColors.accentBlue,
            title: '$displayCurrency ${convertedBalance.toStringAsFixed(2)}',
            subtitle: 'Balance',
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

  // Widget _buildPlatformChip(String platform) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: AppColors.primaryBlue.withValues(alpha: 0.08),
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(
  //         color: AppColors.primaryBlue.withValues(alpha: 0.25),
  //       ),
  //     ),
  //     child: Text(
  //       platform,
  //       style: const TextStyle(
  //         color: AppColors.primaryBlue,
  //         fontSize: 12,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildMonthGroupCard(
    BuildContext context,
    WidgetRef ref,
    AdminMonthOrders monthData,
    String selectedCurrency,
  ) {
    final selectedMap = ref.watch(selectedInvoicesProvider);
    double dynamicMonthTotal = 0.0;

    for (final order in monthData.orders) {
      final hasPendingInvoices = order.invoiceDetails.any(
        (d) => d.id != null && !d.isApproved,
      );

      double orderCommission = 0.0;
      if (!hasPendingInvoices) {
        orderCommission = CurrencyUtils.convertAmount(
          order.commissionAmountTotal,
          order.currency,
          "AED",
        );
      } else {
        for (final detail in order.invoiceDetails) {
          final int? invoiceId = detail.id;
          final bool isSelectable = invoiceId != null && !detail.isApproved;
          final bool isSelected =
              isSelectable && selectedMap.containsKey(invoiceId);

          final double currentPercentage = isSelected
              ? selectedMap[invoiceId]!
              : (detail.commissionPercentage ?? 5.0);

          final double convertedSubtotal = CurrencyUtils.convertAmount(
            detail.subtotal,
            order.currency,
            "AED",
          );
          orderCommission += convertedSubtotal * (currentPercentage / 100);
        }

        if (orderCommission == 0.0 && order.commissionAmountTotal > 0) {
          orderCommission = CurrencyUtils.convertAmount(
            order.commissionAmountTotal,
            order.currency,
            "AED",
          );
        }
      }
      dynamicMonthTotal += orderCommission;
    }

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
                    'Comm. Total: ${selectedCurrency == "-- Select Currency --" ? "AED" : selectedCurrency} ${CurrencyUtils.convertAmount(dynamicMonthTotal, "AED", selectedCurrency).toStringAsFixed(2)}',
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
    DashboardOrder order,
    String selectedCurrency,
  ) {
    final String statusText = order.isApproved ? 'Approved' : 'Pending';
    final Color badgeColor = order.isApproved ? AppColors.approvedGreen : AppColors.pendingYellow;

    String formattedDate = order.invoiceDate;
    final parsedDate = DateTime.tryParse(order.invoiceDate);
    if (parsedDate != null) {
      final day = parsedDate.day.toString().padLeft(2, '0');
      final month = parsedDate.month.toString().padLeft(2, '0');
      final year = parsedDate.year;
      formattedDate = '$day/$month/$year';
    }

    final refText = order.invoiceReferenceNo;
    final displayCurrency = selectedCurrency == '-- Select Currency --'
        ? (order.currency.isEmpty || order.currency == "False"
              ? "AED"
              : order.currency)
        : selectedCurrency;

    final orderInvoiceIds = order.invoiceDetails
        .map((d) => d.id)
        .whereType<int>()
        .toList();

    final selectedMap = ref.watch(selectedInvoicesProvider);
    final selectedCountInOrder = selectedMap.keys
        .where((id) => orderInvoiceIds.contains(id))
        .length;

    return GestureDetector(
      onTap: () =>
          _showOrderDetailsBottomSheet(context, ref, order, selectedCurrency),
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
            color: selectedCountInOrder > 0
                ? AppColors.primaryBlue.withValues(alpha: 0.5)
                : Colors.grey.shade200,
            width: selectedCountInOrder > 0 ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (selectedCountInOrder > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
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
                    statusText,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reference no:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        refText,
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
                      'Total Amount:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$displayCurrency ${CurrencyUtils.convertAmount(order.totalSubtotal, order.currency, selectedCurrency).toStringAsFixed(2)}',
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
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
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
                          order.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.badge,
                      size: 14,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.salespersonName.isNotEmpty
                          ? order.salespersonName
                          : 'N/A',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.computer,
                  size: 14,
                  color: AppColors.textGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Platform: ${order.platform == "False" || order.platform.isEmpty ? 'N/A' : order.platform}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetailsBottomSheet(
    BuildContext context,
    WidgetRef ref,
    DashboardOrder order,
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
        final String statusText = order.isApproved ? 'Approved' : 'Pending';
        final Color badgeColor = order.isApproved ? AppColors.approvedGreen : AppColors.pendingYellow;

        String formattedDate = order.invoiceDate;
        final parsedDate = DateTime.tryParse(order.invoiceDate);
        if (parsedDate != null) {
          final day = parsedDate.day.toString().padLeft(2, '0');
          final month = parsedDate.month.toString().padLeft(2, '0');
          final year = parsedDate.year;
          formattedDate = '$day/$month/$year';
        }

        final String curText = selectedCurrency == '-- Select Currency --'
            ? (order.currency.isEmpty || order.currency == "False"
                  ? "AED"
                  : order.currency)
            : selectedCurrency;

        return Consumer(
          builder: (consumerContext, sheetRef, child) {
            final orderInvoiceIds = order.invoiceDetails
                .map((d) => d.id)
                .whereType<int>()
                .toList();

            final selectedMap = sheetRef.watch(selectedInvoicesProvider);
            final orderSelectedInvoices = Map<int, double>.fromEntries(
              selectedMap.entries.where((e) => orderInvoiceIds.contains(e.key)),
            );

            final hasPendingInvoices = order.invoiceDetails.any(
              (d) => d.id != null && !d.isApproved,
            );

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (sheetScrollContext, scrollController) {
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.invoiceReferenceNo,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Invoice Date: $formattedDate',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        const Text(
                          'Participants',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.person,
                          label: 'Customer',
                          value: order.customerName,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.business,
                          label: 'Company',
                          value: order.companyName.isNotEmpty
                              ? order.companyName
                              : 'N/A',
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.badge,
                          label: 'Salesperson',
                          value: order.salespersonName,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.computer,
                          label: 'Platform',
                          value: order.platform.isEmpty || order.platform == "False" ? 'N/A' : order.platform,
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        const Text(
                          'Order Items / Invoices',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...order.invoiceDetails.map((detail) {
                          final bool isApproved = detail.isApproved;
                          final int? invoiceId = detail.id;
                          final bool isSelectable =
                              invoiceId != null && !isApproved;

                          final bool isSelected =
                              isSelectable &&
                              selectedMap.containsKey(invoiceId);
                          final double currentPercentage = isSelected
                              ? selectedMap[invoiceId]!
                              : (detail.commissionPercentage ?? 5.0);

                          void toggleSelection() {
                            if (!isSelectable) return;
                            final newMap = Map<int, double>.from(
                              sheetRef.read(selectedInvoicesProvider),
                            );
                            if (isSelected) {
                              newMap.remove(invoiceId);
                            } else {
                              newMap[invoiceId] =
                                  detail.commissionPercentage ?? 5.0;
                            }
                            sheetRef
                                    .read(selectedInvoicesProvider.notifier)
                                    .state =
                                newMap;
                          }

                          void updatePercentage(double val) {
                            if (!isSelected) return;
                            final newMap = Map<int, double>.from(
                              sheetRef.read(selectedInvoicesProvider),
                            );
                            newMap[invoiceId] = val;
                            sheetRef
                                    .read(selectedInvoicesProvider.notifier)
                                    .state =
                                newMap;
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue.withValues(
                                      alpha: 0.03,
                                    )
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.grey.shade200,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (isSelectable)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: isSelected,
                                            activeColor: AppColors.primaryBlue,
                                            onChanged: (val) =>
                                                toggleSelection(),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            detail.productName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (detail.invoiceDate != null)
                                            Text(
                                              'Date: ${detail.invoiceDate} | State: ${detail.paymentState ?? ''}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textGrey,
                                              ),
                                            )
                                          else
                                            Text(
                                              'Qty: ${detail.quantity} x $curText ${CurrencyUtils.convertAmount(detail.unitPrice, order.currency, selectedCurrency).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textGrey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$curText ${CurrencyUtils.convertAmount(detail.subtotal, order.currency, selectedCurrency).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (isApproved)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.approvedGreen
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.check,
                                                  size: 10,
                                                  color:
                                                      AppColors.approvedGreen,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'Approved (${detail.commissionPercentage?.toStringAsFixed(1) ?? '0.0'}%)',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        AppColors.approvedGreen,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.pendingYellow
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Pending Approval',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.pendingYellow,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (isSelected) ...[
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Lock Commission %:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 20,
                                            ),
                                            color: AppColors.primaryBlue,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              if (currentPercentage > 0) {
                                                updatePercentage(
                                                  double.parse(
                                                    (currentPercentage - 0.5)
                                                        .toStringAsFixed(1),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          Container(
                                            width: 55,
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${currentPercentage.toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 20,
                                            ),
                                            color: AppColors.primaryBlue,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              if (currentPercentage < 100) {
                                                updatePercentage(
                                                  double.parse(
                                                    (currentPercentage + 0.5)
                                                        .toStringAsFixed(1),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '$curText ${CurrencyUtils.convertAmount(order.totalSubtotal, order.currency, selectedCurrency).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            double dynamicCommission = 0.0;
                            for (final detail in order.invoiceDetails) {
                              final int? invoiceId = detail.id;
                              final bool isSelectable =
                                  invoiceId != null && !detail.isApproved;
                              final bool isSelected =
                                  isSelectable &&
                                  selectedMap.containsKey(invoiceId);

                              final double currentPercentage = isSelected
                                  ? selectedMap[invoiceId]!
                                  : (detail.commissionPercentage ?? 5.0);

                              final double convertedSubtotal =
                                  CurrencyUtils.convertAmount(
                                    detail.subtotal,
                                    order.currency,
                                    selectedCurrency,
                                  );
                              dynamicCommission +=
                                  convertedSubtotal * (currentPercentage / 100);
                            }

                            // If dynamic calculation results in 0 (e.g. if the backend doesn't provide
                            // invoice-level percentages for approved orders), fallback to the total from backend
                            if (dynamicCommission == 0.0 && order.commissionAmountTotal > 0) {
                              dynamicCommission = CurrencyUtils.convertAmount(
                                order.commissionAmountTotal,
                                order.currency,
                                selectedCurrency,
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Commission Earned:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.approvedGreen,
                                  ),
                                ),
                                Text(
                                  hasPendingInvoices
                                      ? '$curText ${dynamicCommission.toStringAsFixed(2)}'
                                      : '${selectedCurrency == "-- Select Currency --" ? "AED" : selectedCurrency} ${CurrencyUtils.convertAmount(order.commissionAmountTotal, "AED", selectedCurrency).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.approvedGreen,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        if (hasPendingInvoices) ...[
                          const Divider(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: orderSelectedInvoices.isEmpty
                                  ? null
                                  : () {
                                      Navigator.pop(bottomSheetContext);
                                      _approveInvoices(
                                        context,
                                        ref,
                                        orderSelectedInvoices,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.approvedGreen,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              label: Text(
                                orderSelectedInvoices.isEmpty
                                    ? 'Select Invoices to Approve'
                                    : 'Approve Selected (${orderSelectedInvoices.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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

  Future<void> _approveInvoices(
    BuildContext context,
    WidgetRef ref,
    Map<int, double> invoicesToApprove,
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Approving invoices...',
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

      final payload = invoicesToApprove.entries
          .map(
            (entry) => {'id': entry.key, 'commission_percentage': entry.value},
          )
          .toList();

      // Find and detail the invoices being approved for logging
      final List<String> detailsLog = [];
      try {
        final ordersData = ref.read(allSalespersonOrdersProvider).value;
        if (ordersData != null) {
          for (final entry in invoicesToApprove.entries) {
            final int id = entry.key;
            final double targetCommPct = entry.value;

            InvoiceDetail? matchedDetail;
            DashboardOrder? matchedOrder;

            for (final monthOrders in ordersData.ordersByMonth) {
              for (final order in monthOrders.orders) {
                for (final detail in order.invoiceDetails) {
                  if (detail.id == id) {
                    matchedDetail = detail;
                    matchedOrder = order;
                    break;
                  }
                }
                if (matchedDetail != null) break;
              }
              if (matchedDetail != null) break;
            }

            if (matchedDetail != null && matchedOrder != null) {
              detailsLog.add(
                '  - Invoice ID: $id\n'
                '    - Product: ${matchedDetail.productName}\n'
                '    - Invoice Ref: ${matchedOrder.invoiceReferenceNo}\n'
                '    - Customer: ${matchedOrder.customerName}\n'
                '    - Salesperson: ${matchedOrder.salespersonName}\n'
                '    - Company: ${matchedOrder.companyName}\n'
                '    - Quantity: ${matchedDetail.quantity}\n'
                '    - Unit Price: ${matchedDetail.unitPrice} ${matchedOrder.currency}\n'
                '    - Subtotal: ${matchedDetail.subtotal} ${matchedOrder.currency}\n'
                '    - Original Comm %: ${matchedDetail.commissionPercentage ?? "N/A"}%\n'
                '    - Approving Comm %: $targetCommPct%\n'
                '    - Calculated Comm Amount: ${(matchedDetail.subtotal * targetCommPct / 100).toStringAsFixed(2)} ${matchedOrder.currency}',
              );
            } else {
              detailsLog.add(
                '  - Invoice ID: $id\n'
                '    - Approving Comm %: $targetCommPct% (Details not found in cached orders)',
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error compiling detailed approval log: $e');
      }

      final adminUrl = await ApiConfig.getAdminFullUrl(
        '/api/v1/dashboard/submit-selected-invoices/',
      );

      debugPrint(
        '══════════════════════════════════════════════════════════════════════',
      );
      debugPrint('📝 [ADMIN APPROVAL] "Approve Selected" Button Clicked');
      debugPrint('Timestamp: ${DateTime.now().toLocal()}');
      debugPrint('Total Invoices to Approve: ${invoicesToApprove.length}');
      debugPrint(
        '----------------------------------------------------------------------',
      );
      if (detailsLog.isNotEmpty) {
        debugPrint(
          detailsLog.join(
            '\n----------------------------------------------------------------------\n',
          ),
        );
      } else {
        debugPrint('Invoices to approve payload: $invoicesToApprove');
      }
      debugPrint(
        '----------------------------------------------------------------------',
      );
      debugPrint('API Request Details:');
      debugPrint('  - HTTP Method: POST');
      debugPrint('  - URL: $adminUrl');
      debugPrint('  - Payload: {"selectedInvoices": $payload}');
      debugPrint(
        '══════════════════════════════════════════════════════════════════════',
      );

      await service.submitSelectedInvoices(token, payload);

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Invoices approved successfully!'),
              ],
            ),
            backgroundColor: AppColors.approvedGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final currentSelection = Map<int, double>.from(
        ref.read(selectedInvoicesProvider),
      );
      for (final id in invoicesToApprove.keys) {
        currentSelection.remove(id);
      }
      ref.read(selectedInvoicesProvider.notifier).state = currentSelection;

      ref.invalidate(allSalespersonOrdersProvider);
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
                      'Invoices approved, but server failed to update the incentive report.',
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

        // Clear the selection for approved invoices
        final currentSelection = Map<int, double>.from(
          ref.read(selectedInvoicesProvider),
        );
        for (final id in invoicesToApprove.keys) {
          currentSelection.remove(id);
        }
        ref.read(selectedInvoicesProvider.notifier).state = currentSelection;

        // Refresh orders to show the approved status
        ref.invalidate(allSalespersonOrdersProvider);
      } else {
        if (context.mounted) {
          String displayMsg = errorStr;
          if (e is PermissionDeniedException) {
            displayMsg = e.message;
          } else {
            displayMsg = displayMsg
                .replaceAll('Exception: ', '')
                .replaceAll('PermissionDeniedException: ', '');
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
    Map<int, double> invoices,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Bulk Approval'),
          ],
        ),
        content: Text(
          'Are you sure you want to approve ${invoices.length} selected invoices with their locked commission percentages?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _approveInvoices(context, ref, invoices);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.approvedGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
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
    // Permission denied — show friendly locked UI
    if (error is PermissionDeniedException) {
      return PermissionDeniedWidget(
        message: error.message,
        onBack: () {
          Navigator.pop(context);
        },
      );
    }

    // Generic error
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
                  onPressed: () =>
                      // ignore: unused_result
                      ref.refresh(allSalespersonOrdersProvider.future),
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
}
