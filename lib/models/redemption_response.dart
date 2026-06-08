class RedemptionResponse {
  final String convertedAmount;

  RedemptionResponse({required this.convertedAmount});

  factory RedemptionResponse.fromJson(Map<String, dynamic> json) {
    return RedemptionResponse(
      convertedAmount: json['converted_amount']?.toString() ?? '0.00',
    );
  }
}
