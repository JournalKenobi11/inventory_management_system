import 'package:drift/drift.dart';

import '../../../../database/app_database.dart' as db;
import '../../models/salary_payment.dart';
import '../interfaces/salary_payment_repository.dart';

class SqliteSalaryPaymentRepository
    implements SalaryPaymentRepository {
  final db.AppDatabase database;

  SqliteSalaryPaymentRepository(this.database);

  @override
  Future<SalaryPayment> create(SalaryPayment payment) async {
    await database.into(database.salaryPayments).insert(
          db.SalaryPaymentsCompanion.insert(
            id: payment.id,
            employeeId: payment.employeeId,
            amount: payment.amount,
            paymentDate: payment.paymentDate,
            status: payment.status,
          ),
        );

    return payment;
  }

  @override
  Future<SalaryPayment?> getById(String id) async {
    final query = database.select(database.salaryPayments)
      ..where((tbl) => tbl.id.equals(id));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toModel(row);
  }

  @override
  Future<List<SalaryPayment>> getAll() async {
    final query = database.select(database.salaryPayments)
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.paymentDate,
              mode: OrderingMode.desc,
            ),
      ]);

    final rows = await query.get();

    return rows.map(_toModel).toList();
  }

  @override
  Future<List<SalaryPayment>> getByEmployeeId(
    String employeeId,
  ) async {
    final query = database.select(database.salaryPayments)
      ..where(
        (tbl) => tbl.employeeId.equals(employeeId),
      )
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.paymentDate,
              mode: OrderingMode.desc,
            ),
      ]);

    final rows = await query.get();

    return rows.map(_toModel).toList();
  }

  @override
  Future<List<SalaryPayment>> getByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    final query = database.select(database.salaryPayments)
      ..where(
        (tbl) =>
            tbl.paymentDate.isBiggerOrEqualValue(startIso) &
            tbl.paymentDate.isSmallerOrEqualValue(endIso),
      )
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.paymentDate,
              mode: OrderingMode.desc,
            ),
      ]);

    final rows = await query.get();

    return rows.map(_toModel).toList();
  }

  @override
  Future<void> updateStatus({
    required String paymentId,
    required String status,
  }) async {
    await (database.update(database.salaryPayments)
          ..where((tbl) => tbl.id.equals(paymentId)))
        .write(
      db.SalaryPaymentsCompanion(
        status: Value(status),
      ),
    );
  }

  SalaryPayment _toModel(db.SalaryPayment row) {
    return SalaryPayment(
      id: row.id,
      employeeId: row.employeeId,
      amount: row.amount,
      paymentDate: row.paymentDate,
      status: row.status,
    );
  }
}