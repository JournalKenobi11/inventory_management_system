import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/customers/customers.dart';

class FakeCustomerNotifier extends CustomerNotifier {
  final List<Customer> initialCustomers;
  FakeCustomerNotifier(this.initialCustomers);

  @override
  Future<List<Customer>> build() async => initialCustomers;
}

void main() {
  const testCustomer = Customer(
    id: 'cust-1',
    name: 'Rahul Sharma',
    mobile: '9876543210',
    vehicleName: 'Honda City',
    createdDate: '2026-10-01T10:00:00.000',
  );

  const mockDetails = InvoiceDetails(
    invoice: Invoice(
      id: 'inv-1',
      invoiceNumber: 42,
      serviceId: 'srv-1',
      totalAmount: 3200.0,
      createdDate: '2026-10-15T10:00:00.000',
    ),
    service: Service(
      id: 'srv-1',
      customerId: 'cust-1',
      problemDesc: 'Oil change and brake overhaul',
      labourCharge: 600.0,
      serviceDate: '2026-10-15T10:00:00.000',
      invoiceId: 'inv-1',
    ),
    customer: testCustomer,
    items: [
      InvoiceLineItem(
        partId: 'p-1',
        partName: 'Engine Oil',
        quantity: 1,
        priceEach: 1800.0,
        lineTotal: 1800.0,
      ),
      InvoiceLineItem(
        partId: 'p-2',
        partName: 'Brake Fluid',
        quantity: 1,
        priceEach: 800.0,
        lineTotal: 800.0,
      ),
    ],
    labourCharge: 600.0,
    totalAmount: 3200.0,
  );

  testWidgets(
      'CustomerQuickServiceSheet displays empty state when no services completed',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerBillingHistoryProvider('cust-1')
              .overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CustomerQuickServiceSheet(customer: testCustomer),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('No completed services yet'), findsOneWidget);
    expect(find.text('0'), findsAtLeastNWidgets(1)); // 0 services completed
    expect(find.text('₹0'), findsOneWidget); // ₹0 total spent
  });

  testWidgets(
      'CustomerQuickServiceSheet displays metrics and completed services list when history exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerBillingHistoryProvider('cust-1')
              .overrideWith((ref) => Future.value([mockDetails])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CustomerQuickServiceSheet(customer: testCustomer),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Customer name and header info
    expect(find.text('Rahul Sharma'), findsOneWidget);

    // Verify KPI summary
    expect(find.text('1'), findsAtLeastNWidgets(1)); // 1 service
    expect(find.text('₹3200'), findsNWidgets(2)); // Total spent and service amount

    // Verify Service details
    expect(find.text('#42'), findsOneWidget);
    expect(find.text('Oil change and brake overhaul'), findsOneWidget);
    expect(find.textContaining('Labour: ₹600'), findsOneWidget);
    expect(find.textContaining('Engine Oil'), findsOneWidget);
    expect(find.text('View Full Customer Details'), findsOneWidget);
  });

  testWidgets(
      'Long-pressing customer card in CustomerListScreen opens CustomerQuickServiceSheet',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customersProvider.overrideWith(
            () => FakeCustomerNotifier([testCustomer]),
          ),
          customerServiceRemindersProvider.overrideWith(
            (ref) => Future.value([]),
          ),
          customerBillingHistoryProvider('cust-1')
              .overrideWith((ref) => Future.value([mockDetails])),
        ],
        child: const MaterialApp(
          home: CustomerListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify customer card is present
    expect(find.text('Rahul Sharma'), findsOneWidget);

    // Long press on the customer card
    await tester.longPress(find.text('Rahul Sharma'));
    await tester.pumpAndSettle();

    // Verify bottom sheet appeared
    expect(find.byType(CustomerQuickServiceSheet), findsOneWidget);
    expect(find.text('Completed Services'), findsOneWidget);
    expect(find.text('#42'), findsOneWidget);
  });
}
