import 'package:drift/drift.dart' hide TableInfo;
import 'package:uuid/uuid.dart';

import '../../../../database/app_database.dart' hide Purchase;
import '../../models/purchase.dart';
import '../interfaces/purchase_repository.dart';

class SqlitePurchaseRepository implements PurchaseRepository {
  final AppDatabase database;
  final Uuid _uuid;

  SqlitePurchaseRepository(
    this.database, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<Purchase> create(Purchase purchase) async {
    final id = purchase.id.isEmpty ? _uuid.v4() : purchase.id;

    final purchaseToCreate = purchase.copyWith(id: id);

    await database.customStatement(
      '''
      INSERT INTO Purchases (
        id,
        part_id,
        quantity,
        purchase_price,
        purchase_date
      )
      VALUES (?, ?, ?, ?, ?)
      ''',
      [
        purchaseToCreate.id,
        purchaseToCreate.partId,
        purchaseToCreate.quantity,
        purchaseToCreate.purchasePrice,
        purchaseToCreate.purchaseDate,
      ],
    );

    return purchaseToCreate;
  }

  @override
  Future<List<Purchase>> getByPartId(String partId) async {
    final rows = await database.customSelect(
      '''
      SELECT
        id,
        part_id,
        quantity,
        purchase_price,
        purchase_date
      FROM Purchases
      WHERE part_id = ?
      ORDER BY purchase_date DESC
      ''',
      variables: [
        Variable.withString(partId),
      ],
    ).get();

    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<Purchase>> getAll() async {
    final rows = await database.customSelect(
      '''
      SELECT
        id,
        part_id,
        quantity,
        purchase_price,
        purchase_date
      FROM Purchases
      ORDER BY purchase_date DESC
      ''',
    ).get();

    return rows.map(_mapRow).toList();
  }

  Purchase _mapRow(QueryRow row) {
    return Purchase(
      id: row.read<String>('id'),
      partId: row.read<String>('part_id'),
      quantity: row.read<int>('quantity'),
      purchasePrice: row.read<double>('purchase_price'),
      purchaseDate: row.read<String>('purchase_date'),
    );
  }
}