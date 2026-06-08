import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/statement_order.dart';
import '../services/statement_service.dart';
import 'auth_provider.dart';
import 'dio_provider.dart';

final statementServiceProvider = Provider<StatementService>((ref) {
  final dio = ref.watch(dioProvider);
  return StatementService(dio: dio);
});

final statementDataProvider = FutureProvider<StatementOrderResponse>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  
  // Primary: token from user session. Fallback: prompt token.
  final token = authState.session?.accessToken ?? 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzc5Nzg3OTA4LCJpYXQiOjE3Nzk3MDE1MDgsImp0aSI6IjQwMzU3MmIzMzVmYTQyNTNiOTkyN2JkYjY4MWQ3YjY3IiwidXNlcl9pZCI6IjQ3In0.i6rZZ-VOL0Gwo1rgz0NqtA5CdcBbHZ0xyYUWLuhB_o0';

  final service = ref.watch(statementServiceProvider);
  return service.fetchOrders(token);
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

