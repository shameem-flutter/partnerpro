class RedemptionBalanceResponse {
  final bool hasPendingRedemption;
  final String availableBalance;

  RedemptionBalanceResponse({
    required this.hasPendingRedemption,
    required this.availableBalance,
  });

  factory RedemptionBalanceResponse.fromJson(Map<String, dynamic> json) {
    return RedemptionBalanceResponse(
      hasPendingRedemption: json['has_pending_redemption'] as bool? ?? false,
      availableBalance: json['available_balance']?.toString() ?? '0.00',
    );
  }
}
