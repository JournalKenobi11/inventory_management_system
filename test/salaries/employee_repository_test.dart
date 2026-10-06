
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/database/app_database.dart'
    as db;
import 'package:inventory_management_system/features/salaries/models/employee.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_employee_repository.dart';

void main() {
  late db.AppDatabase database;
  late SqliteEmployeeRepository repository;

  setUp(() {
    database = db.AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    repository = SqliteEmployeeRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and reads an employee', () async {
    const employee = Employee(
      id: 'employee-1',
      name: 'Raj',
      monthlySalary: 25000,
    );

    final created = await repository.create(employee);
    final result = await repository.getById(employee.id);

    expect(created, equals(employee));
    expect(result, equals(employee));
  });

  test('returns employees ordered by name', () async {
    await repository.create(
      const Employee(
        id: 'employee-1',
        name: 'Zack',
        monthlySalary: 25000,
      ),
    );

    await repository.create(
      const Employee(
        id: 'employee-2',
        name: 'Amit',
        monthlySalary: 22000,
      ),
    );

    final result = await repository.getAll();

    expect(
      result.map((employee) => employee.name).toList(),
      equals(['Amit', 'Zack']),
    );
  });

  test('updates an employee', () async {
    await repository.create(
      const Employee(
        id: 'employee-1',
        name: 'Raj',
        monthlySalary: 25000,
      ),
    );

    await repository.update(
      const Employee(
        id: 'employee-1',
        name: 'Raj Updated',
        monthlySalary: 28000,
      ),
    );

    final result = await repository.getById('employee-1');

    expect(result!.name, equals('Raj Updated'));
    expect(result.monthlySalary, equals(28000));
  });

  test('deletes an employee', () async {
    await repository.create(
      const Employee(
        id: 'employee-1',
        name: 'Raj',
        monthlySalary: 25000,
      ),
    );

    await repository.delete('employee-1');

    expect(
      await repository.getById('employee-1'),
      isNull,
    );
  });
}
