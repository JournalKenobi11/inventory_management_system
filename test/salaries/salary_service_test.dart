import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/core/errors/app_exceptions.dart';
import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_employee_repository.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_salary_payment_repository.dart';
import 'package:inventory_management_system/features/salaries/services/salary_service.dart';

void main() {
  late AppDatabase database;
  late SqliteEmployeeRepository employeeRepository;
  late SqliteSalaryPaymentRepository paymentRepository;
  late SalaryService service;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    employeeRepository =
        SqliteEmployeeRepository(database);

    paymentRepository =
        SqliteSalaryPaymentRepository(database);

    service = SalaryService(
      employeeRepository,
      paymentRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('creates employee', () async {
    final employee =
        await service.createEmployee(
      name: 'Raj',
      monthlySalary: 25000,
    );

    expect(employee.name, equals('Raj'));
    expect(employee.monthlySalary, equals(25000));
    expect(employee.id, isNotEmpty);
  });

  test('rejects empty employee name', () async {
    expect(
      () => service.createEmployee(
        name: '   ',
        monthlySalary: 25000,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects zero salary', () async {
    expect(
      () => service.createEmployee(
        name: 'Raj',
        monthlySalary: 0,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects negative salary', () async {
    expect(
      () => service.createEmployee(
        name: 'Raj',
        monthlySalary: -100,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('records paid salary payment', () async {
    final employee =
        await service.createEmployee(
      name: 'Raj',
      monthlySalary: 25000,
    );

    final payment =
        await service.recordPayment(
      employeeId: employee.id,
      amount: 10000,
      status: 'paid',
    );

    expect(payment.employeeId, equals(employee.id));
    expect(payment.amount, equals(10000));
    expect(payment.status, equals('paid'));
    expect(
      DateTime.tryParse(payment.paymentDate),
      isNotNull,
    );
  });

  test('records pending salary payment', () async {
    final employee =
        await service.createEmployee(
      name: 'Raj',
      monthlySalary: 25000,
    );

    final payment =
        await service.recordPayment(
      employeeId: employee.id,
      amount: 15000,
      status: 'pending',
    );

    expect(payment.status, equals('pending'));
  });

  test('rejects unknown employee payment', () async {
    expect(
      () => service.recordPayment(
        employeeId: 'missing',
        amount: 10000,
      ),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('rejects invalid payment amount', () async {
    final employee =
        await service.createEmployee(
      name: 'Raj',
      monthlySalary: 25000,
    );

    expect(
      () => service.recordPayment(
        employeeId: employee.id,
        amount: 0,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects invalid payment status', () async {
    final employee =
        await service.createEmployee(
      name: 'Raj',
      monthlySalary: 25000,
    );

    expect(
      () => service.recordPayment(
        employeeId: employee.id,
        amount: 10000,
        status: 'unknown',
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('marks pending payment as paid', () async {
    final employee =
        await service.createEmployee(
      name: 'Raj',
      monthlySalary: 25000,
    );

    final payment =
        await service.recordPayment(
      employeeId: employee.id,
      amount: 10000,
      status: 'pending',
    );

    await service.markPaymentStatus(
      paymentId: payment.id,
      status: 'paid',
    );

    final updated =
        await paymentRepository.getById(payment.id);

    expect(updated!.status, equals('paid'));
  });

  test('calculates amount owed this month', () async {
    final employee =
        await service.createEmployee(
      name: 'Raj',
      monthlySalary: 25000,
    );

    await service.recordPayment(
      employeeId: employee.id,
      amount: 10000,
      status: 'paid',
    );

    final owed =
        await service.getTotalOwedThisMonth(
      employee.id,
    );

    expect(owed, equals(15000));
  });

  test('pending payment does not reduce amount owed', () async {
    final employee =
        await service.createEmployee(
      name: 'Raj',
      monthlySalary: 25000,
    );

    await service.recordPayment(
      employeeId: employee.id,
      amount: 10000,
      status: 'pending',
    );

    final owed =
        await service.getTotalOwedThisMonth(
      employee.id,
    );

    expect(owed, equals(25000));
  });

  test('owed amount never becomes negative', () async {
    final employee =
        await service.createEmployee(
      name: 'Raj',
      monthlySalary: 25000,
    );

    await service.recordPayment(
      employeeId: employee.id,
      amount: 30000,
      status: 'paid',
    );

    final owed =
        await service.getTotalOwedThisMonth(
      employee.id,
    );

    expect(owed, equals(0));
  });

  test('employee with existing salary payments cannot be deleted',
      () async {
    final employee =
        await service.createEmployee(
      name: 'Raj',
      monthlySalary: 25000,
    );

    await service.recordPayment(
      employeeId: employee.id,
      amount: 10000,
    );

    expect(
      () => service.deleteEmployee(employee.id),
      throwsA(isA<ValidationException>()),
    );
  });
}