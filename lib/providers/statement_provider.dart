import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/statement_order.dart';
import '../models/admin_models.dart';
import 'package:flutter/material.dart';
import '../services/statement_service.dart';
import 'auth_provider.dart';
import 'dio_provider.dart';

final statementServiceProvider = Provider<StatementService>((ref) {
  final dio = ref.watch(dioProvider);
  return StatementService(dio: dio);
});

final statementDataProvider =
    FutureProvider.autoDispose<StatementOrderResponse>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final token = authState.session?.accessToken ?? '';
  if (token.isEmpty) throw Exception('No auth token found');

  final service = ref.watch(statementServiceProvider);
  return service.fetchOrders(token);
});

final userSalesReportDateRangeProvider =
    StateProvider.autoDispose<DateTimeRange?>((ref) => null);
final userCurrencyProvider = StateProvider.autoDispose<String>((ref) => 'AED');

final userSalesReportProvider =
    FutureProvider.autoDispose<SalesReportResponse>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final token = authState.session?.accessToken ?? '';
  if (token.isEmpty) throw Exception('No auth token found');

  final dateRange = ref.watch(userSalesReportDateRangeProvider);
  final service = ref.watch(statementServiceProvider);

  String? fromDateStr;
  String? toDateStr;
  if (dateRange != null) {
    fromDateStr = "${dateRange.start.year}-${dateRange.start.month.toString().padLeft(2, '0')}-${dateRange.start.day.toString().padLeft(2, '0')}";
    toDateStr = "${dateRange.end.year}-${dateRange.end.month.toString().padLeft(2, '0')}-${dateRange.end.day.toString().padLeft(2, '0')}";
  }

  return service.fetchUserSalesReport(
    token,
    fromDate: fromDateStr,
    toDate: toDateStr,
  );
});

class StatementFilterState {
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? appliedStartDate;
  final DateTime? appliedEndDate;

  const StatementFilterState({
    this.startDate,
    this.endDate,
    this.appliedStartDate,
    this.appliedEndDate,
  });

  StatementFilterState copyWith({
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    DateTime? Function()? appliedStartDate,
    DateTime? Function()? appliedEndDate,
  }) {
    return StatementFilterState(
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      appliedStartDate:
          appliedStartDate != null ? appliedStartDate() : this.appliedStartDate,
      appliedEndDate:
          appliedEndDate != null ? appliedEndDate() : this.appliedEndDate,
    );
  }
}

class StatementFilterNotifier extends StateNotifier<StatementFilterState> {
  StatementFilterNotifier() : super(const StatementFilterState());

  void setStartDate(DateTime? date) {
    state = state.copyWith(startDate: () => date);
  }

  void setEndDate(DateTime? date) {
    state = state.copyWith(endDate: () => date);
  }

  void applyFilters() {
    state = state.copyWith(
      appliedStartDate: () => state.startDate,
      appliedEndDate: () => state.endDate,
    );
  }

  void clearFilters() {
    state = const StatementFilterState();
  }
}

final statementFilterProvider = StateNotifierProvider.autoDispose<
    StatementFilterNotifier, StatementFilterState>((ref) {
  return StatementFilterNotifier();
});

