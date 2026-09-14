class SalesAgentSettings {
  final double minimumRedemptionAmount;

  SalesAgentSettings({
    required this.minimumRedemptionAmount,
  });

  factory SalesAgentSettings.fromJson(Map<String, dynamic> json) {
    final rawMin = json['minimum_redemption_amount'];
    double minAmount = 100.0;
    if (rawMin is num) {
      minAmount = rawMin.toDouble();
    } else if (rawMin is String) {
      minAmount = double.tryParse(rawMin) ?? 100.0;
    }
    return SalesAgentSettings(
      minimumRedemptionAmount: minAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minimum_redemption_amount': minimumRedemptionAmount.toStringAsFixed(2),
    };
  }
}
