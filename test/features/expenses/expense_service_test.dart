import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/core/errors/app_exceptions.dart';
import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/expenses/repositories/sqlite/sqlite_expense_repository.dart';
import 'package:inventory_management_system/features/expenses/services/expense_service.dart';

void main() {
  late AppDatabase database;
  late SqliteExpenseRepository repository;
  late ExpenseService service;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    repository = SqliteExpenseRepository(database);
    service = ExpenseService(repository);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'creates a business expense with automatic entry date',
    () async {
      final before = DateTime.now();

      final expense = await service.createExpense(
        category: 'Fuel',
        isPersonal: false,
        amount: 500.0,
        note: 'Petrol',
      );

      final after = DateTime.now();
      final entryDate = DateTime.parse(expense.entryDate);

      expect(expense.category, equals('Fuel'));
      expect(expense.isPersonal, isFalse);
      expect(expense.amount, equals(500.0));
      expect(expense.note, equals('Petrol'));

      expect(
        entryDate.isAfter(before) ||
            entryDate.isAtSameMomentAs(before),
        isTrue,
      );

      expect(
        entryDate.isBefore(after) ||
            entryDate.isAtSameMomentAs(after),
        isTrue,
      );
    },
  );

  test(
    'creates a personal expense separately',
    () async {
      final expense = await service.createExpense(
        category: 'Miscellaneous',
        isPersonal: true,
        amount: 250.0,
      );

      expect(expense.isPersonal, isTrue);
    },
  );

  test('rejects empty category', () async {
    expect(
      () => service.createExpense(
        category: '   ',
        isPersonal: false,
        amount: 100.0,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects zero amount', () async {
    expect(
      () => service.createExpense(
        category: 'Fuel',
        isPersonal: false,
        amount: 0.0,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects negative amount', () async {
    expect(
      () => service.createExpense(
        category: 'Fuel',
        isPersonal: false,
        amount: -1.0,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('returns expenses by category', () async {
    await service.createExpense(
      category: 'Fuel',
      isPersonal: false,
      amount: 500.0,
    );

    await service.createExpense(
      category: 'Rent',
      isPersonal: false,
      amount: 5000.0,
    );

    await service.createExpense(
      category: 'Fuel',
      isPersonal: true,
      amount: 200.0,
    );

    final fuelExpenses =
        await service.getExpensesByCategory('Fuel');

    expect(fuelExpenses, hasLength(2));

    expect(
      fuelExpenses.every(
        (expense) => expense.category == 'Fuel',
      ),
      isTrue,
    );
  });

  test('returns expenses by date range', () async {
    final expense1 = await service.createExpense(
      category: 'Fuel',
      isPersonal: false,
      amount: 500.0,
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 5),
    );

    final expense2 = await service.createExpense(
      category: 'Tools',
      isPersonal: false,
      amount: 1000.0,
    );

    final firstDate =
        DateTime.parse(expense1.entryDate);
    final secondDate =
        DateTime.parse(expense2.entryDate);

    final result =
        await service.getExpensesByDateRange(
      start: firstDate.subtract(
        const Duration(seconds: 1),
      ),
      end: secondDate.subtract(
        const Duration(microseconds: 1),
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.id, equals(expense1.id));

    expect(
      result.any(
        (expense) => expense.id == expense2.id,
      ),
      isFalse,
    );

    expect(
      secondDate.isAfter(firstDate),
      isTrue,
    );
  });

  test('rejects reversed date range', () async {
    final start = DateTime(2026, 10, 2);
    final end = DateTime(2026, 10, 1);

    expect(
      () => service.getExpensesByDateRange(
        start: start,
        end: end,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('stores omitted note as null', () async {
    final expense = await service.createExpense(
      category: 'Internet',
      isPersonal: false,
      amount: 1200.0,
    );

    final expenses =
        await service.getAllExpenses();

    expect(expenses, hasLength(1));

    expect(
      expenses.first.id,
      equals(expense.id),
    );

    expect(
      expenses.first.note,
      isNull,
    );
  });
}