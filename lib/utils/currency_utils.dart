class CurrencyUtils {
  static const List<String> currencies = [
    '-- Select Currency --',
    'USD',
    'INR',
    'OMR',
    'AED',
    'SAR',
  ];

  static double convertAmount(
    double amount,
    String fromCurrency,
    String targetCurrency,
  ) {
    final cleanFrom = (fromCurrency.isEmpty || fromCurrency == 'False')
        ? 'AED'
        : fromCurrency.toUpperCase();
    final cleanTarget =
        (targetCurrency == '-- Select Currency --' || targetCurrency.isEmpty)
        ? cleanFrom
        : targetCurrency.toUpperCase();

    if (cleanFrom == cleanTarget) return amount;

    // Rates relative to AED (1 AED = X currency)
    final rates = {
      'AED': 1.0,
      'USD': 0.27226,
      'INR': 22.68,
      'OMR': 0.1049,
      'SAR': 1.0215,
    };

    final rateFrom = rates[cleanFrom] ?? 1.0;
    final rateTo = rates[cleanTarget] ?? 1.0;

    final amountInAED = amount / rateFrom;
    return amountInAED * rateTo;
  }
}
