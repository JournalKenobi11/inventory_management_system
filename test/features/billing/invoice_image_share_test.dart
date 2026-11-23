import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/billing/widgets/printable_invoice_document.dart';
import 'package:inventory_management_system/features/customers/customers.dart';
import 'package:inventory_management_system/features/export/export.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  test('ShareService has shareInvoiceImage method', () async {
    final shareService = ShareService();
    expect(shareService.shareInvoiceImage, isNotNull);
  });

  testWidgets('InvoiceOverviewScreen shows Share Bill as Image and no Payment Received button',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final details = InvoiceDetails(
      invoice: const Invoice(
        id: 'inv-1',
        invoiceNumber: 1001,
        serviceId: 'srv-1',
        totalAmount: 1500.0,
        advanceAmount: 500.0,
        createdDate: '2026-11-23T10:00:00Z',
      ),
      customer: const Customer(
        id: 'cust-1',
        name: 'Rahul Patil',
        mobile: '9876543210',
        vehicleName: 'Ather 450X',
        createdDate: '2026-11-23T10:00:00Z',
      ),
      service: const Service(
        id: 'srv-1',
        customerId: 'cust-1',
        problemDesc: 'Brake pad replacement and general inspection',
        labourCharge: 300.0,
        serviceDate: '2026-11-23T10:00:00Z',
        advanceAmount: 500.0,
      ),
      items: const [
        InvoiceLineItem(
          partId: 'p-1',
          partName: 'Front Brake Pad Set',
          partNumber: 'BP-100',
          quantity: 1,
          priceEach: 1200.0,
          lineTotal: 1200.0,
        ),
      ],
      totalAmount: 1500.0,
      labourCharge: 300.0,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvoiceOverviewScreen(invoiceDetails: details),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify "Share Bill on WhatsApp (Image)" button is present
    expect(find.text('Share Bill on WhatsApp (Image)'), findsOneWidget);

    // 2. Verify PDF options are present
    expect(find.text('Download Bill (PDF)'), findsOneWidget);
    expect(find.text('Share PDF File'), findsOneWidget);

    // 3. Verify confusing "Payment Received / Done" button is completely removed
    expect(find.text('Payment Received / Done'), findsNothing);
    expect(find.text('Payment Received'), findsNothing);
  });

  testWidgets('PrintableInvoiceDocument renders official invoice with UPI QR Code',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final pdfData = InvoicePdfData(
      customer: const Customer(
        id: 'c-1',
        name: 'Amit Kumar',
        mobile: '9820011223',
        vehicleName: 'Ola S1 Pro',
        createdDate: '2026-11-23T10:00:00Z',
      ),
      service: const Service(
        id: 's-1',
        customerId: 'c-1',
        serviceDate: '2026-11-23T10:00:00Z',
        labourCharge: 500.0,
      ),
      invoice: const Invoice(
        id: 'i-1',
        invoiceNumber: 1002,
        serviceId: 's-1',
        totalAmount: 2000.0,
        advanceAmount: 500.0,
        createdDate: '2026-11-23T10:00:00Z',
      ),
      parts: const [
        InvoicePartLineItem(
          partId: 'p-1',
          partName: 'Battery Pack Cable',
          partNumber: 'BAT-101',
          quantity: 1,
          priceEach: 1500.0,
          lineTotal: 1500.0,
        ),
      ],
      labourCharge: 500.0,
      totalAmount: 2000.0,
      garageName: 'Mestry Motors',
      upiId: 'mestrymotors@okhdfcbank',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrintableInvoiceDocument(data: pdfData),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify shop branding
    expect(find.text('Mestry Motors'), findsOneWidget);
    // Verify invoice number
    expect(find.text('Invoice No: #1002'), findsOneWidget);
    // Verify QR code is rendered
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Scan to Pay via UPI'), findsOneWidget);
    expect(find.text('GPay • PhonePe • Paytm • BHIM'), findsOneWidget);
    // Verify balance due
    expect(find.text('Balance Due / Payable'), findsOneWidget);
  });
}
