

import '../../../../database/app_database.dart' as db;
import '../../models/service_part.dart';
import '../interfaces/service_part_repository.dart';

class SqliteServicePartRepository
    implements ServicePartRepository {
  final db.AppDatabase database;

  SqliteServicePartRepository(this.database);

  @override
  Future<ServicePart> create(
    ServicePart servicePart,
  ) async {
    await database.into(database.serviceParts).insert(
          db.ServicePartsCompanion.insert(
            id: servicePart.id,
            serviceId: servicePart.serviceId,
            partId: servicePart.partId,
            quantity: servicePart.quantity,
            priceEach: servicePart.priceEach,
          ),
        );

    return servicePart;
  }

  @override
  Future<List<ServicePart>> getByServiceId(
    String serviceId,
  ) async {
    final query = database.select(database.serviceParts)
      ..where(
        (tbl) => tbl.serviceId.equals(serviceId),
      );

    final rows = await query.get();

    return rows.map(_toModel).toList();
  }

  ServicePart _toModel(db.ServicePart row) {
    return ServicePart(
      id: row.id,
      serviceId: row.serviceId,
      partId: row.partId,
      quantity: row.quantity,
      priceEach: row.priceEach,
    );
  }
}