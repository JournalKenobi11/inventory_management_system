import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:inventory_management_system/core/di/providers.dart';
import 'package:inventory_management_system/database/app_database.dart' hide Customer;
import 'package:inventory_management_system/features/dashboard/dashboard.dart';
import 'package:inventory_management_system/features/customers/customers.dart';
import 'package:inventory_management_system/features/expenses/expenses.dart';
import 'package:inventory_management_system/features/reports/reports.dart';
import 'package:inventory_management_system/features/salaries/salaries.dart';
import 'package:inventory_management_system/features/export/repositories/sqlite/sqlite_backup_repository.dart';

void main() {
  late AppDatabase db;
  late SqliteBackupRepository backupRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backupRepo = SqliteBackupRepository(db);
    await backupRepo.seedExtremeFakeData();
  });

  tearDown(() async {
    await backupRepo.deleteFakeData();
    await db.close();
  });

  testWidgets('DashboardScreen renders seeded extreme data on 360x640 mobile canvas without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
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
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Low Stock'), findsWidgets);
  });

  testWidgets('CustomerDetailScreen renders seeded extreme customer & bill on 360x640 canvas without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final custRows = await db.select(db.customers).get();
    final extremeCustomer = Customer(
      id: custRows.first.id,
      name: custRows.first.name,
      mobile: custRows.first.mobile,
      vehicleName: custRows.first.vehicleName,
      createdDate: custRows.first.createdDate,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: CustomerDetailScreen(customer: extremeCustomer),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(extremeCustomer.name), findsOneWidget);
    await tester.scrollUntilVisible(find.text('View Bill'), 100);
    expect(find.text('View Bill'), findsOneWidget);
  });

  testWidgets('ExpensesScreen renders seeded extreme expenses on 360x640 canvas without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
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
          home: Scaffold(body: ExpensesScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Filter: '), findsOneWidget);
  });

  testWidgets('ReportsScreen renders seeded extreme data on 360x640 canvas without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
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
          home: Scaffold(body: ReportsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ACTIVE REPORT PERIOD'), findsOneWidget);
  });

  testWidgets('EmployeeListScreen renders seeded extreme salary & period on 360x640 canvas without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
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
          home: Scaffold(body: EmployeeListScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Mark Today'), findsOneWidget);
  });
}
