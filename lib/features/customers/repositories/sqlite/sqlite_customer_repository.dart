// lib/features/customers/repositories/sqlite/sqlite_customer_repository.dart

import 'package:drift/drift.dart';

import '../../../../database/app_database.dart' as db;
import '../../models/customer.dart';
import '../interfaces/customer_repository.dart';

class SqliteCustomerRepository implements CustomerRepository {
  final db.AppDatabase database;

  SqliteCustomerRepository(this.database);

  @override
  Future<Customer> create(Customer customer) async {
    await database.into(database.customers).insert(
          db.CustomersCompanion.insert(
            id: customer.id,
            name: customer.name,
            mobile: customer.mobile,
            vehicleName: customer.vehicleName == null
                ? const Value.absent()
                : Value(customer.vehicleName!),
            createdDate: customer.createdDate,
          ),
        );

    return customer;
  }

  @override
  Future<Customer?> getById(String id) async {
    final query = database.select(database.customers)
      ..where((tbl) => tbl.id.equals(id));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return Customer(
      id: row.id,
      name: row.name,
      mobile: row.mobile,
      vehicleName: row.vehicleName,
      createdDate: row.createdDate,
    );
  }

  @override
  Future<List<Customer>> getAll() async {
    final rows = await database.select(database.customers).get();

    return rows
        .map(
          (row) => Customer(
            id: row.id,
            name: row.name,
            mobile: row.mobile,
            vehicleName: row.vehicleName,
            createdDate: row.createdDate,
          ),
        )
        .toList();
  }

  @override
  Future<List<Customer>> search(String query) async {
    final rows = await (database.select(database.customers)
          ..where(
            (tbl) =>
                tbl.name.like('%$query%') |
                tbl.mobile.like('%$query%'),
          ))
        .get();

    return rows
        .map(
          (row) => Customer(
            id: row.id,
            name: row.name,
            mobile: row.mobile,
            vehicleName: row.vehicleName,
            createdDate: row.createdDate,
          ),
        )
        .toList();
  }

  @override
  Future<void> update(Customer customer) async {
    await (database.update(database.customers)
          ..where((tbl) => tbl.id.equals(customer.id)))
        .write(
      db.CustomersCompanion(
        name: Value(customer.name),
        mobile: Value(customer.mobile),
        vehicleName: customer.vehicleName == null
            ? const Value.absent()
            : Value(customer.vehicleName!),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(database.customers)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}