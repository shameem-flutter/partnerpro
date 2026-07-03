import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/auth_session.dart';
import 'screens/user/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user/statement_screen.dart';
import 'screens/user/view_more_screen.dart';
import 'screens/user/redeem_details_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/statement_provider.dart';
import 'providers/redemption_provider.dart';
import 'providers/admin_provider.dart';

void main() {
  runApp(const ProviderScope(child: PartnerProApp()));
}

class PartnerProApp extends StatelessWidget {
  const PartnerProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PartnerPro',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          secondary: AppColors.secondaryTeal,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        fontFamily: 'Roboto',
      ),
      home: const AuthBootstrapScreen(),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

class AuthBootstrapScreen extends ConsumerStatefulWidget {
  const AuthBootstrapScreen({super.key});

  @override
  ConsumerState<AuthBootstrapScreen> createState() =>
      _AuthBootstrapScreenState();
}

class _AuthBootstrapScreenState extends ConsumerState<AuthBootstrapScreen> {
  late PageController _pageController;

  int _getIndexForScreen(ActiveScreen screen) {
    switch (screen) {
      case ActiveScreen.dashboard:
        return 0;
      case ActiveScreen.statement:
        return 1;
      case ActiveScreen.viewMore:
        return 2;
      case ActiveScreen.redeemDetails:
        return 3;
    }
  }

  @override
  void initState() {
    super.initState();
    final initialScreen = ref.read(navigationProvider);
    _pageController = PageController(
      initialPage: _getIndexForScreen(initialScreen),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ActiveScreen>(navigationProvider, (previous, next) {
      if (_pageController.hasClients) {
        final targetIndex = _getIndexForScreen(next);
        _pageController.jumpToPage(targetIndex);
      }
    });

    final authState = ref.watch(authNotifierProvider);

    // -----------------------------------------------------------------------
    // Loading state
    // -----------------------------------------------------------------------
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // -----------------------------------------------------------------------
    // Not authenticated → Login
    // -----------------------------------------------------------------------
    final session = authState.session;
    if (session == null) {
      return const LoginScreen();
    }

    // -----------------------------------------------------------------------
    // Admin flow
    // -----------------------------------------------------------------------
    if (session.role == UserRole.admin) {
      final allSalespersonOrdersAsync = ref.watch(allSalespersonOrdersProvider);
      final salesReportAsync = ref.watch(salesReportProvider);
      final allReferralOrdersAsync = ref.watch(allReferralOrdersProvider);

      if ((allSalespersonOrdersAsync.isLoading &&
              !allSalespersonOrdersAsync.hasValue) ||
          (salesReportAsync.isLoading && !salesReportAsync.hasValue) ||
          (allReferralOrdersAsync.isLoading &&
              !allReferralOrdersAsync.hasValue)) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
        );
      }

      return AdminDashboardScreen(user: session.user);
    }

    // -----------------------------------------------------------------------
    // Normal user flow  (driven by Riverpod navigationProvider)
    // -----------------------------------------------------------------------
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final statementAsync = ref.watch(statementDataProvider);
    final viewMoreAsync = ref.watch(viewMoreDataProvider);
    final redemptionBalanceAsync = ref.watch(redemptionBalanceProvider);
    final salesReportAsync = ref.watch(salesReportDataProvider);

    if ((dashboardAsync.isLoading && !dashboardAsync.hasValue) ||
        (statementAsync.isLoading && !statementAsync.hasValue) ||
        (viewMoreAsync.isLoading && !viewMoreAsync.hasValue) ||
        (redemptionBalanceAsync.isLoading &&
            !redemptionBalanceAsync.hasValue) ||
        (salesReportAsync.isLoading && !salesReportAsync.hasValue)) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
        ),
      );
    }

    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        KeepAliveWrapper(child: DashboardScreen(user: session.user)),
        const KeepAliveWrapper(child: StatementScreen()),
        const KeepAliveWrapper(child: ViewMoreScreen()),
        const KeepAliveWrapper(child: RedeemDetailsScreen()),
      ],
    );
  }
}
