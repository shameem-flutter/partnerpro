import 'package:flutter_test/flutter_test.dart';
import 'package:partnerpro/models/sales_agent_settings.dart';

void main() {
  group('SalesAgentSettings', () {
    test('parses string minimum_redemption_amount properly', () {
      final json = {
        'minimum_redemption_amount': '100.00',
      };
      final settings = SalesAgentSettings.fromJson(json);
      expect(settings.minimumRedemptionAmount, 100.0);
    });

    test('parses numeric minimum_redemption_amount properly', () {
      final json = {
        'minimum_redemption_amount': 250.50,
      };
      final settings = SalesAgentSettings.fromJson(json);
      expect(settings.minimumRedemptionAmount, 250.50);
    });

    test('falls back gracefully when minimum_redemption_amount is missing or invalid', () {
      final json = <String, dynamic>{};
      final settings = SalesAgentSettings.fromJson(json);
      expect(settings.minimumRedemptionAmount, 100.0);
    });
  });
}
