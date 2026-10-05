import '../../models/expense.dart';

abstract class ExpenseRepository {
  Future<void> create(Expense expense);

  Future<List<Expense>> getAll();

  Future<List<Expense>> getByDateRange({
    required DateTime start,
    required DateTime end,
  });

  Future<List<Expense>> getByCategory(String category);
}