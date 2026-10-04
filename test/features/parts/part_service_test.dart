import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/core/errors/app_exceptions.dart';
import 'package:inventory_management_system/database/app_database.dart'
    as db;
import 'package:inventory_management_system/features/parts/repositories/sqlite/sqlite_part_repository.dart';
import 'package:inventory_management_system/features/parts/services/part_service.dart';

void main() {
  late db.AppDatabase database;
  late PartService service;

  setUp(() {
    database = db.AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    final repository = SqlitePartRepository(database);
    service = PartService(repository);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates a part', () async {
    final part = await service.createPart(
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      category: 'Brakes',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
      currentStock: 10,
      lowStockThreshold: 5,
    );

    expect(part.partNumber, 'BRK-001');
    expect(part.partName, 'Brake Pad');
    expect(part.purchasePrice, 500.0);
    expect(part.sellingPrice, 750.0);
    expect(part.currentStock, 10);
  });

  test('rejects duplicate part number', () async {
    await service.createPart(
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
    );

    expect(
      () => service.createPart(
        partNumber: 'BRK-001',
        partName: 'Another Brake Pad',
        purchasePrice: 600.0,
        sellingPrice: 850.0,
      ),
      throwsA(isA<DuplicatePartNumberException>()),
    );
  });

  test('rejects negative purchase price', () async {
    expect(
      () => service.createPart(
        partNumber: 'BRK-001',
        partName: 'Brake Pad',
        purchasePrice: -500.0,
        sellingPrice: 750.0,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects negative selling price', () async {
    expect(
      () => service.createPart(
        partNumber: 'BRK-001',
        partName: 'Brake Pad',
        purchasePrice: 500.0,
        sellingPrice: -750.0,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects negative initial stock', () async {
    expect(
      () => service.createPart(
        partNumber: 'BRK-001',
        partName: 'Brake Pad',
        purchasePrice: 500.0,
        sellingPrice: 750.0,
        currentStock: -1,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('adjusts stock upward', () async {
    final part = await service.createPart(
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
      currentStock: 10,
    );

    await service.adjustStock(part.id, 5);

    final updated = await service.getPartById(part.id);

    expect(updated!.currentStock, 15);
  });

  test('rejects stock adjustment that makes stock negative', () async {
    final part = await service.createPart(
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
      currentStock: 3,
    );

    expect(
      () => service.adjustStock(part.id, -4),
      throwsA(isA<InsufficientStockException>()),
    );

    final unchanged = await service.getPartById(part.id);

    expect(unchanged!.currentStock, 3);
  });

  test('returns low stock parts', () async {
    await service.createPart(
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
      currentStock: 3,
      lowStockThreshold: 5,
    );

    await service.createPart(
      partNumber: 'OIL-001',
      partName: 'Engine Oil',
      purchasePrice: 300.0,
      sellingPrice: 450.0,
      currentStock: 20,
      lowStockThreshold: 5,
    );

    final lowStockParts = await service.getLowStockParts();

    expect(lowStockParts.length, 1);
    expect(lowStockParts.first.partNumber, 'BRK-001');
  });

  test('updates part without falsely triggering duplicate part number',
      () async {
    final part = await service.createPart(
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
    );

    final updated = part.copyWith(
      partName: 'Premium Brake Pad',
      sellingPrice: 850.0,
    );

    await service.updatePart(updated);

    final result = await service.getPartById(part.id);

    expect(result!.partName, 'Premium Brake Pad');
    expect(result.sellingPrice, 850.0);
    expect(result.partNumber, 'BRK-001');
  });

  test('rejects changing part number to an existing part number',
      () async {
    final first = await service.createPart(
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
    );

    await service.createPart(
      partNumber: 'OIL-001',
      partName: 'Engine Oil',
      purchasePrice: 300.0,
      sellingPrice: 450.0,
    );

    final changed = first.copyWith(
      partNumber: 'OIL-001',
    );

    expect(
      () => service.updatePart(changed),
      throwsA(isA<DuplicatePartNumberException>()),
    );
  });
}