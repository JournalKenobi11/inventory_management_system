import '../models/expense.dart';
import '../repositories/interfaces/expense_repository.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/id_generator.dart';

class ExpenseService {
  final ExpenseRepository repository;

  ExpenseService(this.repository);

  Future<Expense> createExpense({
    required String category,
    required bool isPersonal,
    required double amount,
    String? note,
  }) async {
    final trimmedCategory = category.trim();

    if (trimmedCategory.isEmpty) {
      throw ValidationException(
        'Expense category cannot be empty',
      );
    }

    if (amount <= 0) {
      throw ValidationException(
        'Expense amount must be greater than 0',
      );
    }

    final trimmedNote = note?.trim();

    final expense = Expense(
      id: IdGenerator.generate(),
      category: trimmedCategory,
      isPersonal: isPersonal,
      amount: amount,
      note: trimmedNote == null || trimmedNote.isEmpty
          ? null
          : trimmedNote,
      entryDate: DateTime.now().toIso8601String(),
    );

    await repository.create(expense);

    return expense;
  }

  Future<List<Expense>> getAllExpenses() {
    return repository.getAll();
  }

  Future<List<Expense>> getExpensesByDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    if (start.isAfter(end)) {
      throw ValidationException(
        'Start date cannot be after end date',
      );
    }

    return repository.getByDateRange(
      start: start,
      end: end,
    );
  }

  Future<List<Expense>> getExpensesByCategory(
    String category,
  ) {
    final trimmedCategory = category.trim();

    if (trimmedCategory.isEmpty) {
      throw ValidationException(
        'Expense category cannot be empty',
      );
    }

    return repository.getByCategory(trimmedCategory);
  }
}