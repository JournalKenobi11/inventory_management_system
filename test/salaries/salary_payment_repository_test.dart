
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/database/app_database.dart'
    as db;
import 'package:inventory_management_system/features/salaries/models/salary_payment.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_salary_payment_repository.dart';

void main() {
  late db.AppDatabase database;
  late SqliteSalaryPaymentRepository repository;

  setUp(() {
    database = db.AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    repository = SqliteSalaryPaymentRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and reads salary payment', () async {
    const payment = SalaryPayment(
      id: 'payment-1',
      employeeId: 'employee-1',
      amount: 25000,
      paymentDate: '2026-10-01T10:00:00.000',
      status: 'paid',
    );

    final created = await repository.create(payment);
    final result = await repository.getById(payment.id);

    expect(created, equals(payment));
    expect(result, equals(payment));
  });

  test('returns payments for employee', () async {
    await repository.create(
      const SalaryPayment(
        id: 'payment-1',
        employeeId: 'employee-1',
        amount: 25000,
        paymentDate: '2026-10-01T10:00:00.000',
        status: 'paid',
      ),
    );

    await repository.create(
      const SalaryPayment(
        id: 'payment-2',
        employeeId: 'employee-2',
        amount: 20000,
        paymentDate: '2026-10-02T10:00:00.000',
        status: 'paid',
      ),
    );

    final result = await repository.getByEmployeeId(
      'employee-1',
    );

    expect(result, hasLength(1));
    expect(result.first.id, equals('payment-1'));
  });

  test('returns payments by date range', () async {
    await repository.create(
      const SalaryPayment(
        id: 'payment-1',
        employeeId: 'employee-1',
        amount: 25000,
        paymentDate: '2026-10-05T10:00:00.000',
        status: 'paid',
      ),
    );

    await repository.create(
      const SalaryPayment(
        id: 'payment-2',
        employeeId: 'employee-1',
        amount: 5000,
        paymentDate: '2026-10-20T10:00:00.000',
        status: 'paid',
      ),
    );

    final result = await repository.getByDateRange(
      start: DateTime.parse(
        '2026-10-01T00:00:00.000',
      ),
      end: DateTime.parse(
        '2026-10-10T23:59:59.999',
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.id, equals('payment-1'));
  });

  test('updates payment status', () async {
    await repository.create(
      const SalaryPayment(
        id: 'payment-1',
        employeeId: 'employee-1',
        amount: 5000,
        paymentDate: '2026-10-05T10:00:00.000',
        status: 'pending',
      ),
    );

    await repository.updateStatus(
      paymentId: 'payment-1',
      status: 'paid',
    );

    final result = await repository.getById('payment-1');

    expect(result!.status, equals('paid'));
  });
}
