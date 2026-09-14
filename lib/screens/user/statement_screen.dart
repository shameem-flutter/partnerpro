import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/statement_provider.dart';
import '../../models/statement_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/redemption_provider.dart';
import '../../models/redemption_response.dart';
import '../../providers/dashboard_provider.dart';

class StatementScreen extends ConsumerWidget {
  const StatementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statementAsync = ref.watch(statementDataProvider);
    final filterState = ref.watch(statementFilterProvider);
    final filterNotifier = ref.read(statementFilterProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(navigationProvider.notifier).state = ActiveScreen.dashboard;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => ref.read(navigationProvider.notifier).state =
                ActiveScreen.dashboard,
          ),
          title: const Text(
            'Commission Statement',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.refresh(statementDataProvider.future),
                ref.refresh(redemptionBalanceProvider.future),
              ]);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildFilters(context, ref, filterState, filterNotifier),
                  const SizedBox(height: 16),
                  (() {
                    if (statementAsync.hasValue) {
                      final data = statementAsync.value!;
                      final redemptionBalanceState =
                          ref.watch(redemptionBalanceProvider);
                      final totalBalance = redemptionBalanceState.hasValue
                          ? (double.tryParse(
                                redemptionBalanceState.value!.availableBalance,
                              ) ??
                              0.0)
                          : data.orders.fold<double>(
                              0.0,
                              (sum, order) => sum + order.commissionAmountTotal,
                            );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryBlue, Color(0xFF2C3E9F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL AVAILABLE BALANCE',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        const Text(
                                          'AED ',
                                          style: TextStyle(
                                            color: AppColors.secondaryTeal,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          totalBalance.toStringAsFixed(2),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    color: AppColors.secondaryTeal,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: totalBalance > 0
                                    ? () => _showRedemptionDialog(
                                        context,
                                        totalBalance,
                                      )
                                    : null,
                                icon: const Icon(
                                  Icons.currency_exchange,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Convert Balance',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondaryTeal,
                                  foregroundColor: AppColors.primaryBlue,
                                  disabledBackgroundColor: Colors.white24,
                                  disabledForegroundColor: Colors.white54,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  })(),
                  Expanded(
                    child: (() {
                      if (statementAsync.hasValue) {
                        final data = statementAsync.value!;
                        final filtered = _getFilteredOrders(
                          data.orders,
                          filterState,
                        );
                        if (filtered.isEmpty) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: const Center(
                                child: Text(
                                  'No transactions found for the selected range.',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        // Calculate running balances
                        final runningBalances = List<double>.filled(
                          filtered.length,
                          0.0,
                        );
                        double cumulative = 0.0;
                        for (int i = filtered.length - 1; i >= 0; i--) {
                          cumulative += filtered[i].commissionAmountTotal;
                          runningBalances[i] = cumulative;
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            final balance = runningBalances[index];

                            return _buildTransactionCard(
                              date: _formatDateStr(order.invoiceDate),
                              type: order.customerName.isNotEmpty
                                  ? order.customerName
                                  : 'Direct Order',
                              ref: order.invoiceReferenceNo,
                              currency: order.currency,
                              amount:
                                  '+${order.commissionAmountTotal.toStringAsFixed(2)}',
                              balance: balance.toStringAsFixed(2),
                              isCredit: true,
                            );
                          },
                        );
                      } else if (statementAsync.isLoading) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
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
                        final err =
                            statementAsync.error?.toString() ?? 'Unknown error';
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Failed to load transactions:\n$err',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () =>
                                        ref.refresh(statementDataProvider),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    })(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<StatementOrder> _getFilteredOrders(
    List<StatementOrder> allOrders,
    StatementFilterState filterState,
  ) {
    if (filterState.appliedStartDate == null &&
        filterState.appliedEndDate == null) {
      return allOrders;
    }
    return allOrders.where((order) {
      final orderDate = DateTime.tryParse(order.invoiceDate);
      if (orderDate == null) return true;

      if (filterState.appliedStartDate != null) {
        final start = DateTime(
          filterState.appliedStartDate!.year,
          filterState.appliedStartDate!.month,
          filterState.appliedStartDate!.day,
        );
        final ord = DateTime(orderDate.year, orderDate.month, orderDate.day);
        if (ord.isBefore(start)) return false;
      }

      if (filterState.appliedEndDate != null) {
        final end = DateTime(
          filterState.appliedEndDate!.year,
          filterState.appliedEndDate!.month,
          filterState.appliedEndDate!.day,
        );
        final ord = DateTime(orderDate.year, orderDate.month, orderDate.day);
        if (ord.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  String _formatDateStr(String dateStr) {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  Widget _buildFilters(
    BuildContext context,
    WidgetRef ref,
    StatementFilterState filterState,
    StatementFilterNotifier filterNotifier,
  ) {
    final startText = filterState.startDate == null
        ? 'Start Date'
        : _formatDateStr(
            filterState.startDate!.toIso8601String().split('T').first,
          );
    final endText = filterState.endDate == null
        ? 'End Date'
        : _formatDateStr(
            filterState.endDate!.toIso8601String().split('T').first,
          );

    return Row(
      children: [
        _buildDateField(
          label: startText,
          icon: Icons.calendar_today,
          isActive: filterState.startDate != null,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: filterState.startDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primaryBlue,
                      onPrimary: Colors.white,
                      onSurface: Colors.black87,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              filterNotifier.setStartDate(picked);
            }
          },
        ),
        const SizedBox(width: 8),
        _buildDateField(
          label: endText,
          icon: Icons.calendar_today,
          isActive: filterState.endDate != null,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: filterState.endDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primaryBlue,
                      onPrimary: Colors.white,
                      onSurface: Colors.black87,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              filterNotifier.setEndDate(picked);
            }
          },
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            filterNotifier.applyFilters();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Filter',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (filterState.appliedStartDate != null ||
            filterState.appliedEndDate != null) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.redAccent),
            onPressed: () {
              filterNotifier.clearFilters();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primaryBlue : Colors.grey.shade300,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? AppColors.primaryBlue : AppColors.textGrey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.black87 : AppColors.textGrey,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required String date,
    required String type,
    required String ref,
    required String currency,
    required String amount,
    required String balance,
    required bool isCredit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                    'Date:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Amount:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$amount $currency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isCredit ? AppColors.approvedGreen : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaction Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ref: $ref',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Balance:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$balance $currency',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRedemptionDialog(BuildContext context, double maxBalance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return RedemptionBottomSheet(maxBalance: maxBalance);
      },
    );
  }
}

class RedemptionBottomSheet extends ConsumerStatefulWidget {
  final double maxBalance;

  const RedemptionBottomSheet({super.key, required this.maxBalance});

  @override
  ConsumerState<RedemptionBottomSheet> createState() =>
      RedemptionBottomSheetState();
}

class RedemptionBottomSheetState extends ConsumerState<RedemptionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  final List<String> _currencies = ['INR', 'USD', 'SAR', 'OMR', 'AED'];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.maxBalance.toStringAsFixed(2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(redemptionNotifierProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitConvert() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    final authState = ref.read(authNotifierProvider);
    final token = authState.session?.accessToken ?? '';
    if (token.isEmpty) {
      showGlobalSnackBar('Authentication error: Session expired.', isSuccess: false);
      return;
    }
    await ref
        .read(redemptionNotifierProvider.notifier)
        .convert(token: token, amount: amount);

    // Refreshing is now deferred until the user clicks "Close" on the success screen
    // to prevent immediate background loading spinner flickering.
  }

  @override
  Widget build(BuildContext context) {
    final redemptionState = ref.watch(redemptionNotifierProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 24 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          if (redemptionState.result != null) ...[
            _buildSuccessState(redemptionState.result!),
          ] else ...[
            _buildFormState(redemptionState),
          ],
        ],
      ),
    );
  }

  Widget _buildFormState(RedemptionState redemptionState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Convert Commission',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Convert your available AED balance into another currency.',
            style: TextStyle(fontSize: 14, color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),
          if (redemptionState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      redemptionState.errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !redemptionState.isLoading,
            decoration: InputDecoration(
              labelText: 'Amount (AED)',
              labelStyle: const TextStyle(color: AppColors.textGrey),
              suffixText: 'AED',
              suffixStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              helperText:
                  'Max available: AED ${widget.maxBalance.toStringAsFixed(2)}',
              helperStyle: const TextStyle(color: AppColors.textGrey),
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter amount';
              }
              final amount = double.tryParse(value.trim());
              if (amount == null) {
                return 'Please enter a valid number';
              }
              if (amount <= 0) {
                return 'Amount must be greater than zero';
              }
              final maxAllowed = double.parse(widget.maxBalance.toStringAsFixed(2));
              if (amount > maxAllowed) {
                return 'Amount cannot exceed available balance';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: redemptionState.selectedCurrency,
            decoration: InputDecoration(
              labelText: 'Target Currency',
              labelStyle: const TextStyle(color: AppColors.textGrey),
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.primaryBlue,
            ),
            items: _currencies.map((String currency) {
              return DropdownMenuItem<String>(
                value: currency,
                child: Text(
                  currency,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              );
            }).toList(),
            onChanged: redemptionState.isLoading
                ? null
                : (String? newValue) {
                    if (newValue != null) {
                      ref
                          .read(redemptionNotifierProvider.notifier)
                          .setCurrency(newValue);
                    }
                  },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: redemptionState.isLoading ? null : _submitConvert,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: redemptionState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.currency_exchange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Convert Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(RedemptionResponse result) {
    final double convertedVal = double.tryParse(result.convertedAmount) ?? 0.0;
    final String formattedConverted = convertedVal.toStringAsFixed(2);
    final selectedCurrency = ref
        .read(redemptionNotifierProvider)
        .selectedCurrency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        const Center(
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.approvedGreen,
            size: 80,
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Conversion Successful',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Your commission has been successfully converted.',
            style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildReceiptRow(
                'Source Amount',
                '${double.parse(_amountController.text).toStringAsFixed(2)} AED',
              ),
              const Divider(height: 24),
              _buildReceiptRow('Target Currency', selectedCurrency),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Converted Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textGrey,
                    ),
                  ),
                  Text(
                    '$formattedConverted $selectedCurrency',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.approvedGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
            );
            final navigator = Navigator.of(context);

            try {
              ref.invalidate(statementDataProvider);
              ref.invalidate(dashboardDataProvider);
              
              await Future.wait([
                ref.read(statementDataProvider.future),
                ref.read(dashboardDataProvider.future),
              ]).timeout(const Duration(seconds: 10));
            } catch (_) {}

            if (context.mounted) {
              navigator.pop(); // pop loader dialog
              navigator.pop(); // pop bottom sheet
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Close',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
