import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/core/di/providers.dart';
import 'package:inventory_management_system/core/widgets/animated_app_drawer.dart';
import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/settings/settings.dart';

void main() {
  group('AnimatedAppDrawer Branding Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders dynamic shop settings in drawer header and shows Shop Settings menu item',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            shopSettingsProvider.overrideWith(() => _MockSettingsNotifier(
                  const ShopSettings(
                    businessName: 'Dynamic EV Garage',
                    services: 'Custom Battery Packs & Repairs',
                  ),
                )),
          ],
          child: MaterialApp(
            home: Scaffold(
              drawer: AnimatedAppDrawer(
                currentIndex: 0,
                onNavigate: (_) {},
              ),
              body: const Center(child: Text('Home')),
            ),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Dynamic EV Garage'), findsOneWidget);
      expect(find.text('Custom Battery Packs & Repairs'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Shop Settings'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(find.text('Shop Settings'), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
    });
  });
}

class _MockSettingsNotifier extends ShopSettingsNotifier {
  final ShopSettings _settings;
  _MockSettingsNotifier(this._settings);

  @override
  Future<ShopSettings> build() async => _settings;
}
