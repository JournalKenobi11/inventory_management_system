import 'package:drift/drift.dart';

import '../../../../database/app_database.dart' as db;
import '../../models/personal_finance_transaction.dart';
import '../interfaces/personal_finance_transaction_repository.dart';

class SqlitePersonalFinanceTransactionRepository
    implements PersonalFinanceTransactionRepository {
  final db.AppDatabase database;

  SqlitePersonalFinanceTransactionRepository(this.database);

  @override
  Future<PersonalFinanceTransaction> create(
    PersonalFinanceTransaction transaction,
  ) async {
    await database
        .into(database.personalFinanceTransactions)
        .insert(
          db.PersonalFinanceTransactionsCompanion.insert(
            id: transaction.id,
            accountId: transaction.accountId,
            type: transaction.type,
            amount: transaction.amount,
            category: transaction.category,
            payee: Value(transaction.payee),
            note: Value(transaction.note),
            transactionDate: transaction.transactionDate,
          ),
        );
    return transaction;
  }

  @override
  Future<PersonalFinanceTransaction?> getById(String id) async {
    final query = database.select(database.personalFinanceTransactions)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<List<PersonalFinanceTransaction>> getAll() async {
    final query = database.select(database.personalFinanceTransactions)
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.transactionDate,
          mode: OrderingMode.desc,
        ),
      ]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<PersonalFinanceTransaction>> getForAccount(
    String accountId,
  ) async {
    final query = database.select(database.personalFinanceTransactions)
      ..where((tbl) => tbl.accountId.equals(accountId))
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.transactionDate,
          mode: OrderingMode.desc,
        ),
      ]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<PersonalFinanceTransaction>> getByDateRange({
    required String accountId,
    required DateTime start,
    required DateTime end,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    final query = database.select(database.personalFinanceTransactions)
      ..where(
        (tbl) =>
            tbl.accountId.equals(accountId) &
            tbl.transactionDate.isBiggerOrEqualValue(startIso) &
            tbl.transactionDate.isSmallerOrEqualValue(endIso),
      )
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.transactionDate,
          mode: OrderingMode.desc,
        ),
      ]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<PersonalFinanceTransaction>> getByType({
    required String accountId,
    required String type,
  }) async {
    final query = database.select(database.personalFinanceTransactions)
      ..where(
        (tbl) =>
            tbl.accountId.equals(accountId) &
            tbl.type.equals(type.toLowerCase()),
      )
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.transactionDate,
          mode: OrderingMode.desc,
        ),
      ]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<PersonalFinanceTransaction>> getByCategory({
    required String accountId,
    required String category,
  }) async {
    final query = database.select(database.personalFinanceTransactions)
      ..where(
        (tbl) =>
            tbl.accountId.equals(accountId) & tbl.category.equals(category),
      )
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.transactionDate,
          mode: OrderingMode.desc,
        ),
      ]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<double> getTotalCredits({
    required String accountId,
    DateTime? start,
    DateTime? end,
  }) async {
    return _sumByType(
      accountId: accountId,
      type: 'credit',
      start: start,
      end: end,
    );
  }

  @override
  Future<double> getTotalDebits({
    required String accountId,
    DateTime? start,
    DateTime? end,
  }) async {
    return _sumByType(
      accountId: accountId,
      type: 'debit',
      start: start,
      end: end,
    );
  }

  Future<double> _sumByType({
    required String accountId,
    required String type,
    DateTime? start,
    DateTime? end,
  }) async {
    final amountSum = database.personalFinanceTransactions.amount.sum();
    final query = database.selectOnly(database.personalFinanceTransactions)
      ..addColumns([amountSum]);

    Expression<bool> predicate =
        database.personalFinanceTransactions.accountId.equals(accountId) &
        database.personalFinanceTransactions.type.equals(type);

    if (start != null) {
      predicate =
          predicate &
          database.personalFinanceTransactions.transactionDate
              .isBiggerOrEqualValue(start.toIso8601String());
    }
    if (end != null) {
      predicate =
          predicate &
          database.personalFinanceTransactions.transactionDate
              .isSmallerOrEqualValue(end.toIso8601String());
    }

    query.where(predicate);
    final row = await query.getSingle();
    return row.read(amountSum) ?? 0.0;
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(
      database.personalFinanceTransactions,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  PersonalFinanceTransaction _toModel(db.PersonalFinanceTransaction row) {
    return PersonalFinanceTransaction(
      id: row.id,
      accountId: row.accountId,
      type: row.type,
      amount: row.amount,
      category: row.category,
      payee: row.payee,
      note: row.note,
      transactionDate: row.transactionDate,
    );
  }
}
