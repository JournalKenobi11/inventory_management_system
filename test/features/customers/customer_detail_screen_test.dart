import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/customers/customers.dart';

void main() {
  const testCustomer = Customer(
    id: 'cust-1',
    name: 'Rahul Sharma',
    mobile: '9876543210',
    vehicleName: 'Honda City',
    createdDate: '2026-10-01T10:00:00.000',
  );

  testWidgets('CustomerDetailScreen displays customer info and empty state when no history',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerBillingHistoryProvider('cust-1')
              .overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: CustomerDetailScreen(customer: testCustomer),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Customer Info
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('Honda City'), findsAtLeastNWidgets(1));
    expect(find.text('Service History'), findsOneWidget);

    // Verify Empty State
    expect(find.text('No service history yet'), findsOneWidget);
  });

  testWidgets('CustomerDetailScreen displays service cards when history exists',
      (WidgetTester tester) async {
    const mockDetails = InvoiceDetails(
      invoice: Invoice(
        id: 'inv-1',
        invoiceNumber: 12,
        serviceId: 'srv-1',
        totalAmount: 2650.0,
        createdDate: '2026-10-08T10:00:00.000',
      ),
      service: Service(
        id: 'srv-1',
        customerId: 'cust-1',
        problemDesc: 'Brake pad replacement',
        labourCharge: 500.0,
        serviceDate: '2026-10-08T10:00:00.000',
        invoiceId: 'inv-1',
      ),
      customer: testCustomer,
      items: [
        InvoiceLineItem(
          partId: 'p-1',
          partName: 'Brake Pad',
          partNumber: 'BP-1',
          quantity: 2,
          priceEach: 850.0,
          lineTotal: 1700.0,
        ),
        InvoiceLineItem(
          partId: 'p-2',
          partName: 'Oil Filter',
          quantity: 1,
          priceEach: 450.0,
          lineTotal: 450.0,
        ),
      ],
      labourCharge: 500.0,
      totalAmount: 2650.0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerBillingHistoryProvider('cust-1')
              .overrideWith((ref) => Future.value([mockDetails])),
        ],
        child: const MaterialApp(
          home: CustomerDetailScreen(customer: testCustomer),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify invoice number and items
    expect(find.text('Invoice #12'), findsOneWidget);
    expect(find.text('Brake pad replacement'), findsOneWidget);
    expect(find.text('Brake Pad × 2'), findsOneWidget);
    expect(find.text('₹1700.00'), findsOneWidget);
    expect(find.text('Oil Filter × 1'), findsOneWidget);
    expect(find.text('₹450.00'), findsOneWidget);
    expect(find.text('₹500.00'), findsOneWidget);
    expect(find.text('₹2650.00'), findsOneWidget);
    expect(find.text('View Bill'), findsOneWidget);
  });
}
