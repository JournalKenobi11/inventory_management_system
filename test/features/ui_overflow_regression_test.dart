import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/customers/customers.dart';
import 'package:inventory_management_system/features/dashboard/dashboard.dart';

class _FakeCustomerNotifier extends CustomerNotifier {
  final List<Customer> initialCustomers;
  _FakeCustomerNotifier(this.initialCustomers);

  @override
  Future<List<Customer>> build() async => initialCustomers;
}

void main() {
  const compactPhoneSize = Size(360, 640);
  const accessibilityScale = 1.3;

  final sampleCustomer = Customer(
    id: 'cust-overflow-1',
    name: 'Vikramaditya Chandrasekharan',
    mobile: '9876543210',
    vehicleName: 'Mahindra XUV700 AX7 Luxury',
    createdDate: '2026-11-20',
  );

  final sampleJob = Service(
    id: 'job-overflow-1',
    customerId: sampleCustomer.id,
    problemDesc:
        'Complete Battery & Alternator Assembly Overhaul (Special Import Part)',
    labourCharge: 0.0,
    serviceDate: '2026-11-23',
    status: 'pending',
    advanceAmount: 25000.0,
    advancePaymentMode: 'UPI',
    advanceNotes: 'Advance payment received via PhonePe on 23rd Nov',
  );

  Widget createTestContainer({
    required Widget child,
  }) {
    return ProviderScope(
      overrides: [
        customersProvider.overrideWith(
          () => _FakeCustomerNotifier([sampleCustomer]),
        ),
        pendingJobCardsProvider.overrideWith(
          (ref) => Future.value([sampleJob]),
        ),
        customerPendingJobCardsProvider.overrideWith(
          (ref, id) => Future.value([sampleJob]),
        ),
        customerBillingHistoryProvider.overrideWith(
          (ref, id) => Future.value(<InvoiceDetails>[]),
        ),
        customerReminderProvider.overrideWith(
          (ref, id) => Future.value(null),
        ),
        dashboardProvider.overrideWith(
          (ref, range) => Future.value(const DashboardSummary.empty()),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: MediaQuery(
          data: const MediaQueryData(
            size: compactPhoneSize,
            textScaler: TextScaler.linear(accessibilityScale),
          ),
          child: child,
        ),
      ),
    );
  }

  group('UI Overflow Regression & Accessibility Tests', () {
    testWidgets(
      'PendingJobCardsSheet renders cleanly on 360x640 with 1.3x TextScale',
      (tester) async {
        tester.view.physicalSize = compactPhoneSize;
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = accessibilityScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        bool errorCaught = false;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exception.toString().contains('overflowed')) {
            errorCaught = true;
          }
          originalOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        await tester.pumpWidget(
          createTestContainer(
            child: const Scaffold(
              body: PendingJobCardsSheet(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PendingJobCardsSheet), findsOneWidget);
        expect(find.text('Active Work Orders'), findsOneWidget);
        expect(find.text('Complete & Bill'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(errorCaught, isFalse,
            reason: 'RenderFlex overflow occurred in PendingJobCardsSheet');
      },
    );

    testWidgets(
      'CustomerDetailScreen active work order card renders cleanly without button bleed',
      (tester) async {
        tester.view.physicalSize = compactPhoneSize;
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = accessibilityScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        bool errorCaught = false;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exception.toString().contains('overflowed')) {
            errorCaught = true;
          }
          originalOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        await tester.pumpWidget(
          createTestContainer(
            child: CustomerDetailScreen(customer: sampleCustomer),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CustomerDetailScreen), findsOneWidget);

        final cardFinder = find.text('Active Work Order in Progress');
        await tester.scrollUntilVisible(cardFinder, 200);
        await tester.pumpAndSettle();

        expect(cardFinder, findsOneWidget);
        expect(find.text('Complete & Bill'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(errorCaught, isFalse,
            reason: 'RenderFlex overflow occurred in CustomerDetailScreen');
      },
    );

    testWidgets(
      'DashboardScreen renders pending alert and notification badge on 360x640 with 1.3x TextScale',
      (tester) async {
        tester.view.physicalSize = compactPhoneSize;
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = accessibilityScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        bool errorCaught = false;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exception.toString().contains('overflowed')) {
            errorCaught = true;
          }
          originalOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        await tester.pumpWidget(
          createTestContainer(
            child: const DashboardScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DashboardScreen), findsOneWidget);
        // Verify notification badge icon exists in AppBar
        expect(find.byIcon(Icons.pending_actions_rounded), findsOneWidget);
        expect(find.byType(Badge), findsWidgets);
        expect(errorCaught, isFalse,
            reason: 'RenderFlex overflow occurred in DashboardScreen');
      },
    );
  });
}
