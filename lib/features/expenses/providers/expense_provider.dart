import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../models/expense.dart';
import '../repositories/interfaces/expense_repository.dart';
import '../repositories/sqlite/sqlite_expense_repository.dart';
import '../services/expense_service.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return SqliteExpenseRepository(
    ref.read(appDatabaseProvider),
  );
});

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService(
    ref.read(expenseRepositoryProvider),
  );
});

final expensesProvider =
    AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  ExpenseService get service => ref.read(expenseServiceProvider);

  @override
  Future<List<Expense>> build() {
    return service.getAllExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => service.getAllExpenses(),
    );
  }

  Future<void> addExpense({
    required String category,
    required bool isPersonal,
    required double amount,
    String? note,
  }) async {
    state = await AsyncValue.guard(() async {
      await service.createExpense(
        category: category,
        isPersonal: isPersonal,
        amount: amount,
        note: note,
      );

      return service.getAllExpenses();
    });
  }

  Future<void> loadByType(bool isPersonal) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final expenses = await service.getAllExpenses();

      return expenses
          .where(
            (expense) => expense.isPersonal == isPersonal,
          )
          .toList();
    });
  }

  Future<void> loadByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    state = await AsyncValue.guard(
      () => service.getExpensesByDateRange(
        start: start,
        end: end,
      ),
    );
  }

  Future<void> loadByCategory(String category) async {
    state = await AsyncValue.guard(
      () => service.getExpensesByCategory(category),
    );
  }
}