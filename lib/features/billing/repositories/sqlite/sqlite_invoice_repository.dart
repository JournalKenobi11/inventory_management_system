import 'package:drift/drift.dart';

import '../../../../database/app_database.dart' as db;
import '../../models/invoice.dart';
import '../interfaces/invoice_repository.dart';

class SqliteInvoiceRepository
    implements InvoiceRepository {
  final db.AppDatabase database;

  SqliteInvoiceRepository(this.database);

  @override
  Future<Invoice> create(Invoice invoice) async {
    await database.into(database.invoices).insert(
          db.InvoicesCompanion.insert(
            id: invoice.id,
            invoiceNumber: invoice.invoiceNumber,
            serviceId: invoice.serviceId,
            totalAmount: invoice.totalAmount,
            createdDate: invoice.createdDate,
          ),
        );

    return invoice;
  }

  @override
  Future<Invoice?> getById(String id) async {
    final query = database.select(database.invoices)
      ..where((tbl) => tbl.id.equals(id));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toModel(row);
  }

  @override
  Future<Invoice?> getByInvoiceNumber(
    int invoiceNumber,
  ) async {
    final query = database.select(database.invoices)
      ..where(
        (tbl) => tbl.invoiceNumber.equals(invoiceNumber),
      );

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toModel(row);
  }

  @override
  Future<List<Invoice>> getAll() async {
    final query = database.select(database.invoices)
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.createdDate,
              mode: OrderingMode.desc,
            ),
      ]);

    final rows = await query.get();

    return rows.map(_toModel).toList();
  }

  @override
  Future<int> nextInvoiceNumber() async {
    final query = database.select(database.counters)
      ..where(
        (tbl) => tbl.name.equals('invoice_number'),
      );

    final row = await query.getSingleOrNull();

    if (row == null) {
      await database.into(database.counters).insert(
            db.CountersCompanion.insert(
              name: 'invoice_number',
              value: const Value(1),
            ),
          );

      return 1;
    }

    final nextNumber = row.value + 1;

    await (database.update(database.counters)
          ..where(
            (tbl) => tbl.name.equals('invoice_number'),
          ))
        .write(
      db.CountersCompanion(
        value: Value(nextNumber),
      ),
    );

    return nextNumber;
  }

  Invoice _toModel(db.Invoice row) {
    return Invoice(
      id: row.id,
      invoiceNumber: row.invoiceNumber,
      serviceId: row.serviceId,
      totalAmount: row.totalAmount,
      createdDate: row.createdDate,
    );
  }
}