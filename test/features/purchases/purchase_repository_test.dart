import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/database/app_database.dart'
    hide Purchase;
import 'package:inventory_management_system/features/purchases/models/purchase.dart';
import 'package:inventory_management_system/features/purchases/repositories/sqlite/sqlite_purchase_repository.dart';

void main() {
  late AppDatabase database;
  late SqlitePurchaseRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    repository = SqlitePurchaseRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and retrieves a purchase by part ID', () async {
    const partId = 'part-001';

    final purchase = Purchase(
      id: 'purchase-001',
      partId: partId,
      quantity: 5,
      purchasePrice: 100.0,
      purchaseDate: '2026-10-04T10:00:00.000Z',
    );

    final created = await repository.create(purchase);

    expect(created, equals(purchase));

    final purchases = await repository.getByPartId(partId);

    expect(purchases, hasLength(1));
    expect(purchases.first.id, equals('purchase-001'));
    expect(purchases.first.partId, equals(partId));
    expect(purchases.first.quantity, equals(5));
    expect(purchases.first.purchasePrice, equals(100.0));
    expect(
      purchases.first.purchaseDate,
      equals('2026-10-04T10:00:00.000Z'),
    );
  });

  test('getAll returns all purchases', () async {
    final purchase1 = Purchase(
      id: 'purchase-001',
      partId: 'part-001',
      quantity: 5,
      purchasePrice: 100.0,
      purchaseDate: '2026-10-04T10:00:00.000Z',
    );

    final purchase2 = Purchase(
      id: 'purchase-002',
      partId: 'part-002',
      quantity: 3,
      purchasePrice: 250.0,
      purchaseDate: '2026-10-04T11:00:00.000Z',
    );

    await repository.create(purchase1);
    await repository.create(purchase2);

    final purchases = await repository.getAll();

    expect(purchases, hasLength(2));
    expect(
      purchases.map((purchase) => purchase.id),
      containsAll(<String>[
        'purchase-001',
        'purchase-002',
      ]),
    );
  });

  test(
    'getByPartId returns an empty list when no purchases exist',
    () async {
      final purchases =
          await repository.getByPartId('part-does-not-exist');

      expect(purchases, isEmpty);
    },
  );
}