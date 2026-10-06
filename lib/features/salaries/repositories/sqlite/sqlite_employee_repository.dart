import 'package:drift/drift.dart';

import '../../../../database/app_database.dart' as db;
import '../../models/employee.dart';
import '../interfaces/employee_repository.dart';

class SqliteEmployeeRepository implements EmployeeRepository {
  final db.AppDatabase database;

  SqliteEmployeeRepository(this.database);

  @override
  Future<Employee> create(Employee employee) async {
    await database.into(database.employees).insert(
          db.EmployeesCompanion.insert(
            id: employee.id,
            name: employee.name,
            monthlySalary: employee.monthlySalary,
          ),
        );

    return employee;
  }

  @override
  Future<Employee?> getById(String id) async {
    final query = database.select(database.employees)
      ..where((tbl) => tbl.id.equals(id));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toModel(row);
  }

  @override
  Future<List<Employee>> getAll() async {
    final query = database.select(database.employees)
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.name,
              mode: OrderingMode.asc,
            ),
      ]);

    final rows = await query.get();

    return rows.map(_toModel).toList();
  }

  @override
  Future<void> update(Employee employee) async {
    await (database.update(database.employees)
          ..where((tbl) => tbl.id.equals(employee.id)))
        .write(
      db.EmployeesCompanion(
        name: Value(employee.name),
        monthlySalary: Value(employee.monthlySalary),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(database.employees)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Employee _toModel(db.Employee row) {
    return Employee(
      id: row.id,
      name: row.name,
      monthlySalary: row.monthlySalary,
    );
  }
}