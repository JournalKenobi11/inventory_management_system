import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:inventory_management_system/database/app_database.dart'
    as db;
import 'package:inventory_management_system/features/customers/models/customer.dart';
import 'package:inventory_management_system/features/customers/repositories/sqlite/sqlite_customer_repository.dart';

void main() {
  late db.AppDatabase database;
  late SqliteCustomerRepository repository;

  setUp(() {
    database = db.AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    repository = SqliteCustomerRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates customer', () async {
    final customer = Customer(
      id: 'test-id',
      name: 'John',
      mobile: '9876543210',
      vehicleName: 'Honda',
      createdDate: '2026-01-01',
    );

    final result = await repository.create(customer);

    expect(result, customer);

    final saved = await repository.getById(customer.id);

    expect(saved, customer);
  });

  test('gets all customers', () async {
    final customer = Customer(
      id: 'test-id',
      name: 'John',
      mobile: '9876543210',
      vehicleName: 'Honda',
      createdDate: '2026-01-01',
    );

    await repository.create(customer);

    final result = await repository.getAll();

    expect(result.length, 1);
    expect(result.first.name, 'John');
  });

  test('updates customer', () async {
    final customer = Customer(
      id: 'test-id',
      name: 'John',
      mobile: '9876543210',
      vehicleName: 'Honda',
      createdDate: '2026-01-01',
    );

    await repository.create(customer);

    final updated = customer.copyWith(
      name: 'Alex',
    );

    await repository.update(updated);

    final result = await repository.getById(customer.id);

    expect(result!.name, 'Alex');
  });

  test('deletes customer', () async {
    final customer = Customer(
      id: 'test-id',
      name: 'John',
      mobile: '9876543210',
      vehicleName: 'Honda',
      createdDate: '2026-01-01',
    );

    await repository.create(customer);

    await repository.delete(customer.id);

    final result = await repository.getById(customer.id);

    expect(result, null);
  });

  test('searches customers', () async {
    final customer = Customer(
      id: 'test-id',
      name: 'John',
      mobile: '9876543210',
      vehicleName: 'Honda',
      createdDate: '2026-01-01',
    );

    await repository.create(customer);

    final result = await repository.search('John');

    expect(result.length, 1);
  });
}