import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/redemption_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/statement_provider.dart';
import 'view_more_screen.dart';

class RedeemRequestScreen extends ConsumerStatefulWidget {
  const RedeemRequestScreen({super.key});

  @override
  ConsumerState<RedeemRequestScreen> createState() =>
      _RedeemRequestScreenState();
}

class _RedeemRequestScreenState extends ConsumerState<RedeemRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _routingCodeController = TextEditingController();
  final _amountController = TextEditingController();
  final _convertedAmountController = TextEditingController();

  String? _selectedCountry;
  String _selectedCurrency = 'INR';

  final List<String> _countries = [
    'United Arab Emirates',
    'India',
    'United States',
    'Saudi Arabia',
    'Oman',
  ];

  static const Map<String, String> _countryCodes = {
    'United Arab Emirates': 'AE',
    'India': 'IN',
    'United States': 'US',
    'Saudi Arabia': 'SA',
    'Oman': 'OM',
  };

  final List<String> _currencies = ['INR', 'USD', 'SAR', 'OMR', 'AED'];

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _routingCodeController.dispose();
    _amountController.dispose();
    _convertedAmountController.dispose();
    super.dispose();
  }

  String get _routingCodeLabel {
    if (_selectedCountry == 'India') {
      return 'IFSC Code';
    } else if (_selectedCountry == 'United States') {
      return 'Routing Number';
    } else if (_selectedCountry == 'United Arab Emirates' ||
        _selectedCountry == 'Saudi Arabia' ||
        _selectedCountry == 'Oman') {
      return 'IBAN';
    }
    return 'IFSC Code / IBAN / Routing Number';
  }

  String? get _routingCodeHelperText {
    if (_selectedCountry == 'India') {
      return 'Enter 11-character IFSC code';
    } else if (_selectedCountry == 'United States') {
      return 'Enter 9-digit routing number';
    } else if (_selectedCountry == 'United Arab Emirates') {
      return 'Enter UAE IBAN (23 characters)';
    } else if (_selectedCountry == 'Saudi Arabia') {
      return 'Enter Saudi IBAN (24 characters)';
    } else if (_selectedCountry == 'Oman') {
      return 'Enter Oman IBAN (24 characters)';
    }
    return null;
  }

  String? _validateRoutingCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final code = value.trim().toUpperCase();
    if (_selectedCountry == 'India') {
      if (code.length != 11) {
        return 'IFSC Code must be exactly 11 characters';
      }
    } else if (_selectedCountry == 'United States') {
      if (code.length != 9 || int.tryParse(code) == null) {
        return 'Routing Number must be exactly 9 digits';
      }
    } else if (_selectedCountry == 'United Arab Emirates') {
      if (!code.startsWith('AE') || code.length != 23) {
        return 'UAE IBAN must start with AE and be 23 characters';
      }
    } else if (_selectedCountry == 'Saudi Arabia') {
      if (!code.startsWith('SA') || code.length != 24) {
        return 'Saudi IBAN must start with SA and be 24 characters';
      }
    } else if (_selectedCountry == 'Oman') {
      if (!code.startsWith('OM') || code.length != 24) {
        return 'Oman IBAN must start with OM and be 24 characters';
      }
    }
    return null;
  }

  void _updateConvertedAmount() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _convertedAmountController.text = '';
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null) {
      _convertedAmountController.text = 'Invalid amount';
      return;
    }
    // Convert AED to selected currency
    final converted = ViewMoreScreen.convertAmount(
      amount,
      'AED',
      _selectedCurrency,
    );
    _convertedAmountController.text = converted.toStringAsFixed(2);
  }

  Future<void> _submitRedeem(double maxBalance) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null) {
      showGlobalSnackBar('Please select a country', isSuccess: false);
      return;
    }

    final authState = ref.read(authNotifierProvider);
    final token = authState.session?.accessToken ?? '';
    final countryCode = _countryCodes[_selectedCountry] ?? '';
    final ifscCode = _routingCodeController.text.trim();
    final convertedAmount = _convertedAmountController.text.trim();

    await ref
        .read(redemptionNotifierProvider.notifier)
        .submitRedemption(
          token: token,
          accountNumber: _accountNumberController.text.trim(),
          accountName: _accountNameController.text.trim(),
          country: countryCode,
          ifscCode: ifscCode,
          amount: convertedAmount,
          currency: _selectedCurrency,
        );

    if (!mounted) return;

    final redemptionState = ref.read(redemptionNotifierProvider);
    if (redemptionState.errorMessage != null) {
      showGlobalSnackBar(redemptionState.errorMessage!, isSuccess: false);
    } else if (redemptionState.isSuccess) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Success'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Redeem request submitted successfully.'),
              const SizedBox(height: 16),
              Text(
                'Account Name: ${_accountNameController.text}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Account Number: ${_accountNumberController.text}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$_routingCodeLabel: ${_routingCodeController.text}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Country: $_selectedCountry',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Amount: ${_amountController.text} AED',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Converted Amount: ${_convertedAmountController.text} $_selectedCurrency',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Refresh data
                final _ = ref.refresh(dashboardDataProvider);
                final _ = ref.refresh(statementDataProvider);
                final _ = ref.refresh(redemptionBalanceProvider);
                Navigator.of(context).pop(); // pop dialog
                Navigator.of(context).pop(); // pop screen
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardDataProvider);
    final redemptionBalanceState = ref.watch(redemptionBalanceProvider);
    final maxBalance = redemptionBalanceState.hasValue
        ? (double.tryParse(redemptionBalanceState.value!.availableBalance) ??
              0.0)
        : (dashboardState.value?.totalCommission ?? 0.0);
    final redemptionState = ref.watch(redemptionNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Redeem Request',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Number
                    _buildFormRow(
                      label: 'Account Number',
                      child: TextFormField(
                        controller: _accountNumberController,
                        keyboardType: TextInputType.text,
                        decoration: _inputDecoration(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Account Name
                    _buildFormRow(
                      label: 'Account Name',
                      child: TextFormField(
                        controller: _accountNameController,
                        keyboardType: TextInputType.name,
                        decoration: _inputDecoration(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Country
                    _buildFormRow(
                      label: 'Country',
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCountry,
                        decoration: _inputDecoration(),
                        items: _countries.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCountry = val;
                            _routingCodeController.clear();
                          });
                        },
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Routing Code (IFSC / IBAN / Routing Number)
                    _buildFormRow(
                      label: _routingCodeLabel,
                      child: TextFormField(
                        controller: _routingCodeController,
                        keyboardType: TextInputType.text,
                        decoration: _inputDecoration(
                          helperText: _routingCodeHelperText,
                        ),
                        validator: _validateRoutingCode,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount (AED)
                    _buildFormRow(
                      label: 'Amount (AED)',
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(
                          helperText:
                              'Max available: AED ${maxBalance.toStringAsFixed(2)}',
                        ),
                        onChanged: (val) => _updateConvertedAmount(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final amt = double.tryParse(value.trim());
                          if (amt == null || amt <= 0) {
                            return 'Must be greater than 0';
                          }
                          if (amt > maxBalance) {
                            return 'Exceeds available balance';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Currency
                    _buildFormRow(
                      label: 'Currency',
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCurrency,
                        decoration: _inputDecoration(),
                        items: _currencies.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCurrency = val;
                              _updateConvertedAmount();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Converted Amount
                    _buildFormRow(
                      label: 'Converted Amount',
                      child: TextFormField(
                        controller: _convertedAmountController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          filledColor: const Color(0xFFF1F3F5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: 150,
                      child: ElevatedButton(
                        onPressed: redemptionState.isLoading
                            ? null
                            : () => _submitRedeem(maxBalance),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F3D7A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          elevation: 0,
                        ),
                        child: redemptionState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Redeem',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormRow({required String label, required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          );
        }
      },
    );
  }

  InputDecoration _inputDecoration({String? helperText, Color? filledColor}) {
    return InputDecoration(
      helperText: helperText,
      helperStyle: const TextStyle(color: AppColors.textGrey, fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: filledColor != null,
      fillColor: filledColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF3F3D7A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
