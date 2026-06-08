import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_user.dart';
import '../models/dashboard_data.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _directLimit = 10;
  int _referralLimit = 10;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          title: Column(
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
          actions: [
            Text(
              widget.user.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
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
          bottom: const TabBar(
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
              return TabBarView(
                children: [
                  _buildDashboardContent(context, data, isReferral: false),
                  _buildDashboardContent(context, data, isReferral: true),
                ],
              );
            } else if (dashboardAsync.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              );
            } else {
              return _buildErrorState(context, dashboardAsync.error?.toString() ?? 'Unknown error');
            }
          })(),
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
    final displayLimit = isReferral ? _referralLimit : _directLimit;

    final showList = displayLimit < ordersList.length ? ordersList.sublist(0, displayLimit) : ordersList;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(data, isReferral: isReferral),
            const SizedBox(height: 24),
            _buildRecentOrdersHeader(isReferral: isReferral),
            const SizedBox(height: 12),
            if (ordersList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    isReferral ? 'No referral orders found.' : 'No orders found.',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else ...[
              ...showList.map((order) => _buildOrderCard(order)),
              if (displayLimit < ordersList.length) ...[
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (isReferral) {
                            _referralLimit += 10;
                          } else {
                            _directLimit += 10;
                          }
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
    );
  }

  Widget _buildSummaryCards(DashboardData data, {required bool isReferral}) {
    final double commission = isReferral ? data.totalCommissionRef : data.totalCommission;
    final int approved = isReferral ? data.refApprovedOrdersCount : data.approvedOrdersCount;
    final int pending = isReferral ? data.refPendingOrdersCount : data.pendingOrdersCount;

    final ordersList = isReferral ? data.referralOrders : data.orders;
    final String orderCurrency = ordersList.isNotEmpty && ordersList.first.currency.isNotEmpty
        ? ordersList.first.currency
        : 'AED';

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            topWidget: Text(
              orderCurrency,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            title: commission.toStringAsFixed(2),
            subtitle: isReferral ? 'Referral\nCommission' : 'Total\nCommission',
            titleColor: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            topWidget: const Icon(
              Icons.check_circle,
              color: AppColors.approvedGreen,
              size: 32,
            ),
            title: '$approved',
            subtitle: 'Approved\norders',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            topWidget: const Icon(
              Icons.access_time_filled,
              color: AppColors.pendingYellow,
              size: 32,
            ),
            title: '$pending',
            subtitle: 'Pending\norders',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    Widget? topWidget,
    required String title,
    required String subtitle,
    Color titleColor = Colors.black,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (topWidget != null)
            topWidget
          else
            const SizedBox(height: 32),
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
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersHeader({required bool isReferral}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        isReferral ? 'Referral Orders' : 'Recent Orders',
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
    final String platformText = order.platform == "False" || order.platform.isEmpty
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

    final double commVal = order.commissionAmountTotal;
    final String commText = commVal == commVal.roundToDouble() 
        ? commVal.toStringAsFixed(0) 
        : commVal.toStringAsFixed(2);

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
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Commission Amount:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    commText,
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
      ),
    ),
    );
  }

  void _showOrderDetailsBottomSheet(BuildContext context, DashboardOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final String platformText = order.platform == "False" || order.platform.isEmpty
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

        final double commVal = order.commissionAmountTotal;
        final String commText = commVal == commVal.roundToDouble() 
            ? commVal.toStringAsFixed(0) 
            : commVal.toStringAsFixed(2);

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      value: order.companyName.isNotEmpty ? order.companyName : 'N/A',
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
                    ...order.invoiceDetails.map((detail) => Padding(
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
                                  'Qty: ${detail.quantity} x ${order.currency} ${detail.unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${order.currency} ${detail.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    )),
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
                          '${order.currency} ${order.totalSubtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
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
                          '${order.currency} $commText',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.approvedGreen,
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
                  Text(
                    widget.user.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.more_horiz, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(
              context,
              Icons.description,
              'Commission Statement',
              ActiveScreen.statement,
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
              onTap: () {
                Navigator.pop(context); // Close drawer
                ref.read(navigationProvider.notifier).state = ActiveScreen.redeemDetails;
              },
            ),
            const Spacer(),
            Column(
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
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 16,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 0,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
      onTap: () {
        Navigator.pop(context);
        ref.read(navigationProvider.notifier).state = screen;
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
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
    );
  }
}
