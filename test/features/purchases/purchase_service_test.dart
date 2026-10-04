import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/parts/repositories/sqlite/sqlite_part_repository.dart';
import 'package:inventory_management_system/features/parts/services/part_service.dart';
import 'package:inventory_management_system/features/purchases/repositories/sqlite/sqlite_purchase_repository.dart';
import 'package:inventory_management_system/features/purchases/services/purchase_service.dart';

void main() {
  late AppDatabase database;
  late SqlitePartRepository partRepository;
  late PartService partService;
  late SqlitePurchaseRepository purchaseRepository;
  late PurchaseService purchaseService;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    partRepository = SqlitePartRepository(database);
    partService = PartService(partRepository);

    purchaseRepository = SqlitePurchaseRepository(database);

    purchaseService = PurchaseService(
      purchaseRepository,
      partService,
      database,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('records purchase and increases stock', () async {
    final part = await partService.createPart(
      partNumber: 'BRK-001',
      partName: 'Brake Pad',
      purchasePrice: 500.0,
      sellingPrice: 750.0,
      currentStock: 10,
      lowStockThreshold: 5,
    );

    final purchase = await purchaseService.recordPurchase(
      partId: part.id,
      quantity: 5,
      price: 480.0,
    );

    expect(purchase.partId, equals(part.id));
    expect(purchase.quantity, equals(5));
    expect(purchase.purchasePrice, equals(480.0));

    final updatedPart = await partService.getPartById(part.id);

    expect(updatedPart, isNotNull);
    expect(updatedPart!.currentStock, equals(15));

    final purchases =
        await purchaseService.getPurchasesByPartId(part.id);

    expect(purchases, hasLength(1));
    expect(purchases.first.quantity, equals(5));
  });

  test('rejects zero quantity', () async {
    final part = await partService.createPart(
      partNumber: 'OIL-001',
      partName: 'Engine Oil',
      purchasePrice: 300.0,
      sellingPrice: 450.0,
    );

    expect(
      () => purchaseService.recordPurchase(
        partId: part.id,
        quantity: 0,
        price: 300.0,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('rejects negative quantity', () async {
    final part = await partService.createPart(
      partNumber: 'FLT-001',
      partName: 'Air Filter',
      purchasePrice: 200.0,
      sellingPrice: 350.0,
    );

    expect(
      () => purchaseService.recordPurchase(
        partId: part.id,
        quantity: -1,
        price: 200.0,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('rejects negative purchase price', () async {
    final part = await partService.createPart(
      partNumber: 'SPK-001',
      partName: 'Spark Plug',
      purchasePrice: 100.0,
      sellingPrice: 180.0,
    );

    expect(
      () => purchaseService.recordPurchase(
        partId: part.id,
        quantity: 2,
        price: -100.0,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('rejects purchase for a non-existent part', () async {
    expect(
      () => purchaseService.recordPurchase(
        partId: 'non-existent-part',
        quantity: 2,
        price: 100.0,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('records purchase and updates stock consistently', () async {
    final part = await partService.createPart(
      partNumber: 'BAT-001',
      partName: 'Battery',
      purchasePrice: 2500.0,
      sellingPrice: 3200.0,
      currentStock: 2,
    );

    final purchase = await purchaseService.recordPurchase(
      partId: part.id,
      quantity: 3,
      price: 2400.0,
    );

    final updatedPart = await partService.getPartById(part.id);
    final purchases =
        await purchaseService.getPurchasesByPartId(part.id);

    expect(purchase.id, isNotEmpty);
    expect(updatedPart!.currentStock, equals(5));
    expect(purchases, hasLength(1));
  });
}