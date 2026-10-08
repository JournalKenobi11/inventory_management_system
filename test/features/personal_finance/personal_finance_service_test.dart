import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/core/errors/app_exceptions.dart';
import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/personal_finance/personal_finance.dart';
import 'package:inventory_management_system/features/personal_finance/repositories/sqlite/sqlite_personal_finance_account_repository.dart';
import 'package:inventory_management_system/features/personal_finance/repositories/sqlite/sqlite_personal_finance_transaction_repository.dart';

void main() {
  late AppDatabase database;
  late SqlitePersonalFinanceAccountRepository accountRepository;
  late SqlitePersonalFinanceTransactionRepository transactionRepository;
  late PersonalFinanceService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepository = SqlitePersonalFinanceAccountRepository(database);
    transactionRepository = SqlitePersonalFinanceTransactionRepository(
      database,
    );
    service = PersonalFinanceService(accountRepository, transactionRepository);
  });

  tearDown(() async {
    await database.close();
  });

  group('PersonalFinanceService - Account Management', () {
    test(
      '1. creates and retrieves Owner Account automatically or explicitly',
      () async {
        final defaultAccount = await service.getOwnerAccount();
        expect(defaultAccount.name, equals("Owner's Account"));
        expect(defaultAccount.openingBalance, equals(0.0));

        final customAccount = await service.createAccount(
          name: 'Savings Ledger',
          openingBalance: 15000.0,
        );
        expect(customAccount.name, equals('Savings Ledger'));
        expect(customAccount.openingBalance, equals(15000.0));
        expect(customAccount.id, isNotEmpty);
      },
    );

    test(
      '10. opening balance is included correctly in current balance',
      () async {
        await service.updateOpeningBalance(openingBalance: 25000.0);
        final balance = await service.getCurrentBalance();
        expect(balance, equals(25000.0));
      },
    );

    test('validates account opening balance cannot be negative', () async {
      expect(
        () => service.createAccount(name: 'Bad Account', openingBalance: -500),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => service.updateOpeningBalance(openingBalance: -100),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('PersonalFinanceService - Transactions & Validation', () {
    test('2. creates a credit transaction', () async {
      final tx = await service.addTransaction(
        type: 'credit',
        amount: 50000.0,
        category: 'Salary',
        payee: 'Company XYZ',
        note: 'October salary',
        transactionDate: '2026-10-01T10:00:00.000',
      );

      expect(tx.type, equals('credit'));
      expect(tx.amount, equals(50000.0));
      expect(tx.category, equals('Salary'));
      expect(tx.payee, equals('Company XYZ'));
      expect(tx.note, equals('October salary'));
      expect(tx.isCredit, isTrue);
      expect(tx.isDebit, isFalse);
    });

    test('3. creates a debit transaction', () async {
      final tx = await service.addTransaction(
        type: 'debit',
        amount: 10000.0,
        category: 'Family',
        payee: 'Mother',
        note: 'Sent money to mother',
      );

      expect(tx.type, equals('debit'));
      expect(tx.amount, equals(10000.0));
      expect(tx.category, equals('Family'));
      expect(tx.payee, equals('Mother'));
      expect(tx.isDebit, isTrue);
      expect(tx.isCredit, isFalse);
    });

    test('4. amount <= 0 is rejected', () async {
      expect(
        () => service.addTransaction(
          type: 'credit',
          amount: 0.0,
          category: 'Gift',
        ),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => service.addTransaction(
          type: 'debit',
          amount: -500.0,
          category: 'Bills',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('5. empty category is rejected', () async {
      expect(
        () => service.addTransaction(
          type: 'credit',
          amount: 1000.0,
          category: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('6. invalid transaction type is rejected', () async {
      expect(
        () => service.addTransaction(
          type: 'transfer',
          amount: 1000.0,
          category: 'Other',
        ),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => service.addTransaction(
          type: '',
          amount: 1000.0,
          category: 'Other',
        ),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => service.addTransaction(
          type: 'unknown',
          amount: 1000.0,
          category: 'Other',
        ),
        throwsA(isA<ValidationException>()),
      );

      final tx = await service.addTransaction(
        type: 'CREDIT',
        amount: 1000.0,
        category: 'Other',
      );
      expect(tx.type, equals('credit'));
    });
  });

  group('PersonalFinanceService - Balance Calculations', () {
    test('7. credit increases balance', () async {
      await service.updateOpeningBalance(openingBalance: 10000.0);
      await service.addTransaction(
        type: 'credit',
        amount: 5000.0,
        category: 'Gift',
      );

      final balance = await service.getCurrentBalance();
      expect(balance, equals(15000.0));
    });

    test('8. debit decreases balance', () async {
      await service.updateOpeningBalance(openingBalance: 10000.0);
      await service.addTransaction(
        type: 'debit',
        amount: 3000.0,
        category: 'Shopping',
      );

      final balance = await service.getCurrentBalance();
      expect(balance, equals(7000.0));
    });

    test('9. multiple transactions calculate balance correctly', () async {
      // Opening: 10,000
      // Credit: 50,000
      // Debit: 10,000
      // Debit: 500
      // Credit: 2,000
      // Expected = 10,000 + 50,000 - 10,000 - 500 + 2,000 = 51,500
      await service.updateOpeningBalance(openingBalance: 10000.0);

      await service.addTransaction(
        type: 'credit',
        amount: 50000.0,
        category: 'Salary',
      );
      await service.addTransaction(
        type: 'debit',
        amount: 10000.0,
        category: 'Family',
      );
      await service.addTransaction(
        type: 'debit',
        amount: 500.0,
        category: 'Miscellaneous',
      );
      await service.addTransaction(
        type: 'credit',
        amount: 2000.0,
        category: 'Other Income',
      );

      final balance = await service.getCurrentBalance();
      expect(balance, equals(51500.0));
    });

    test('12. credit/debit totals are correct', () async {
      final account = await service.getOwnerAccount();

      await service.addTransaction(
        accountId: account.id,
        type: 'credit',
        amount: 1500.0,
        category: 'Salary',
      );
      await service.addTransaction(
        accountId: account.id,
        type: 'credit',
        amount: 3500.0,
        category: 'Gift',
      );
      await service.addTransaction(
        accountId: account.id,
        type: 'debit',
        amount: 2000.0,
        category: 'Bills',
      );

      final totalCredits = await transactionRepository.getTotalCredits(
        accountId: account.id,
      );
      final totalDebits = await transactionRepository.getTotalDebits(
        accountId: account.id,
      );

      expect(totalCredits, equals(5000.0));
      expect(totalDebits, equals(2000.0));
    });
  });

  group('PersonalFinanceService - Queries, Summaries & Sorting', () {
    test('11. date-range filtering works', () async {
      final account = await service.getOwnerAccount();

      await service.addTransaction(
        accountId: account.id,
        type: 'credit',
        amount: 1000.0,
        category: 'Salary',
        transactionDate: '2026-09-15T09:00:00.000',
      );
      await service.addTransaction(
        accountId: account.id,
        type: 'debit',
        amount: 200.0,
        category: 'Food',
        transactionDate: '2026-10-05T12:00:00.000',
      );
      await service.addTransaction(
        accountId: account.id,
        type: 'credit',
        amount: 500.0,
        category: 'Gift',
        transactionDate: '2026-10-15T18:00:00.000',
      );
      await service.addTransaction(
        accountId: account.id,
        type: 'debit',
        amount: 100.0,
        category: 'Transport',
        transactionDate: '2026-11-01T08:00:00.000',
      );

      final octoberTxs = await service.getTransactionsByDateRange(
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 31, 23, 59, 59),
      );

      expect(octoberTxs.length, equals(2));
      expect(octoberTxs.map((t) => t.category), containsAll(['Food', 'Gift']));
    });

    test('13. monthly summary is correct', () async {
      await service.updateOpeningBalance(openingBalance: 12000.0);

      // October transactions
      await service.addTransaction(
        type: 'credit',
        amount: 4000.0,
        category: 'Refund',
        transactionDate: '2026-10-02T10:00:00.000',
      );
      await service.addTransaction(
        type: 'debit',
        amount: 1500.0,
        category: 'Bills',
        transactionDate: '2026-10-10T11:00:00.000',
      );

      // Previous month transaction (should not affect October credits/debits)
      await service.addTransaction(
        type: 'credit',
        amount: 10000.0,
        category: 'Salary',
        transactionDate: '2026-09-20T10:00:00.000',
      );

      final summary = await service.getMonthlySummary(
        month: DateTime(2026, 10, 15),
      );

      expect(summary.totalCredits, equals(4000.0));
      expect(summary.totalDebits, equals(1500.0));
      expect(summary.netChange, equals(2500.0)); // 4000 - 1500
      expect(summary.openingBalance, equals(12000.0));
      // Total current balance includes all transactions:
      // 12000 + 4000 - 1500 + 10000 = 24500
      expect(summary.currentBalance, equals(24500.0));
    });

    test('14. transactions are returned newest first', () async {
      await service.addTransaction(
        type: 'credit',
        amount: 100.0,
        category: 'Salary',
        transactionDate: '2026-10-01T10:00:00.000',
      );
      await service.addTransaction(
        type: 'debit',
        amount: 200.0,
        category: 'Food',
        transactionDate: '2026-10-03T10:00:00.000',
      );
      await service.addTransaction(
        type: 'credit',
        amount: 300.0,
        category: 'Gift',
        transactionDate: '2026-10-02T10:00:00.000',
      );

      final txs = await service.getTransactions();
      expect(txs.length, equals(3));
      expect(txs[0].transactionDate, equals('2026-10-03T10:00:00.000'));
      expect(txs[1].transactionDate, equals('2026-10-02T10:00:00.000'));
      expect(txs[2].transactionDate, equals('2026-10-01T10:00:00.000'));
    });
  });
}
