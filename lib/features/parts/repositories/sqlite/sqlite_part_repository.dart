import 'package:drift/drift.dart';

import '../../../../database/app_database.dart' as db;
import '../../models/part.dart';
import '../interfaces/part_repository.dart';

class SqlitePartRepository implements PartRepository {
  final db.AppDatabase database;

  SqlitePartRepository(this.database);

  @override
  Future<Part> create(Part part) async {
    await database.into(database.parts).insert(
          db.PartsCompanion.insert(
            id: part.id,
            partNumber: part.partNumber,
            partName: part.partName,
            category: part.category == null
                ? const Value.absent()
                : Value(part.category!),
            purchasePrice: part.purchasePrice,
            sellingPrice: part.sellingPrice,
            currentStock: Value(part.currentStock),
            lowStockThreshold: Value(part.lowStockThreshold),
          ),
        );

    return part;
  }

  @override
  Future<Part?> getById(String id) async {
    final query = database.select(database.parts)
      ..where((tbl) => tbl.id.equals(id));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toModel(row);
  }

  @override
  Future<Part?> getByPartNumber(String partNumber) async {
    final query = database.select(database.parts)
      ..where((tbl) => tbl.partNumber.equals(partNumber));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toModel(row);
  }

  @override
  Future<List<Part>> getAll() async {
    final rows = await database.select(database.parts).get();

    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Part>> getLowStock() async {
    final query = database.select(database.parts)
      ..where(
        (tbl) => tbl.currentStock.isSmallerOrEqual(tbl.lowStockThreshold),
      );

    final rows = await query.get();

    return rows.map(_toModel).toList();
  }

  @override
  Future<void> update(Part part) async {
    await (database.update(database.parts)
          ..where((tbl) => tbl.id.equals(part.id)))
        .write(
      db.PartsCompanion(
        partNumber: Value(part.partNumber),
        partName: Value(part.partName),
        category: part.category == null
            ? const Value.absent()
            : Value(part.category!),
        purchasePrice: Value(part.purchasePrice),
        sellingPrice: Value(part.sellingPrice),
        currentStock: Value(part.currentStock),
        lowStockThreshold: Value(part.lowStockThreshold),
      ),
    );
  }

  @override
  Future<void> adjustStock(String partId, int delta) async {
    final part = await getById(partId);

    if (part == null) {
      throw StateError('Part not found: $partId');
    }

    final newStock = part.currentStock + delta;

    await (database.update(database.parts)
          ..where((tbl) => tbl.id.equals(partId)))
        .write(
      db.PartsCompanion(
        currentStock: Value(newStock),
      ),
    );
  }

  Part _toModel(db.Part row) {
    return Part(
      id: row.id,
      partNumber: row.partNumber,
      partName: row.partName,
      category: row.category,
      purchasePrice: row.purchasePrice,
      sellingPrice: row.sellingPrice,
      currentStock: row.currentStock,
      lowStockThreshold: row.lowStockThreshold,
    );
  }
}