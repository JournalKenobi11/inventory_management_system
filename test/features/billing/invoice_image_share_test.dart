import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/customers/customers.dart';
import 'package:inventory_management_system/features/export/export.dart';

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
}
