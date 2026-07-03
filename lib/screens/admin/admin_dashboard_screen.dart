import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/auth_user.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/permission_service.dart';
import 'admin_all_salesperson_orders_screen.dart';
import 'admin_all_referral_orders_screen.dart';
import 'admin_referral_orders_screen.dart';
import 'admin_incentive_report_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AdminHomeScreen(user: user);
  }
}

// ---------------------------------------------------------------------------
// Admin Home Screen
// ---------------------------------------------------------------------------

class _AdminHomeScreen extends ConsumerWidget {
  const _AdminHomeScreen({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allSalespersonOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            // Admin is already on home screen, do nothing or pop to root of admin flow if needed.
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
                user.displayName,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white30, width: 0.5),
                ),
                child: Text(
                  user.formattedUserType.isNotEmpty
                      ? user.formattedUserType
                      : 'Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: _buildAdminDrawer(context, ref),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(allSalespersonOrdersProvider.future),
        child: ordersAsync.when(
          data: (data) => _buildDashboardContent(context, data),
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
          error: (err, _) => _buildErrorState(context, ref, err.toString()),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, dynamic data) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSummaryCards(data),
            const SizedBox(height: 24),
            _buildSectionHeader('Overview'),
            const SizedBox(height: 12),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(dynamic data) {
    final totalCredit = data?.totalCredit ?? 0.0;
    final totalDebit = data?.totalDebit ?? 0.0;
    final totalBalance = data?.totalBalance ?? 0.0;
    final salespersonsCount = (data?.salespersons as List?)?.length ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                topWidget: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.approvedGreen,
                  size: 32,
                ),
                title: totalCredit.toStringAsFixed(2),
                subtitle: 'Commission\nEarned',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                topWidget: const Icon(
                  Icons.trending_down,
                  color: Colors.redAccent,
                  size: 32,
                ),
                title: totalDebit.toStringAsFixed(2),
                subtitle: 'Commission\nRadeemed',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                topWidget: const Icon(
                  Icons.monetization_on,
                  color: AppColors.accentBlue,
                  size: 32,
                ),
                title: totalBalance.toStringAsFixed(2),
                subtitle: 'Total\nBalance',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                topWidget: const Icon(
                  Icons.people,
                  color: AppColors.secondaryTeal,
                  size: 32,
                ),
                title: '$salespersonsCount',
                subtitle: 'Total\nSalespersons',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container()),
            const SizedBox(width: 8),
            Expanded(child: Container()),
          ],
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
          if (topWidget != null) topWidget else const SizedBox(height: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.2,
            ),
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
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final hasViewOrders = PermissionService.instance.hasPermission('order_management.view_orders');
    final hasViewReferrals = PermissionService.instance.hasPermission('order_management.view_referralsalesperson');
    final hasViewIncentive = PermissionService.instance.hasPermission('sales_agent_management.view_salesincentivereport');

    final actions = [
      if (hasViewOrders)
        (
          icon: Icons.person_search,
          label: 'All Salesperson\nOrders',
          screen: const AdminAllSalespersonOrdersScreen(),
          color: AppColors.primaryBlue,
        ),
      if (hasViewReferrals) ...[
        (
          icon: Icons.people_alt,
          label: 'All Referral\nOrders',
          screen: const AdminAllReferralOrdersScreen(),
          color: AppColors.accentBlue,
        ),
        (
          icon: Icons.share,
          label: 'Referral\nOrders',
          screen: const AdminReferralOrdersScreen(),
          color: AppColors.secondaryTeal,
        ),
      ],
      if (hasViewIncentive)
        (
          icon: Icons.bar_chart,
          label: 'Incentive\nReport',
          screen: const AdminIncentiveReportScreen(),
          color: AppColors.approvedGreen,
        ),
    ];

    if (actions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'You do not have permission to view any reports.',
            style: TextStyle(color: AppColors.textGrey, fontSize: 16),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _QuickActionCard(
          icon: action.icon,
          label: action.label,
          color: action.color,
          destinationScreen: action.screen,
        );
      },
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
              'Error loading admin data',
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
              onPressed: () => ref.refresh(allSalespersonOrdersProvider.future),
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

  Widget _buildAdminDrawer(BuildContext context, WidgetRef ref) {
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
                      children: [
                        Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryTeal.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.secondaryTeal,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            user.formattedUserType.isNotEmpty
                                ? user.formattedUserType
                                : 'Admin',
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
                  const SizedBox(width: 8),
                  const Icon(Icons.admin_panel_settings, color: Colors.white),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 8),
            if (PermissionService.instance.hasPermission('order_management.view_orders'))
              _buildDrawerItem(
                context,
                ref,
                Icons.person_search,
                'All Salesperson Orders',
                const AdminAllSalespersonOrdersScreen(),
              ),
            if (PermissionService.instance.hasPermission('order_management.view_referralsalesperson')) ...[
              _buildDrawerItem(
                context,
                ref,
                Icons.people_alt,
                'All Referral Orders',
                const AdminAllReferralOrdersScreen(),
              ),
              _buildDrawerItem(
                context,
                ref,
                Icons.share,
                'Referral Orders',
                const AdminReferralOrdersScreen(),
              ),
            ],
            if (PermissionService.instance.hasPermission('sales_agent_management.view_salesincentivereport'))
              _buildDrawerItem(
                context,
                ref,
                Icons.bar_chart,
                'Incentive Report',
                const AdminIncentiveReportScreen(),
              ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close drawer
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
              onPressed: () => _handleLogout(context, ref),
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

  Widget _buildDrawerItem(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String title,
    Widget destinationScreen,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context); // close drawer
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => destinationScreen,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
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
      if (!context.mounted) return;
      Navigator.pop(context);
    }
  }
}

// ---------------------------------------------------------------------------
// Quick Action Card Widget (needs ConsumerWidget to access ref)
// ---------------------------------------------------------------------------

class _QuickActionCard extends ConsumerWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.destinationScreen,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Widget destinationScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => destinationScreen,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
