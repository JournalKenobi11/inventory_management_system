import 'package:drift/drift.dart';

import '../../../../database/app_database.dart' as db;
import '../../models/service.dart';
import '../interfaces/service_repository.dart';

class SqliteServiceRepository implements ServiceRepository {
  final db.AppDatabase database;

  SqliteServiceRepository(this.database);

  @override
  Future<Service> create(Service service) async {
    await database.into(database.serviceJobs).insert(
          db.ServiceJobsCompanion.insert(
            id: service.id,
            customerId: service.customerId,
            problemDesc: service.problemDesc == null
                ? const Value.absent()
                : Value(service.problemDesc!),
            labourCharge: Value(service.labourCharge),
            serviceDate: service.serviceDate,
            invoiceId: service.invoiceId == null
                ? const Value.absent()
                : Value(service.invoiceId!),
          ),
        );

    return service;
  }

  @override
  Future<Service?> getById(String id) async {
    final query = database.select(database.serviceJobs)
      ..where(
        (tbl) => tbl.id.equals(id),
      );

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toModel(row);
  }

  @override
  Future<List<Service>> getAll() async {
    final query = database.select(database.serviceJobs)
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.serviceDate,
              mode: OrderingMode.desc,
            ),
      ]);

    final rows = await query.get();

    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Service>> getByCustomerId(
    String customerId,
  ) async {
    final query = database.select(database.serviceJobs)
      ..where(
        (tbl) => tbl.customerId.equals(customerId),
      )
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.serviceDate,
              mode: OrderingMode.desc,
            ),
      ]);

    final rows = await query.get();

    return rows.map(_toModel).toList();
  }

  @override
  Future<void> linkInvoice(
    String serviceId,
    String invoiceId,
  ) async {
    await (database.update(database.serviceJobs)
          ..where(
            (tbl) => tbl.id.equals(serviceId),
          ))
        .write(
      db.ServiceJobsCompanion(
        invoiceId: Value(invoiceId),
      ),
    );
  }

  Service _toModel(db.ServiceJob row) {
    return Service(
      id: row.id,
      customerId: row.customerId,
      problemDesc: row.problemDesc,
      labourCharge: row.labourCharge,
      serviceDate: row.serviceDate,
      invoiceId: row.invoiceId,
    );
  }
}