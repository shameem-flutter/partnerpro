import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_data.dart';
import '../models/view_more_data.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';

class ViewMoreScreen extends ConsumerWidget {
  const ViewMoreScreen({super.key});

  static double convertAmount(
    double amount,
    String fromCurrency,
    String targetCurrency,
  ) {
    final cleanFrom = (fromCurrency.isEmpty || fromCurrency == 'False')
        ? 'AED'
        : fromCurrency.toUpperCase();
    final cleanTarget =
        (targetCurrency == '-- Select Currency --' || targetCurrency.isEmpty)
        ? cleanFrom
        : targetCurrency.toUpperCase();

    if (cleanFrom == cleanTarget) return amount;

    // Rates relative to AED (1 AED = X currency)
    final rates = {
      'AED': 1.0,
      'USD': 0.27226,
      'INR': 22.68,
      'OMR': 0.1049,
      'SAR': 1.0215,
    };

    final rateFrom = rates[cleanFrom] ?? 1.0;
    final rateTo = rates[cleanTarget] ?? 1.0;

    final amountInAED = amount / rateFrom;
    return amountInAED * rateTo;
  }

  static const List<String> _currencies = [
    '-- Select Currency --',
    'USD',
    'INR',
    'OMR',
    'AED',
    'SAR',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMoreAsync = ref.watch(viewMoreDataProvider);
    final filterState = ref.watch(viewMoreFilterProvider);
    final filterNotifier = ref.read(viewMoreFilterProvider.notifier);

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
            onPressed: () => ref.read(navigationProvider.notifier).state = ActiveScreen.dashboard,
          ),
        title: const Text(
          'Detailed Statement',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(viewMoreDataProvider.future),
          child: (() {
            if (viewMoreAsync.hasValue) {
              final data = viewMoreAsync.value!;
              return _buildContent(context, ref, data, filterState, filterNotifier);
            } else if (viewMoreAsync.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              );
            } else {
              return _buildErrorState(context, ref, viewMoreAsync.error?.toString() ?? 'Unknown error');
            }
          })(),
        ),
      ),
    ),);
  }

  Widget _buildCurrencyDropdown(
    WidgetRef ref,
    ViewMoreFilterState filterState,
    ViewMoreFilterNotifier filterNotifier,
  ) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: filterState.selectedCurrency,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.primaryBlue,
          ),
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              filterNotifier.setCurrency(newValue);
            }
          },
          items: _currencies.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ViewMoreResponse data,
    ViewMoreFilterState filterState,
    ViewMoreFilterNotifier filterNotifier,
  ) {
    final platforms = data.availablePlatforms.toSet().toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statement by Month',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to expand or filter below.',
                      style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              _buildCurrencyDropdown(ref, filterState, filterNotifier),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Chips
          if (platforms.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      'All Platforms',
                      style: TextStyle(
                        color: filterState.selectedPlatform == null
                            ? Colors.white
                            : AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: filterState.selectedPlatform == null,
                    selectedColor: AppColors.primaryBlue,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: filterState.selectedPlatform == null
                          ? AppColors.primaryBlue
                          : Colors.grey.shade300,
                    ),
                    onSelected: (selected) {
                      filterNotifier.setPlatform(null);
                    },
                  ),
                  ...platforms.map((platform) {
                    final isSelected = filterState.selectedPlatform == platform;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          platform,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primaryBlue,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.grey.shade300,
                        ),
                        onSelected: (selected) {
                          filterNotifier.setPlatform(selected ? platform : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: data.months.isEmpty
                ? const Center(
                    child: Text(
                      'No orders found.',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: data.months.length,
                    itemBuilder: (context, index) {
                      final monthData = data.months[index];

                      final filteredOrders = filterState.selectedPlatform == null
                          ? monthData.orders
                          : monthData.orders
                                .where(
                                  (o) =>
                                      o.platform.toLowerCase() ==
                                      filterState.selectedPlatform!.toLowerCase(),
                                )
                                .toList();

                      if (filteredOrders.isEmpty &&
                          filterState.selectedPlatform != null) {
                        return const SizedBox.shrink();
                      }

                      return _buildMonthGroupCard(
                        context,
                        ref,
                        monthData,
                        filteredOrders,
                        filterState.selectedCurrency,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGroupCard(
    BuildContext context,
    WidgetRef ref,
    ViewMoreMonth monthData,
    List<DashboardOrder> displayOrders,
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
                    'Appr. Total: ${selectedCurrency == "-- Select Currency --" ? "AED" : selectedCurrency} ${convertAmount(monthData.approvedTotal, "AED", selectedCurrency).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.approvedGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${monthData.approvedCount} Approved',
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
                children: displayOrders
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
    final String platformText =
        order.platform == "False" || order.platform.isEmpty
            ? 'Pending'
            : order.platform;

    Color badgeColor = AppColors.pendingYellow;
    if (platformText.toLowerCase().contains('subscription')) {
      badgeColor = AppColors.primaryBlue;
    } else if (platformText.toLowerCase().contains('project')) {
      badgeColor = AppColors.secondaryTeal;
    } else if (platformText.toLowerCase() == 'approved') {
      badgeColor = AppColors.approvedGreen;
    }

    String formattedDate = order.invoiceDate;
    final parsedDate = DateTime.tryParse(order.invoiceDate);
    if (parsedDate != null) {
      final day = parsedDate.day.toString().padLeft(2, '0');
      final month = parsedDate.month.toString().padLeft(2, '0');
      final year = parsedDate.year;
      formattedDate = '$day/$month/$year';
    }

    final refText = order.invoiceReferenceNo;

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
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      '${selectedCurrency == "-- Select Currency --" ? ((order.currency.isEmpty || order.currency == "False") ? "AED" : order.currency) : selectedCurrency} ${order.isApproved ? convertAmount(order.totalSubtotal, order.currency, selectedCurrency).toStringAsFixed(2) : "0.00"}',
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
                      order.salespersonName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
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
      builder: (context) {
        final String platformText =
            order.platform == "False" || order.platform.isEmpty
                ? 'Pending'
                : order.platform;

        Color badgeColor = AppColors.pendingYellow;
        if (platformText.toLowerCase().contains('subscription')) {
          badgeColor = AppColors.primaryBlue;
        } else if (platformText.toLowerCase().contains('project')) {
          badgeColor = AppColors.secondaryTeal;
        } else if (platformText.toLowerCase() == 'approved') {
          badgeColor = AppColors.approvedGreen;
        }

        String formattedDate = order.invoiceDate;
        final parsedDate = DateTime.tryParse(order.invoiceDate);
        if (parsedDate != null) {
          final day = parsedDate.day.toString().padLeft(2, '0');
          final month = parsedDate.month.toString().padLeft(2, '0');
          final year = parsedDate.year;
          formattedDate = '$day/$month/$year';
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
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
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    const Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...order.invoiceDetails.map(
                      (detail) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detail.productName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Qty: ${detail.quantity} x ${selectedCurrency == "-- Select Currency --" ? ((order.currency.isEmpty || order.currency == "False") ? "AED" : order.currency) : selectedCurrency} ${order.isApproved ? convertAmount(detail.unitPrice, order.currency, selectedCurrency).toStringAsFixed(2) : "0.00"}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${selectedCurrency == "-- Select Currency --" ? ((order.currency.isEmpty || order.currency == "False") ? "AED" : order.currency) : selectedCurrency} ${order.isApproved ? convertAmount(detail.subtotal, order.currency, selectedCurrency).toStringAsFixed(2) : "0.00"}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                          '${selectedCurrency == "-- Select Currency --" ? ((order.currency.isEmpty || order.currency == "False") ? "AED" : order.currency) : selectedCurrency} ${order.isApproved ? convertAmount(order.totalSubtotal, order.currency, selectedCurrency).toStringAsFixed(2) : "0.00"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading statement details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(viewMoreDataProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
