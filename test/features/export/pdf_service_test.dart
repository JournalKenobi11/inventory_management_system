import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/customers/customers.dart';
import 'package:inventory_management_system/features/export/export.dart';
import 'package:inventory_management_system/features/reports/reports.dart';

void main() {
  late PdfService pdfService;

  setUp(() {
    pdfService = PdfService();
  });

  test('generates valid PDF invoice matching DB totals and structure', () async {
    final customer = Customer(
      id: 'cust-1',
      name: 'Anil Sharma',
      mobile: '9845012345',
      vehicleName: 'Maruti Swift',
      createdDate: '2026-10-06T10:00:00.000Z',
    );

    final service = Service(
      id: 'srv-1',
      customerId: 'cust-1',
      problemDesc: 'General Service & Brake Bleeding',
      labourCharge: 400.0,
      serviceDate: '2026-10-06T10:00:00.000Z',
    );

    final parts = [
      const InvoicePartLineItem(
        partId: 'part-1',
        partName: 'Engine Oil',
        partNumber: 'OIL-5W30',
        quantity: 1,
        priceEach: 1200.0,
        lineTotal: 1200.0,
      ),
      const InvoicePartLineItem(
        partId: 'part-2',
        partName: 'Oil Filter',
        partNumber: 'FLT-09',
        quantity: 1,
        priceEach: 150.0,
        lineTotal: 150.0,
      ),
    ];

    // Total = 1200 + 150 + 400 = 1750
    final invoice = Invoice(
      id: 'inv-1',
      invoiceNumber: 1001,
      serviceId: 'srv-1',
      totalAmount: 1750.0,
      createdDate: '2026-10-06T10:00:00.000Z',
    );

    final pdfData = InvoicePdfData(
      invoice: invoice,
      service: service,
      customer: customer,
      parts: parts,
      labourCharge: 400.0,
      totalAmount: 1750.0,
      garageName: 'Express Garage Hub',
      garagePhone: '9845000000',
      garageAddress: '123 Main Road, Bangalore',
    );

    expect(pdfData.partsTotal, equals(1350.0));
    expect(pdfData.subtotal, equals(1750.0));
    expect(pdfData.grandTotal, equals(1750.0));

    final bytes = await pdfService.generateInvoicePdf(pdfData);

    expect(bytes, isNotEmpty);
    // PDF Magic bytes: %PDF-
    final header = utf8.decode(bytes.sublist(0, 5));
    expect(header, equals('%PDF-'));
  });

  test('computes GST fields accurately when GST is registered', () async {
    final customer = Customer(
      id: 'cust-2',
      name: 'Sunil Rao',
      mobile: '9876543210',
      createdDate: '2026-10-06T10:00:00.000Z',
    );

    final service = Service(
      id: 'srv-2',
      customerId: 'cust-2',
      labourCharge: 500.0,
      serviceDate: '2026-10-06T10:00:00.000Z',
    );

    final parts = [
      const InvoicePartLineItem(
        partId: 'part-3',
        partName: 'Brake Disc',
        partNumber: 'BRK-10',
        quantity: 1,
        priceEach: 1500.0,
        lineTotal: 1500.0,
      ),
    ];

    // Subtotal = 1500 + 500 = 2000
    // CGST @ 9% = 180, SGST @ 9% = 180, Total GST = 360, Grand Total = 2360
    final invoice = Invoice(
      id: 'inv-2',
      invoiceNumber: 1002,
      serviceId: 'srv-2',
      totalAmount: 2000.0,
      createdDate: '2026-10-06T10:00:00.000Z',
    );

    final gstPdfData = InvoicePdfData(
      invoice: invoice,
      service: service,
      customer: customer,
      parts: parts,
      labourCharge: 500.0,
      totalAmount: 2000.0,
      isGstRegistered: true,
      gstNumber: '29ABCDE1234F1Z5',
      gstRatePercentage: 18.0,
    );

    expect(gstPdfData.subtotal, equals(2000.0));
    expect(gstPdfData.cgstAmount, equals(180.0));
    expect(gstPdfData.sgstAmount, equals(180.0));
    expect(gstPdfData.totalGstAmount, equals(360.0));
    expect(gstPdfData.grandTotal, equals(2360.0));

    final bytes = await pdfService.generateInvoicePdf(gstPdfData);
    expect(bytes, isNotEmpty);
    final header = utf8.decode(bytes.sublist(0, 5));
    expect(header, equals('%PDF-'));
  });

  test('generates valid business performance report PDF', () async {
    final report = ComprehensiveReport(
      range: ReportDateRange.month(DateTime.now()),
      generatedAt: DateTime.now(),
      sales: const SalesReportData(
        totalSales: 50000.0,
        invoiceCount: 25,
        averageInvoiceValue: 2000.0,
        trends: [],
      ),
      expenses: const ExpenseReportData(
        totalBusinessExpenses: 15000.0,
        totalPersonalExpenses: 5000.0,
        totalSalaryExpenses: 12000.0,
        totalExpenses: 27000.0,
        categories: [],
      ),
      profit: const ProfitReportData(
        totalRevenue: 50000.0,
        totalExpenses: 27000.0,
        netProfit: 23000.0,
        profitMarginPercentage: 46.0,
      ),
      servicesCompleted: 25,
      topCustomers: const [],
      topParts: const [],
      salaries: const SalaryExpenseReportData(
        totalPaid: 12000.0,
        totalPending: 0.0,
        totalSalaryExpense: 12000.0,
        items: [],
      ),
      inventory: const InventorySummaryReportData(
        totalPartCount: 150,
        totalStockUnits: 500,
        totalInventoryValue: 125000.0,
        lowStockCount: 3,
        categoryBreakdown: {},
      ),
    );

    final bytes = await pdfService.generateReportPdf(report);
    expect(bytes, isNotEmpty);
    final header = utf8.decode(bytes.sublist(0, 5));
    expect(header, equals('%PDF-'));
  });
}
