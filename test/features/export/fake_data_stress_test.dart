import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/export/export.dart';
import 'package:inventory_management_system/features/export/repositories/sqlite/sqlite_backup_repository.dart';

void main() {
  late AppDatabase db;
  late SqliteBackupRepository repo;
  late BackupService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SqliteBackupRepository(db);
    service = BackupService(repo);
  });

  tearDown(() async {
    await db.close();
  });

  group('Tracked Fake Data Management', () {
    test('seedExtremeFakeData seeds extreme tracked records and deleteFakeData cleans them up completely', () async {
      // 1. Seed extreme fake data
      final seededCount = await service.seedExtremeFakeData();
      expect(seededCount, greaterThanOrEqualTo(10));

      // Verify that all seeded records are tracked with fake_ IDs and [FAKE] names
      final customers = await db.select(db.customers).get();
      final fakeCustomers = customers.where((c) => c.id.startsWith('fake_')).toList();
      expect(fakeCustomers.length, 2);
      expect(fakeCustomers.first.name, contains('[FAKE]'));
      expect(fakeCustomers.first.vehicleName, contains('[FAKE]'));

      final parts = await db.select(db.parts).get();
      final fakeParts = parts.where((p) => p.id.startsWith('fake_')).toList();
      expect(fakeParts.length, 2);
      expect(fakeParts.first.partName, contains('[FAKE]'));

      final invoices = await db.select(db.invoices).get();
      final fakeInvoices = invoices.where((i) => i.id.startsWith('fake_')).toList();
      expect(fakeInvoices.length, 2);
      expect(fakeInvoices.first.totalAmount, greaterThanOrEqualTo(500000.0));

      final employees = await db.select(db.employees).get();
      final fakeEmployees = employees.where((e) => e.id.startsWith('fake_')).toList();
      expect(fakeEmployees.length, 1);
      expect(fakeEmployees.first.name, contains('[FAKE]'));

      final pftx = await db.select(db.personalFinanceTransactions).get();
      final fakePftx = pftx.where((t) => t.id.startsWith('fake_')).toList();
      expect(fakePftx.length, 2);

      // 2. Insert a real customer to ensure it is not touched during clean-up
      await db.into(db.customers).insert(
            CustomersCompanion.insert(
              id: 'real_cust_123',
              name: 'Real Customer Rahul',
              mobile: '+91 98765 43210',
              createdDate: DateTime.now().toIso8601String(),
            ),
          );

      // 3. Delete fake data
      final deletedCount = await service.deleteFakeData();
      expect(deletedCount, greaterThanOrEqualTo(10));

      // 4. Verify fake records are gone, but real customer remains untouched
      final remainingCustomers = await db.select(db.customers).get();
      expect(remainingCustomers.length, 1);
      expect(remainingCustomers.first.id, 'real_cust_123');
      expect(remainingCustomers.first.name, 'Real Customer Rahul');

      final remainingParts = await db.select(db.parts).get();
      expect(remainingParts.where((p) => p.id.startsWith('fake_')).isEmpty, isTrue);

      final remainingInvoices = await db.select(db.invoices).get();
      expect(remainingInvoices.where((i) => i.id.startsWith('fake_')).isEmpty, isTrue);
    });

    test('seedExtremeFakeData is idempotent when called multiple times', () async {
      final firstCount = await service.seedExtremeFakeData();
      final secondCount = await service.seedExtremeFakeData();
      expect(firstCount, equals(secondCount));

      final customers = await db.select(db.customers).get();
      expect(customers.where((c) => c.id.startsWith('fake_')).length, 2);
    });
  });
}
