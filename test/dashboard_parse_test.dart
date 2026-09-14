import 'package:flutter_test/flutter_test.dart';
import 'package:partnerpro/models/dashboard_data.dart';
import 'package:partnerpro/models/sales_report.dart';
import 'package:partnerpro/models/admin_models.dart' as admin;
import 'package:partnerpro/models/admin_models.dart' hide SalesReportResponse;

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
            "approved_at": "2026-05-20T19:03:39.018448Z",
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
      expect(response.salesReport[0].invoiceDate, "2024-12-20");
      expect(response.salesReport[0].approvedAt, "2026-05-20T19:03:39.018448Z");
      expect(response.salesReport[0].displayDate, "2026-05-20T19:03:39.018448Z");
      expect(response.salesReport[0].customerName, "DTECH INFORMATION TECHNOLOGY & OUTSOURCING PVT LTD");
      expect(response.salesReport[0].balance, "1134.10");
      expect(response.totalBalance, "1134.10");
    });

    test('Parse sales-report-no-balance response and calculate balance properly on app side', () {
      final Map<String, dynamic> json = {
        "sales_report": [
          {
            "id": 19187,
            "invoice_date": "2026-08-22",
            "invoice_reference_no": "TEST-AUG22-002",
            "customer_name": "Test Customer 2",
            "platform": "Febno",
            "currency": "AED",
            "currency_amount": "250.00",
            "debit": "0.00",
            "credit": "250.00",
            "approved_at": "2026-09-04T12:00:00Z"
          },
          {
            "id": 19186,
            "invoice_date": "2026-08-21",
            "invoice_reference_no": "TEST-AUG21-001",
            "customer_name": "Test Customer 1",
            "platform": "Febno",
            "currency": "AED",
            "currency_amount": "150.00",
            "debit": "0.00",
            "credit": "150.00",
            "approved_at": "2026-09-04T10:45:00Z"
          },
          {
            "id": 19184,
            "invoice_date": "2026-08-29",
            "invoice_reference_no": "77777777",
            "customer_name": "Testing7",
            "platform": "Subscription Invoice",
            "currency": "AED",
            "currency_amount": "-100.00",
            "debit": "0.00",
            "credit": "-100.00",
            "approved_at": "2026-08-29T11:16:54.845617Z"
          },
          {
            "id": 19183,
            "invoice_date": "2026-08-29",
            "invoice_reference_no": "66666666",
            "customer_name": "Testing4",
            "platform": "Subscription Invoice",
            "currency": "AED",
            "currency_amount": "-50.00",
            "debit": "0.00",
            "credit": "-50.00",
            "approved_at": "2026-08-29T11:13:18.106934Z"
          },
          {
            "id": 19181,
            "invoice_date": "2026-08-29",
            "invoice_reference_no": "444444444",
            "customer_name": "Testing2",
            "platform": "Subscription Invoice",
            "currency": "AED",
            "currency_amount": "9.72",
            "debit": "0.00",
            "credit": "9.72",
            "approved_at": "2026-08-29T10:48:33.176082Z"
          },
          {
            "id": 19180,
            "invoice_date": "2026-08-29",
            "invoice_reference_no": "333333",
            "customer_name": "Testing",
            "platform": "Subscription Invoice",
            "currency": "AED",
            "currency_amount": "194.32",
            "debit": "0.00",
            "credit": "194.32",
            "approved_at": "2026-08-29T10:21:21.630723Z"
          },
          {
            "id": 19175,
            "invoice_date": "2026-07-03",
            "invoice_reference_no": "1809423",
            "customer_name": "MIND MERGE TECHNOLOGIES L.L.C",
            "platform": "Subscription Invoice",
            "currency": "AED",
            "currency_amount": "12.02",
            "debit": "0.00",
            "credit": "500.00",
            "approved_at": "2026-08-08T07:08:35.686172Z"
          },
          {
            "id": 19182,
            "invoice_date": "2026-08-29",
            "invoice_reference_no": "5555555",
            "customer_name": "Testing3",
            "platform": "Subscription Invoice",
            "currency": "AED",
            "currency_amount": "15.54",
            "debit": "0.00",
            "credit": "15.54",
            "approved_at": null
          }
        ],
        "total_debit": "0",
        "total_credit": "969.58",
        "total_balance": "969.58"
      };

      final response = admin.SalesReportResponse.fromJson(json);

      expect(response.entries.length, 8);
      // Verify raw response array order is preserved exactly
      expect(response.entries[0].id, 19187);
      expect(response.entries[1].id, 19186);
      expect(response.entries[2].id, 19184);
      expect(response.entries[3].id, 19183);
      expect(response.entries[4].id, 19181);
      expect(response.entries[5].id, 19180);
      expect(response.entries[6].id, 19175);
      expect(response.entries[7].id, 19182);

      // Verify running balances calculated starting from initial balance 0.0 at the first order (19182):
      // Entry 7 (19182, first order): 0.0 + 15.54 = 15.54
      expect(response.entries[7].balance, 15.54);
      // Entry 6 (19175): 15.54 + 500.00 = 515.54
      expect(response.entries[6].balance, 515.54);
      // Entry 5 (19180): 515.54 + 194.32 = 709.86
      expect(response.entries[5].balance, 709.86);
      // Entry 4 (19181): 709.86 + 9.72 = 719.58
      expect(response.entries[4].balance, 719.58);
      // Entry 3 (19183): 719.58 + (-50.00) = 669.58
      expect(response.entries[3].balance, 669.58);
      // Entry 2 (19184): 669.58 + (-100.00) = 569.58
      expect(response.entries[2].balance, 569.58);
      // Entry 1 (19186): 569.58 + 150.00 = 719.58
      expect(response.entries[1].balance, 719.58);
      // Entry 0 (19187, latest order): 719.58 + 250.00 = 969.58
      expect(response.entries[0].balance, 969.58);

      expect(response.totalBalance, 969.58);
      expect(response.totalCommission, 969.58);
      expect(response.totalDebit, 0.0);
    });

    test('Parse user SalesReportResponse from sales_report.dart without balance and calculate sequentially from first order', () {
      final Map<String, dynamic> json = {
        "sales_report": [
          {
            "id": 19187,
            "invoice_date": "2026-08-22",
            "invoice_reference_no": "TEST-AUG22-002",
            "customer_name": "Test Customer 2",
            "platform": "Febno",
            "currency": "AED",
            "currency_amount": "250.00",
            "debit": "0.00",
            "credit": "250.00",
            "approved_at": "2026-08-22T08:31:00Z"
          },
          {
            "id": 19186,
            "invoice_date": "2026-08-22",
            "invoice_reference_no": "TEST-AUG22-001",
            "customer_name": "Test Customer",
            "platform": "Febno",
            "currency": "AED",
            "currency_amount": "150.00",
            "debit": "0.00",
            "credit": "150.00",
            "approved_at": "2026-08-22T08:30:00Z"
          }
        ],
        "total_debit": "0.00",
        "total_credit": "400.00",
        "total_balance": "400.00"
      };

      final response = SalesReportResponse.fromJson(json);

      expect(response.salesReport.length, 2);
      expect(response.salesReport[1].balance, "150.00");
      expect(response.salesReport[0].balance, "400.00");
      expect(response.totalBalance, "400.00");
    });
  });

  group('AllSalespersonOrdersResponse parsing tests', () {
    test('Parse AllSalespersonOrdersResponse JSON and check availableBalance getter', () {
      final Map<String, dynamic> json = {
        "salespersons": [],
        "available_platforms": ["Vercel"],
        "orders_by_month": {},
        "selected_salesperson_id": "1",
        "total_debit": "100.00",
        "total_credit": "500.00",
        "total_balance": "400.00"
      };

      final response = AllSalespersonOrdersResponse.fromJson(json);

      expect(response.totalDebit, 100.00);
      expect(response.totalCredit, 500.00);
      expect(response.totalBalance, 400.00);
      expect(response.availableBalance, 400.00);
    });
  });
}