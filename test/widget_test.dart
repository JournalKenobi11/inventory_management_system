import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/main.dart';

void main() {
  testWidgets('App shell loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: InventoryManagementApp(),
      ),
    );

    expect(find.byType(InventoryManagementApp), findsOneWidget);
  });
}
