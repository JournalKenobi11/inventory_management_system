import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/main.dart';

void main() {
  final testDevices = <String, Size>{
    'Narrow Phone (iPhone SE 1st gen)': const Size(320, 568),
    'Compact Android': const Size(360, 640),
    'Modern Standard Phone': const Size(390, 844),
    'Large Phone (Pixel Pro)': const Size(412, 915),
    'Landscape / Short Screen': const Size(800, 400),
    'Tablet / Expanded Screen': const Size(1024, 768),
  };

  group('Responsive Layout Matrix Tests', () {
    for (final entry in testDevices.entries) {
      testWidgets('Renders app without RenderFlex overflow on ${entry.key} (${entry.value.width.toInt()}x${entry.value.height.toInt()})', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(child: InventoryManagementApp()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Expect app to mount cleanly
        expect(find.byType(InventoryManagementApp), findsOneWidget);

        // Check navigation mode based on width
        if (entry.value.width >= 720) {
          // Tablet layout: NavigationRail is visible
          expect(find.byType(NavigationRail), findsOneWidget);
        } else {
          // Mobile/compact layout: NavigationBar is visible
          expect(find.byType(NavigationBar), findsOneWidget);
        }
      });
    }

    testWidgets('Renders properly under 1.5x accessibility font scaling on compact phone (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        const ProviderScope(child: InventoryManagementApp()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InventoryManagementApp), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Navigation switches tabs and opens Drawer without overflow across screen sizes', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(child: InventoryManagementApp()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Open drawer on narrow phone
      final menuButton = find.byIcon(Icons.menu).first;
      await tester.tap(menuButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Drawer), findsOneWidget);

      // Close drawer by tapping outside or pressing back
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Billing tab (index 1)
      final billingDestination = find.text('Billing');
      if (billingDestination.evaluate().isNotEmpty) {
        await tester.tap(billingDestination.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Switch to Customers tab (index 3)
      final customersDestination = find.text('Customers');
      if (customersDestination.evaluate().isNotEmpty) {
        await tester.tap(customersDestination.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
    });
  });
}
