import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/dashboard_data.dart';
import '../models/view_more_data.dart';
import '../services/dashboard_service.dart';
import 'auth_provider.dart';
import 'dio_provider.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardService(dio: dio);
});

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final token = authState.session?.accessToken ?? 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzc5Nzg3OTA4LCJpYXQiOjE3Nzk3MDE1MDgsImp0aSI6IjQwMzU3MmIzMzVmYTQyNTNiOTkyN2JkYjY4MWQ3YjY3IiwidXNlcl9pZCI6IjQ3In0.i6rZZ-VOL0Gwo1rgz0NqtA5CdcBbHZ0xyYUWLuhB_o0';

  final service = ref.watch(dashboardServiceProvider);
  return service.fetchHomeData(token);
});

final viewMoreDataProvider = FutureProvider<ViewMoreResponse>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final token = authState.session?.accessToken ?? 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzc5Nzg3OTA4LCJpYXQiOjE3Nzk3MDE1MDgsImp0aSI6IjQwMzU3MmIzMzVmYTQyNTNiOTkyN2JkYjY4MWQ3YjY3IiwidXNlcl9pZCI6IjQ3In0.i6rZZ-VOL0Gwo1rgz0NqtA5CdcBbHZ0xyYUWLuhB_o0';

  final service = ref.watch(dashboardServiceProvider);
  return service.fetchViewMoreData(token);
});

class ViewMoreFilterState {
  final String? selectedPlatform;
  final String selectedCurrency;

  const ViewMoreFilterState({
    this.selectedPlatform,
    this.selectedCurrency = 'AED',
  });

  ViewMoreFilterState copyWith({
    String? Function()? selectedPlatform,
    String? selectedCurrency,
  }) {
    return ViewMoreFilterState(
      selectedPlatform:
          selectedPlatform != null ? selectedPlatform() : this.selectedPlatform,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
    );
  }
}

class ViewMoreFilterNotifier extends StateNotifier<ViewMoreFilterState> {
  ViewMoreFilterNotifier() : super(const ViewMoreFilterState());

  void setPlatform(String? platform) {
    state = state.copyWith(selectedPlatform: () => platform);
  }

  void setCurrency(String currency) {
    state = state.copyWith(selectedCurrency: currency);
  }
}

final viewMoreFilterProvider = StateNotifierProvider.autoDispose<
    ViewMoreFilterNotifier, ViewMoreFilterState>((ref) {
  return ViewMoreFilterNotifier();
});


