import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/core/di/providers.dart';
import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/parts/repositories/sqlite/sqlite_part_repository.dart';
import 'package:inventory_management_system/features/parts/screens/part_list_screen.dart';
import 'package:inventory_management_system/features/parts/services/part_service.dart';

void main() {
  group('PartListScreen Inventory Priority Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders low stock items at the top and normal items alphabetically',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = PartService(
        SqlitePartRepository(db),
      );

      // Seed parts
      await service.createPart(
        partNumber: 'P-Z',
        partName: 'Zebra Tyres',
        purchasePrice: 1000,
        sellingPrice: 1500,
        currentStock: 20,
        lowStockThreshold: 5,
      );
      await service.createPart(
        partNumber: 'P-A',
        partName: 'Alpha Battery',
        purchasePrice: 2000,
        sellingPrice: 2500,
        currentStock: 10,
        lowStockThreshold: 5,
      );
      await service.createPart(
        partNumber: 'P-EMPTY',
        partName: 'Brake Disc',
        purchasePrice: 300,
        sellingPrice: 500,
        currentStock: 0,
        lowStockThreshold: 5,
      );
      await service.createPart(
        partNumber: 'P-LOW',
        partName: 'Chain Lubricant',
        purchasePrice: 150,
        sellingPrice: 250,
        currentStock: 2,
        lowStockThreshold: 5,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: PartListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all part name text widgets in order
      final nameFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.style?.fontWeight == FontWeight.bold) &&
            [
              'BRAKE DISC',
              'CHAIN LUBRICANT',
              'ALPHA BATTERY',
              'ZEBRA TYRES',
            ].contains(widget.data),
      );

      final renderedNames = tester
          .widgetList<Text>(nameFinder)
          .map((t) => t.data)
          .toList();

      // 0 stock: BRAKE DISC
      // 2 stock: CHAIN LUBRICANT
      // Normal in-stock: ALPHA BATTERY, then ZEBRA TYRES
      expect(renderedNames, [
        'BRAKE DISC',
        'CHAIN LUBRICANT',
        'ALPHA BATTERY',
        'ZEBRA TYRES',
      ]);

      // Both LOW STOCK badges should be visible
      expect(find.text('LOW STOCK'), findsNWidgets(2));
      // Both IN STOCK badges should be visible
      expect(find.text('IN STOCK'), findsNWidgets(2));
    });
  });
}
