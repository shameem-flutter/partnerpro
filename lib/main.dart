import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/statement_screen.dart';
import 'screens/view_more_screen.dart';
import 'screens/redeem_details_screen.dart';
import 'theme/app_colors.dart';
import 'providers/auth_provider.dart';

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



class AuthBootstrapScreen extends ConsumerWidget {
  const AuthBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = authState.session;
    if (session == null) {
      return const LoginScreen();
    }

    final activeScreen = ref.watch(navigationProvider);
    switch (activeScreen) {
      case ActiveScreen.dashboard:
        return DashboardScreen(user: session.user);
      case ActiveScreen.statement:
        return const StatementScreen();
      case ActiveScreen.viewMore:
        return const ViewMoreScreen();
      case ActiveScreen.redeemDetails:
        return const RedeemDetailsScreen();
    }
  }
}
