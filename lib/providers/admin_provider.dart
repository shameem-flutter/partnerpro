import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';
import 'auth_provider.dart';
import 'dio_provider.dart';

// ---------------------------------------------------------------------------
// Service Provider
// ---------------------------------------------------------------------------

final adminServiceProvider = Provider<AdminService>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminService(dio: dio);
});

// ---------------------------------------------------------------------------
// Selected Salesperson ID  (used as query param)
// ---------------------------------------------------------------------------

final selectedSalespersonIdProvider = StateProvider.autoDispose<String?>((ref) => null);

// ---------------------------------------------------------------------------
// 1.  All Salesperson Orders
// ---------------------------------------------------------------------------

final allSalespersonOrdersProvider =
    FutureProvider.autoDispose<AllSalespersonOrdersResponse>((ref) async {
      final authState = ref.watch(authNotifierProvider);
      final token = authState.session?.accessToken ?? '';
      final salespersonId = ref.watch(selectedSalespersonIdProvider);
      final service = ref.watch(adminServiceProvider);
      return service.fetchAllSalespersonOrders(
        token,
        salespersonId: salespersonId,
      );
    });

// ---------------------------------------------------------------------------
// 2.  Sales Report / Incentive Report
// ---------------------------------------------------------------------------

/// Separate selected salesperson for the incentive report screen
final incentiveReportSalespersonIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final salesReportProvider = FutureProvider.autoDispose<SalesReportResponse>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final token = authState.session?.accessToken ?? '';
  final salespersonId = ref.watch(incentiveReportSalespersonIdProvider);
  final dateRange = ref.watch(salesReportDateRangeProvider);
  final service = ref.watch(adminServiceProvider);

  String? fromDateStr;
  String? toDateStr;
  if (dateRange != null) {
    fromDateStr = "${dateRange.start.year}-${dateRange.start.month.toString().padLeft(2, '0')}-${dateRange.start.day.toString().padLeft(2, '0')}";
    toDateStr = "${dateRange.end.year}-${dateRange.end.month.toString().padLeft(2, '0')}-${dateRange.end.day.toString().padLeft(2, '0')}";
  }

  return service.fetchSalesReport(
    token,
    salespersonId: salespersonId,
    fromDate: fromDateStr,
    toDate: toDateStr,
  );
});

// ---------------------------------------------------------------------------
// 3.  All Referral Orders
// ---------------------------------------------------------------------------

final allReferralOrdersSalespersonIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final allReferralOrdersProvider =
    FutureProvider.autoDispose<AllReferralOrdersResponse>((ref) async {
      final authState = ref.watch(authNotifierProvider);
      final token = authState.session?.accessToken ?? '';
      final salespersonId = ref.watch(allReferralOrdersSalespersonIdProvider);
      final service = ref.watch(adminServiceProvider);
      return service.fetchAllReferralOrders(
        token,
        salespersonId: salespersonId,
      );
    });

// ---------------------------------------------------------------------------
// Salespersons list (derived from allSalespersonOrdersProvider)
// ---------------------------------------------------------------------------

final salespersonsListProvider = Provider<AsyncValue<List<Salesperson>>>((ref) {
  return ref.watch(allSalespersonOrdersProvider).whenData(
    (data) => data.salespersons,
  );
});

// ---------------------------------------------------------------------------
// Admin Currency Provider (shared across the 4 admin screens)
// ---------------------------------------------------------------------------

final adminCurrencyProvider = StateProvider.autoDispose<String>((ref) => 'AED');

// ---------------------------------------------------------------------------
// 4. Sales Report Filters & Search
// ---------------------------------------------------------------------------
final salesReportSearchInvoiceProvider = StateProvider.autoDispose<String>((ref) => '');
final salesReportSearchCustomerProvider = StateProvider.autoDispose<String>((ref) => '');
final salesReportDateRangeProvider = StateProvider.autoDispose<DateTimeRange?>((ref) => null);
final salesReportSortAscendingProvider = StateProvider.autoDispose<bool>((ref) => false);

// ---------------------------------------------------------------------------
// 5. Selected Invoices & Commission percentages for Approval
// ---------------------------------------------------------------------------
/// Map of invoice_id -> commission_percentage
final selectedInvoicesProvider = StateProvider.autoDispose<Map<int, double>>((ref) => {});

// ---------------------------------------------------------------------------
// 6. Selected Referral Orders for Approval
// ---------------------------------------------------------------------------
/// Set of referral_order_ids selected for approval
final selectedReferralsProvider = StateProvider.autoDispose<Set<int>>((ref) => {});


