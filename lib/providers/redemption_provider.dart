import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/redemption_service.dart';
import '../models/redemption_response.dart';
import '../models/redemption_balance.dart';
import '../models/sales_report.dart';
import 'auth_provider.dart';
import 'dio_provider.dart';

final redemptionServiceProvider = Provider<RedemptionService>((ref) {
  final dio = ref.watch(dioProvider);
  return RedemptionService(dio: dio);
});

final redemptionBalanceProvider = FutureProvider<RedemptionBalanceResponse>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final token = authState.session?.accessToken ?? 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzgwNTY4MzQ3LCJpYXQiOjE3ODA0ODE5NDcsImp0aSI6ImQ4MjFhMDYyNTUxYzRhMjBiNTY3MGY1ZDc1ZjgwYTE0IiwidXNlcl9pZCI6IjMwIn0.dK4Vcnm_8lxpwd3Xv6mU5Fm7tMx2iEJtfXE4AXUPqs4';

  final service = ref.watch(redemptionServiceProvider);
  return service.getBalance(accessToken: token);
});

final salesReportDataProvider = FutureProvider<SalesReportResponse>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final token = authState.session?.accessToken ?? 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzgwNTY4MzQ3LCJpYXQiOjE3ODA0ODE5NDcsImp0aSI6ImQ4MjFhMDYyNTUxYzRhMjBiNTY3MGY1ZDc1ZjgwYTE0IiwidXNlcl9pZCI6IjMwIn0.dK4Vcnm_8lxpwd3Xv6mU5Fm7tMx2iEJtfXE4AXUPqs4';

  final service = ref.watch(redemptionServiceProvider);
  return service.getSalesReport(accessToken: token);
});

class RedemptionState {
  final bool isLoading;
  final String? errorMessage;
  final RedemptionResponse? result;
  final String selectedCurrency;
  final bool isSuccess;

  const RedemptionState({
    this.isLoading = false,
    this.errorMessage,
    this.result,
    this.selectedCurrency = 'INR',
    this.isSuccess = false,
  });

  RedemptionState copyWith({
    bool? isLoading,
    String? errorMessage,
    RedemptionResponse? result,
    String? selectedCurrency,
    bool? isSuccess,
  }) {
    return RedemptionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      result: result ?? this.result,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class RedemptionNotifier extends StateNotifier<RedemptionState> {
  final RedemptionService _service;

  RedemptionNotifier(this._service) : super(const RedemptionState());

  void setCurrency(String currency) {
    state = state.copyWith(selectedCurrency: currency);
  }

  void reset() {
    state = const RedemptionState();
  }

  Future<void> convert({
    required String token,
    required double amount,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, result: null, isSuccess: false);
    try {
      final res = await _service.convert(
        token: token,
        amount: amount,
        currency: state.selectedCurrency,
      );
      state = state.copyWith(isLoading: false, result: res);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> submitRedemption({
    required String token,
    required String accountNumber,
    required String accountName,
    required String country,
    required String ifscCode,
    required String amount,
    required String currency,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _service.requestRedemption(
        token: token,
        accountNumber: accountNumber,
        accountName: accountName,
        country: country,
        ifscCode: ifscCode,
        amount: amount,
        currency: currency,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final redemptionNotifierProvider = StateNotifierProvider.autoDispose<RedemptionNotifier, RedemptionState>((ref) {
  final service = ref.watch(redemptionServiceProvider);
  return RedemptionNotifier(service);
});
