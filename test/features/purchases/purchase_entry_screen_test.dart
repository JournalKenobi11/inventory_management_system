import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/features/parts/parts.dart';
import 'package:inventory_management_system/features/purchases/screens/purchase_entry_screen.dart';

class FakePartNotifier extends PartNotifier {
  final List<Part> _parts;
  FakePartNotifier(this._parts);

  @override
  Future<List<Part>> build() async => _parts;
}

void main() {
  const part1 = Part(
    id: 'p-1',
    partNumber: 'OIL-FLT-001',
    partName: 'Engine Oil Filter',
    category: 'Filters',
    purchasePrice: 150.0,
    sellingPrice: 300.0,
    currentStock: 5,
    lowStockThreshold: 2,
  );

  const part2 = Part(
    id: 'p-2',
    partNumber: 'BRK-PAD-002',
    partName: 'Front Brake Pads',
    category: 'Brakes',
    purchasePrice: 450.0,
    sellingPrice: 800.0,
    currentStock: 12,
    lowStockThreshold: 4,
  );

  testWidgets('PurchaseEntryScreen renders part dropdown with stable string IDs (BUG-006)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partsProvider.overrideWith(() => FakePartNotifier([part1, part2])),
        ],
        child: const MaterialApp(
          home: PurchaseEntryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify screen elements
    expect(find.text('Record Purchase'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('Amount Paid (per unit)'), findsOneWidget);

    // Tap dropdown to expand items
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    // Verify dropdown items
    expect(find.text('OIL-FLT-001 - Engine Oil Filter').last, findsOneWidget);
    expect(find.text('BRK-PAD-002 - Front Brake Pads').last, findsOneWidget);

    // Select part 2
    await tester.tap(find.text('BRK-PAD-002 - Front Brake Pads').last);
    await tester.pumpAndSettle();

    // Verify purchase price auto-filled from part 2
    expect(find.text('450.00'), findsOneWidget);
  });

  testWidgets('PurchaseEntryScreen with preselectedPartId sets initial value correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partsProvider.overrideWith(() => FakePartNotifier([part1, part2])),
        ],
        child: const MaterialApp(
          home: PurchaseEntryScreen(preselectedPartId: 'p-2'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial value auto-filled
    expect(find.text('450.00'), findsOneWidget);
    expect(find.text('BRK-PAD-002 - Front Brake Pads'), findsOneWidget);
  });
}
