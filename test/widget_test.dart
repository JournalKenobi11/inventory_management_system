import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/main.dart';

void main() {
  testWidgets('App shell loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: InventoryManagementApp()),
    );

    expect(find.byType(InventoryManagementApp), findsOneWidget);
  });

  testWidgets(
    'Hamburger button is present at top-left and opens existing Drawer on tap',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: InventoryManagementApp()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify hamburger icon button exists
      final menuButtonFinder = find.byIcon(Icons.menu);
      expect(menuButtonFinder, findsWidgets);

      // Verify Drawer is initially not open
      expect(find.text('Garage & Inventory'), findsNothing);

      // Tap the hamburger button
      await tester.tap(menuButtonFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify existing Drawer opened
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('Garage & Inventory'), findsOneWidget);
      expect(find.text('Personal Finance'), findsOneWidget);
    },
  );
}
