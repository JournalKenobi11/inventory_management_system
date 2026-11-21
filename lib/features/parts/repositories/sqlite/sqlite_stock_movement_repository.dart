import 'package:drift/drift.dart' as drift;

import '../../../../database/app_database.dart' as db;
import '../../models/stock_movement.dart';
import '../interfaces/stock_movement_repository.dart';

class SqliteStockMovementRepository implements StockMovementRepository {
  final db.AppDatabase database;

  SqliteStockMovementRepository(this.database);

  @override
  Future<StockMovement> create(StockMovement movement) async {
    await database.into(database.stockMovements).insert(
          db.StockMovementsCompanion.insert(
            id: movement.id,
            partId: movement.partId,
            quantityChange: movement.quantityChange,
            balanceAfter: movement.balanceAfter,
            movementType: movement.movementType,
            referenceId: drift.Value(movement.referenceId),
            notes: drift.Value(movement.notes),
            createdDate: movement.createdDate,
          ),
        );
    return movement;
  }

  @override
  Future<List<StockMovement>> getByPartId(String partId) async {
    final query = database.select(database.stockMovements)
      ..where((tbl) => tbl.partId.equals(partId))
      ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.createdDate)]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<StockMovement>> getAll() async {
    final query = database.select(database.stockMovements)
      ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.createdDate)]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  StockMovement _toModel(db.StockMovement row) {
    return StockMovement(
      id: row.id,
      partId: row.partId,
      quantityChange: row.quantityChange,
      balanceAfter: row.balanceAfter,
      movementType: row.movementType,
      referenceId: row.referenceId,
      notes: row.notes,
      createdDate: row.createdDate,
    );
  }
}
