import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/auth_user.dart';
import '../../models/dashboard_data.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/auth_session.dart';
import '../../utils/currency_utils.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _directLimit = 10;
  final int _referralLimit = 10;
  String _selectedCurrency = 'AED';
  int _selectedFilterDirect = 0; // 0: Total Commission, 1: Approved, 2: Pending
  int _selectedFilterReferral = 0; // 0: Total Commission, 1: Approved, 2: Pending



  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final appUserType = AppUserTypeMapper.fromString(widget.user.userType);
    final isEndUser = widget.user.userType == 'end_user';
    final isPublicUser = appUserType == AppUserType.publicUser;
    final isSingleTab = isEndUser || isPublicUser;

    Widget mainContent(DashboardData data) {
      if (isEndUser) {
        return _buildDashboardContent(context, data, isReferral: false);
      } else if (isPublicUser) {
        return _buildDashboardContent(context, data, isReferral: true);
      } else {
        return TabBarView(
          children: [
            _buildDashboardContent(context, data, isReferral: false),
            _buildDashboardContent(context, data, isReferral: true),
          ],
        );
      }
    }

    final scaffold = Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            ref.read(navigationProvider.notifier).state =
                ActiveScreen.dashboard;
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAASORDER',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'partnerPro',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.user.displayName,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(width: 10),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: isSingleTab
            ? null
            : const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: 'Direct Orders'),
                  Tab(text: 'Referral Orders'),
                ],
              ),
      ),
      endDrawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardDataProvider.future),
        child: (() {
          if (dashboardAsync.hasValue) {
            final data = dashboardAsync.value!;
            return mainContent(data);
          } else if (dashboardAsync.isLoading) {
            return SingleChildScrollView(
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
            );
          } else {
            return _buildErrorState(
              context,
              dashboardAsync.error?.toString() ?? 'Unknown error',
            );
          }
        })(),
      ),
    );

    if (isSingleTab) {
      return scaffold;
    }

    return DefaultTabController(length: 2, child: scaffold);
  }

  Widget _buildCurrencyDropdown() {
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
          value: _selectedCurrency,
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
              setState(() {
                _selectedCurrency = newValue;
              });
            }
          },
          items: CurrencyUtils.currencies.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    DashboardData data, {
    required bool isReferral,
  }) {
    final ordersList = isReferral ? data.referralOrders : data.orders;
    final selectedFilter = isReferral ? _selectedFilterReferral : _selectedFilterDirect;

    List<DashboardOrder> filteredOrders;
    String headerTitle;

    if (selectedFilter == 1) {
      filteredOrders = ordersList.where((o) => o.isApproved).toList();
      headerTitle = isReferral ? 'Approved Referral Orders' : 'Approved Orders';
    } else if (selectedFilter == 2) {
      filteredOrders = ordersList.where((o) => !o.isApproved).toList();
      headerTitle = isReferral ? 'Pending Referral Orders' : 'Pending Orders';
    } else {
      filteredOrders = ordersList;
      headerTitle = isReferral ? 'Referral Commission Orders' : 'Total Commission Orders';
    }

    final displayLimit = isReferral ? _referralLimit : _directLimit;

    final showList = isReferral
        ? filteredOrders
        : (displayLimit < filteredOrders.length
              ? filteredOrders.sublist(0, displayLimit)
              : filteredOrders);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardDataProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  _buildCurrencyDropdown(),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryCards(data, isReferral: isReferral),
              const SizedBox(height: 24),
              _buildRecentOrdersHeader(title: headerTitle),
              const SizedBox(height: 12),
              if (filteredOrders.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      selectedFilter == 1
                          ? (isReferral ? 'No approved referral orders found.' : 'No approved orders found.')
                          : selectedFilter == 2
                              ? (isReferral ? 'No pending referral orders found.' : 'No pending orders found.')
                              : (isReferral ? 'No referral orders found.' : 'No orders found.'),
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 16),
                    ),
                  ),
                )
              else ...[
                ...showList.map((order) => _buildOrderCard(order)),
                if (!isReferral && displayLimit < filteredOrders.length) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _directLimit += 10;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          'VIEW MORE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DashboardData data, {required bool isReferral}) {
    final double commission = isReferral
        ? data.totalCommissionRef
        : data.totalCommission;
    final int approved = isReferral
        ? data.refApprovedOrdersCount
        : data.approvedOrdersCount;
    final int pending = isReferral
        ? data.refPendingOrdersCount
        : data.pendingOrdersCount;

    final ordersList = isReferral ? data.referralOrders : data.orders;
    final String orderCurrency =
        ordersList.isNotEmpty && ordersList.first.currency.isNotEmpty
        ? ordersList.first.currency
        : 'AED';

    final String displayCurrency =
        _selectedCurrency == "-- Select Currency --" ? orderCurrency : _selectedCurrency;
    final double convertedCommission = CurrencyUtils.convertAmount(
      commission,
      orderCurrency,
      _selectedCurrency,
    );

    final selectedFilter = isReferral ? _selectedFilterReferral : _selectedFilterDirect;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            isSelected: selectedFilter == 0,
            onTap: () {
              setState(() {
                if (isReferral) {
                  _selectedFilterReferral = 0;
                } else {
                  _selectedFilterDirect = 0;
                }
              });
            },
            topWidget: Text(
              displayCurrency,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: selectedFilter == 0 ? AppColors.primaryBlue : Colors.black,
              ),
            ),
            title: convertedCommission.toStringAsFixed(2),
            subtitle: isReferral ? 'Referral\nCommission' : 'Total\nCommission',
            titleColor: selectedFilter == 0 ? AppColors.primaryBlue : Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            isSelected: selectedFilter == 1,
            onTap: () {
              setState(() {
                if (isReferral) {
                  _selectedFilterReferral = 1;
                } else {
                  _selectedFilterDirect = 1;
                }
              });
            },
            topWidget: const Icon(
              Icons.check_circle,
              color: AppColors.approvedGreen,
              size: 32,
            ),
            title: '$approved',
            subtitle: 'Approved\norders',
            titleColor: selectedFilter == 1 ? AppColors.approvedGreen : Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            isSelected: selectedFilter == 2,
            onTap: () {
              setState(() {
                if (isReferral) {
                  _selectedFilterReferral = 2;
                } else {
                  _selectedFilterDirect = 2;
                }
              });
            },
            topWidget: const Icon(
              Icons.access_time_filled,
              color: AppColors.pendingYellow,
              size: 32,
            ),
            title: '$pending',
            subtitle: 'Pending\norders',
            titleColor: selectedFilter == 2 ? const Color(0xFFD97706) : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required bool isSelected,
    required VoidCallback onTap,
    Widget? topWidget,
    required String title,
    required String subtitle,
    Color titleColor = Colors.black,
  }) {
    final activeColor = isSelected ? AppColors.primaryBlue : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activeColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (topWidget != null) topWidget else const SizedBox(height: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.primaryBlue : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersHeader({required String title}) {
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
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildOrderCard(DashboardOrder order) {
    final appUserType = AppUserTypeMapper.fromString(widget.user.userType);
    final isEndUser = widget.user.userType == 'end_user';
    final isReferralRole = appUserType == AppUserType.publicUser;

    final String statusText = order.isApproved ? 'Approved' : 'Pending';
    final Color badgeColor = order.isApproved
        ? AppColors.approvedGreen
        : AppColors.pendingYellow;

    String formattedDate = order.invoiceDate;
    final parsedDate = DateTime.tryParse(order.invoiceDate);
    if (parsedDate != null) {
      final day = parsedDate.day.toString().padLeft(2, '0');
      final month = parsedDate.month.toString().padLeft(2, '0');
      final year = parsedDate.year;
      formattedDate = '$day/$month/$year';
    }

    final refText = order.invoiceReferenceNo.isNotEmpty
        ? order.invoiceReferenceNo
        : (order.id != null ? 'Ref #${order.id}' : 'N/A');

    final double commVal = CurrencyUtils.convertAmount(
      order.commissionAmountTotal,
      order.currency,
      _selectedCurrency,
    );
    final String commText = commVal == commVal.roundToDouble()
        ? commVal.toStringAsFixed(0)
        : commVal.toStringAsFixed(2);

    final double totalVal = CurrencyUtils.convertAmount(
      order.totalSubtotal,
      order.currency,
      _selectedCurrency,
    );
    final String totalText = totalVal.toStringAsFixed(2);

    final String displayCurrency = _selectedCurrency == "-- Select Currency --"
        ? ((order.currency.isEmpty || order.currency == "False") ? "AED" : order.currency)
        : _selectedCurrency;

    final bool hasPlatform =
        order.platform.isNotEmpty && order.platform != "False";
    final bool hasCustomer = order.customerName.isNotEmpty;
    final bool hasSalesperson = order.salespersonName.isNotEmpty;

    return GestureDetector(
      onTap: () => _showOrderDetailsBottomSheet(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            if (widget.user.userType == 'referral_salesperson') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Referral Commission:',
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
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
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (formattedDate.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inv Date:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reference no:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        refText,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E2B7B),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (!isEndUser)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isReferralRole
                              ? 'Referral Commission:'
                              : 'Commission Amount:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$displayCurrency $commText',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$displayCurrency $totalText',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
            if (hasPlatform || hasCustomer || hasSalesperson) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (hasCustomer) ...[
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
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ] else if (hasSalesperson) ...[
                    const Icon(
                      Icons.badge,
                      size: 14,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.salespersonName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ],
                  if (hasPlatform) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Platform: ${order.platform}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showOrderDetailsBottomSheet(
    BuildContext context,
    DashboardOrder order,
  ) {
    final isEndUser = widget.user.userType == 'end_user';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final String statusText = order.isApproved ? 'Approved' : 'Pending';
        final Color badgeColor = order.isApproved
            ? AppColors.approvedGreen
            : AppColors.pendingYellow;

        String formattedDate = order.invoiceDate;
        final parsedDate = DateTime.tryParse(order.invoiceDate);
        if (parsedDate != null) {
          final day = parsedDate.day.toString().padLeft(2, '0');
          final month = parsedDate.month.toString().padLeft(2, '0');
          final year = parsedDate.year;
          formattedDate = '$day/$month/$year';
        }

        final String displayCurrency = _selectedCurrency == "-- Select Currency --"
            ? ((order.currency.isEmpty || order.currency == "False") ? "AED" : order.currency)
            : _selectedCurrency;

        final double commVal = CurrencyUtils.convertAmount(
          order.commissionAmountTotal,
          order.currency,
          _selectedCurrency,
        );
        final String commText = commVal == commVal.roundToDouble()
            ? commVal.toStringAsFixed(0)
            : commVal.toStringAsFixed(2);

        final refText = order.invoiceReferenceNo.isNotEmpty
            ? order.invoiceReferenceNo
            : (order.id != null ? 'Ref #${order.id}' : 'N/A');

        final bool hasCustomer = order.customerName.isNotEmpty;
        final bool hasCompany = order.companyName.isNotEmpty;
        final bool hasSalesperson = order.salespersonName.isNotEmpty;
        final bool hasPlatform =
            order.platform.isNotEmpty && order.platform != "False";
        final bool hasParticipants =
            hasCustomer || hasCompany || hasSalesperson || hasPlatform;

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
                          refText,
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
                    if (formattedDate.isNotEmpty && widget.user.userType != 'referral_salesperson') ...[
                      const SizedBox(height: 8),
                      Text(
                        'Invoice Date: $formattedDate',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (hasParticipants) ...[
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
                      if (hasCustomer) ...[
                        _buildDetailRow(
                          icon: Icons.person,
                          label: 'Customer',
                          value: order.customerName,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (hasCompany) ...[
                        _buildDetailRow(
                          icon: Icons.business,
                          label: 'Company',
                          value: order.companyName,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (hasSalesperson) ...[
                        _buildDetailRow(
                          icon: Icons.badge,
                          label: 'Salesperson',
                          value: order.salespersonName,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (hasPlatform)
                        _buildDetailRow(
                          icon: Icons.computer,
                          label: 'Platform',
                          value: order.platform,
                        ),
                    ],
                    if (order.invoiceDetails.isNotEmpty) ...[
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
                                      'Qty: ${detail.quantity} x $displayCurrency ${CurrencyUtils.convertAmount(detail.unitPrice, order.currency, _selectedCurrency).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$displayCurrency ${CurrencyUtils.convertAmount(detail.subtotal, order.currency, _selectedCurrency).toStringAsFixed(2)}',
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
                    ],
                    if (order.totalSubtotal > 0) ...[
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
                            '$displayCurrency ${CurrencyUtils.convertAmount(order.totalSubtotal, order.currency, _selectedCurrency).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!isEndUser && commVal > 0) ...[
                      const SizedBox(height: 8),
                      Row(
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
                            '$displayCurrency $commText',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.approvedGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primaryBlue,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.user.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryTeal.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.secondaryTeal,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            widget.user.formattedUserType.isNotEmpty
                                ? widget.user.formattedUserType
                                : 'Partner',
                            style: const TextStyle(
                              color: AppColors.secondaryTeal,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.person, color: Colors.white),
                ],
              ),
            ),
            if (widget.user.userType != 'referral_salesperson')
              _buildDrawerItem(
                context,
                Icons.description,
                'Commission Statement',
                ActiveScreen.statement,
              ),
            _buildDrawerItem(
              context,
              Icons.bar_chart,
              'Incentive Report',
              ActiveScreen.incentiveReport,
            ),
            _buildDrawerItem(
              context,
              Icons.more_horiz,
              'View More',
              ActiveScreen.viewMore,
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.white),
              title: const Text(
                'Redeem Request',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await Future.delayed(const Duration(milliseconds: 250));
                ref.read(navigationProvider.notifier).state =
                    ActiveScreen.redeemDetails;
              },
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close drawer
                ref.read(navigationProvider.notifier).state =
                    ActiveScreen.dashboard;
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  const Text(
                    'SAASORDER',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Text(
                    'partnerPro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _handleLogout(context),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(color: AppColors.textGrey, fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                elevation: 0,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (!context.mounted) {
        return;
      }
      Navigator.pop(context);
    }
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    ActiveScreen screen,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      onTap: () async {
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 250));
        ref.read(navigationProvider.notifier).state = screen;
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading dashboard data',
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
                  onPressed: () => ref.refresh(dashboardDataProvider),
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
