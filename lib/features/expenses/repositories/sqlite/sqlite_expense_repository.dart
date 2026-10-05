
import 'package:drift/drift.dart';

import '../../../../database/app_database.dart' as db;
import '../../models/expense.dart';
import '../interfaces/expense_repository.dart';

class SqliteExpenseRepository implements ExpenseRepository {
  final db.AppDatabase database;

  SqliteExpenseRepository(this.database);

  @override
  Future<Expense> create(Expense expense) async {
    await database.into(database.expenses).insert(
          db.ExpensesCompanion.insert(
            id: expense.id,
            category: expense.category,
            isPersonal: Value(expense.isPersonal),
            amount: expense.amount,
            note: expense.note == null
                ? const Value.absent()
                : Value(expense.note!),
            entryDate: expense.entryDate,
          ),
        );

    return expense;
  }

  @override
  Future<List<Expense>> getAll() async {
    final rows = await (database.select(database.expenses)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.entryDate,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();

    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Expense>> getByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    final rows = await (database.select(database.expenses)
          ..where(
            (tbl) =>
                tbl.entryDate.isBiggerOrEqualValue(startIso) &
                tbl.entryDate.isSmallerOrEqualValue(endIso),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.entryDate,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();

    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Expense>> getByCategory(String category) async {
    final rows = await (database.select(database.expenses)
          ..where((tbl) => tbl.category.equals(category))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.entryDate,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();

    return rows.map(_toModel).toList();
  }

  Expense _toModel(db.Expense row) {
    return Expense(
      id: row.id,
      category: row.category,
      isPersonal: row.isPersonal,
      amount: row.amount,
      note: row.note,
      entryDate: row.entryDate,
    );
  }
}
