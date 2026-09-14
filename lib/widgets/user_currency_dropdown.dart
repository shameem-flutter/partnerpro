import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/statement_provider.dart';
import '../theme/app_colors.dart';
import '../utils/currency_utils.dart';

class UserCurrencyDropdown extends ConsumerWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? height;

  const UserCurrencyDropdown({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrency = ref.watch(userCurrencyProvider);
    final activeBgColor = backgroundColor ?? Colors.white;
    final activeTextColor = textColor ?? AppColors.primaryBlue;
    final activeBorderColor = borderColor ?? Colors.grey.shade300;
    final activeHeight = height ?? 48.0;

    return SizedBox(
      width: 120,
      child: Container(
        height: activeHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: activeBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: activeBorderColor),
          boxShadow: [
            if (backgroundColor == null)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedCurrency,
            isExpanded: true,
            dropdownColor: activeBgColor,
            icon: Icon(Icons.keyboard_arrow_down, color: activeTextColor),
            style: TextStyle(
              color: activeTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            onChanged: (String? newValue) {
              if (newValue != null) {
                ref.read(userCurrencyProvider.notifier).state = newValue;
              }
            },
            items: CurrencyUtils.currencies
                .where((c) => c != '-- Select Currency --')
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: activeTextColor),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

