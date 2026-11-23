import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/core/di/providers.dart';
import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/settings/settings.dart';

void main() {
  group('Shop Settings UI Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders shop settings screen with default establishment values',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: ShopSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Shop Settings'), findsOneWidget);
      expect(find.text('Establishment Branding'), findsOneWidget);
      expect(find.text('Mestry Motors'), findsOneWidget);
      expect(find.text('9359664276'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('shows validation error when business name is cleared',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: ShopSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final businessField = find.widgetWithText(TextFormField, 'Business Name *');
      await tester.enterText(businessField, '');
      final saveButton = find.text('Save Changes');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Business name is required'), findsOneWidget);
    });

    testWidgets('UpiPaymentQrDialog displays bill info and amount',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  UpiPaymentQrDialog.show(
                    context: context,
                    upiUri: 'upi://pay?pa=shop@upi&pn=Test&am=500.00&cu=INR',
                    businessName: 'Mestry Motors',
                    upiId: 'shop@upi',
                    amount: 500.0,
                    referenceNumber: '#INV-001',
                  );
                },
                child: const Text('Open QR'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open QR'));
      await tester.pumpAndSettle();

      expect(find.text('Mestry Motors'), findsOneWidget);
      expect(find.text('Bill Ref: #INV-001'), findsOneWidget);
      expect(find.text('₹500.00'), findsOneWidget);
      expect(find.text('GPay • PhonePe • Paytm • BHIM • Any UPI App'), findsOneWidget);
      expect(find.text('UPI ID: shop@upi'), findsOneWidget);
    });
  });
}
