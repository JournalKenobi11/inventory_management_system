import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/database/app_database.dart'
    as db;
import 'package:inventory_management_system/features/parts/models/part.dart';
import 'package:inventory_management_system/features/parts/repositories/sqlite/sqlite_part_repository.dart';

void main() {
  late db.AppDatabase database;
  late SqlitePartRepository repository;

  setUp(() {
    database = db.AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    repository = SqlitePartRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates part', () async {
    final part = Part(
      id: 'test-id',
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      category: 'Brakes',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
      currentStock: 10,
      lowStockThreshold: 5,
    );

    final result = await repository.create(part);

    expect(result, part);

    final saved = await repository.getById(part.id);

    expect(saved, part);
  });

  test('gets part by part number', () async {
    final part = Part(
      id: 'test-id',
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      category: 'Brakes',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
      currentStock: 10,
      lowStockThreshold: 5,
    );

    await repository.create(part);

    final result = await repository.getByPartNumber('BRK-001');

    expect(result, part);
  });

  test('gets all parts', () async {
    final part = Part(
      id: 'test-id',
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      category: 'Brakes',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
      currentStock: 10,
      lowStockThreshold: 5,
    );

    await repository.create(part);

    final result = await repository.getAll();

    expect(result.length, 1);
    expect(result.first.partName, 'Brake Pad');
  });

  test('gets low stock parts', () async {
    final part = Part(
      id: 'test-id',
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      category: 'Brakes',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
      currentStock: 3,
      lowStockThreshold: 5,
    );

    await repository.create(part);

    final result = await repository.getLowStock();

    expect(result.length, 1);
    expect(result.first.partNumber, 'BRK-001');
  });

  test('updates part', () async {
    final part = Part(
      id: 'test-id',
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      category: 'Brakes',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
      currentStock: 10,
      lowStockThreshold: 5,
    );

    await repository.create(part);

    final updated = part.copyWith(
      sellingPrice: 800.0,
      currentStock: 12,
    );

    await repository.update(updated);

    final result = await repository.getById(part.id);

    expect(result!.sellingPrice, 800.0);
    expect(result.currentStock, 12);
  });

  test('adjusts stock', () async {
    final part = Part(
      id: 'test-id',
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      category: 'Brakes',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
      currentStock: 10,
      lowStockThreshold: 5,
    );

    await repository.create(part);

    await repository.adjustStock(part.id, 5);

    final result = await repository.getById(part.id);

    expect(result!.currentStock, 15);
  });
}