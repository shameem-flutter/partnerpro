import 'package:flutter_test/flutter_test.dart';
import 'package:partnerpro/models/dashboard_data.dart';
import 'package:partnerpro/models/sales_report.dart';

void main() {
  group('DashboardData parsing tests', () {
    test('Parse Dashboard Data JSON with direct and referral orders', () {
      final Map<String, dynamic> json = {
        "orders": [
          {
            "invoice_date": "2026-06-01",
            "platform": "Vercel",
            "invoice_reference_no": "INV001",
            "customer_name": "Test Customer",
            "salesperson_name": "Agent A",
            "company_name": "Test Corp",
            "currency": "AED",
            "commission_amount_total": "120.50",
            "is_approved": true,
            "invoice_details": [
              {
                "product_name": "Product A",
                "quantity": 2,
                "unit_price": "50.00",
                "subtotal": "100.00",
                "is_approved": true
              }
            ],
            "referral_details": []
          }
        ],
        "referral_orders": [
          {
            "invoice_date": "2026-06-02",
            "platform": "Shopify",
            "invoice_reference_no": "INV002",
            "customer_name": "Ref Customer",
            "salesperson_name": "Agent B",
            "company_name": "Ref Corp",
            "currency": "AED",
            "commission_amount_total": "50.00",
            "is_approved": false,
            "invoice_details": [
              {
                "product_name": "Product B",
                "quantity": 1,
                "unit_price": "50.00",
                "subtotal": "50.00",
                "is_approved": false
              }
            ],
            "referral_details": [
              {
                "salesperson_id": "30",
                "salesperson_name": "Agent A",
                "salesperson_email": "agent@example.com",
                "type": "percentage",
                "percentage": "10",
                "fixed_amount": "0",
                "currency": "AED",
                "commission_amount": "5.00"
              }
            ]
          }
        ],
        "today_date": "2026-06-03",
        "total_commission": "120.50",
        "approved_orders_count": 1,
        "pending_orders_count": 0,
        "total_commission_ref": "5.00",
        "ref_approved_orders_count": 0,
        "ref_pending_orders_count": 1
      };

      final data = DashboardData.fromJson(json);

      expect(data.orders.length, 1);
      expect(data.orders[0].companyName, 'Test Corp');
      expect(data.orders[0].isApproved, true);
      expect(data.orders[0].invoiceDetails[0].isApproved, true);
      expect(data.orders[0].commissionAmountTotal, 120.50);

      expect(data.referralOrders.length, 1);
      expect(data.referralOrders[0].isApproved, false);
      expect(data.referralOrders[0].invoiceDetails[0].isApproved, false);
      expect(data.referralOrders[0].referralDetails[0].commissionAmount, 5.00);

      expect(data.totalCommission, 120.50);
      expect(data.totalCommissionRef, 5.00);
      expect(data.todayDate, "2026-06-03");
    });
  });

  group('SalesReportResponse parsing tests', () {
    test('Parse Sales Report response', () {
      final Map<String, dynamic> json = {
        "sales_report": [
          {
            "id": 117,
            "invoice_date": "2024-12-20",
            "invoice_reference_no": "IN/FEB/2024/0160",
            "customer_name": "DTECH INFORMATION TECHNOLOGY & OUTSOURCING PVT LTD",
            "platform": "FEBNO TECHNOLOGIES PRIVATE LIMITED",
            "currency": "INR",
            "currency_amount": "621.12",
            "debit": "0.00",
            "credit": "26.98",
            "balance": "1134.10"
          }
        ],
        "total_debit": "0",
        "total_credit": "1134.10",
        "total_balance": "1134.10"
      };

      final response = SalesReportResponse.fromJson(json);

      expect(response.salesReport.length, 1);
      expect(response.salesReport[0].id, 117);
      expect(response.salesReport[0].customerName, "DTECH INFORMATION TECHNOLOGY & OUTSOURCING PVT LTD");
      expect(response.salesReport[0].balance, "1134.10");
      expect(response.totalBalance, "1134.10");
    });
  });
}