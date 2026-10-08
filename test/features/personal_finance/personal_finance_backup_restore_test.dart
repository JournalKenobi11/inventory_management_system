import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/export/export.dart';
import 'package:inventory_management_system/features/export/repositories/sqlite/sqlite_backup_repository.dart';
import 'package:inventory_management_system/features/personal_finance/personal_finance.dart';
import 'package:inventory_management_system/features/personal_finance/repositories/sqlite/sqlite_personal_finance_account_repository.dart';
import 'package:inventory_management_system/features/personal_finance/repositories/sqlite/sqlite_personal_finance_transaction_repository.dart';

void main() {
  late AppDatabase database;
  late BackupService backupService;
  late PersonalFinanceService personalFinanceService;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    final backupRepo = SqliteBackupRepository(database);
    backupService = BackupService(backupRepo);

    final accountRepo = SqlitePersonalFinanceAccountRepository(database);
    final transactionRepo = SqlitePersonalFinanceTransactionRepository(
      database,
    );
    personalFinanceService = PersonalFinanceService(
      accountRepo,
      transactionRepo,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Personal Finance - Backup & Restore', () {
    test(
      '15 & 16. backup exports and restore restores personal finance data',
      () async {
        // 1. Setup account and transactions
        await personalFinanceService.updateOpeningBalance(
          openingBalance: 30000.0,
        );
        final creditTx = await personalFinanceService.addTransaction(
          type: 'credit',
          amount: 50000.0,
          category: 'Salary',
          payee: 'Acme Corp',
          note: 'October Paycheck',
          transactionDate: '2026-10-01T09:00:00.000',
        );
        final debitTx = await personalFinanceService.addTransaction(
          type: 'debit',
          amount: 10000.0,
          category: 'Family',
          payee: 'Mother',
          note: 'Sent to mother',
          transactionDate: '2026-10-02T10:00:00.000',
        );

        // Verify pre-backup balance
        expect(
          await personalFinanceService.getCurrentBalance(),
          equals(70000.0),
        );

        // 2. Export backup JSON
        final jsonString = await backupService.exportBackupJsonString();
        expect(jsonString.contains('personalFinanceAccounts'), isTrue);
        expect(jsonString.contains('personalFinanceTransactions'), isTrue);
        expect(jsonString.contains('30000.0'), isTrue);
        expect(jsonString.contains('Acme Corp'), isTrue);
        expect(jsonString.contains('Sent to mother'), isTrue);

        // 3. Wipe current tables to simulate clean reinstall
        await database.delete(database.personalFinanceTransactions).go();
        await database.delete(database.personalFinanceAccounts).go();

        expect(
          await database.select(database.personalFinanceAccounts).get(),
          isEmpty,
        );
        expect(
          await database.select(database.personalFinanceTransactions).get(),
          isEmpty,
        );

        // 4. Restore from backup
        final result = await backupService.restoreFromJson(jsonString);
        expect(result.success, isTrue);

        // 5. Verify restored state
        final restoredAccount = await personalFinanceService.getOwnerAccount();
        expect(restoredAccount.openingBalance, equals(30000.0));

        final restoredTxs = await personalFinanceService.getTransactions();
        expect(restoredTxs.length, equals(2));

        final restoredCredit = restoredTxs.firstWhere(
          (t) => t.id == creditTx.id,
        );
        expect(restoredCredit.amount, equals(50000.0));
        expect(restoredCredit.type, equals('credit'));
        expect(restoredCredit.payee, equals('Acme Corp'));

        final restoredDebit = restoredTxs.firstWhere((t) => t.id == debitTx.id);
        expect(restoredDebit.amount, equals(10000.0));
        expect(restoredDebit.type, equals('debit'));
        expect(restoredDebit.payee, equals('Mother'));

        final restoredBalance = await personalFinanceService
            .getCurrentBalance();
        expect(restoredBalance, equals(70000.0));
      },
    );

    test(
      '17. restoring an old backup without personal finance tables creates default owner account and works seamlessly',
      () async {
        // Simulate an old version 1 backup JSON payload without personal finance tables
        const legacyBackupJson = '''
{
  "app": "inventory_management_system",
  "version": 1,
  "exportDate": "2026-09-01T00:00:00.000Z",
  "data": {
    "customers": [
      {
        "id": "cust-1",
        "name": "Legacy Customer",
        "mobile": "9876543210",
        "vehicleName": "Honda City",
        "createdDate": "2026-09-01T00:00:00.000Z"
      }
    ],
    "parts": [],
    "purchases": [],
    "serviceJobs": [],
    "serviceParts": [],
    "invoices": [],
    "expenses": [
      {
        "id": "exp-1",
        "category": "Workshop Rent",
        "isPersonal": false,
        "amount": 15000.0,
        "note": "Rent",
        "entryDate": "2026-09-01T00:00:00.000Z"
      }
    ],
    "employees": [],
    "salaryPayments": [],
    "counters": []
  }
}
''';

        // Restore legacy backup
        final result = await backupService.restoreFromJson(legacyBackupJson);
        expect(result.success, isTrue);

        // Verify that database didn't crash and default Owner's Account was automatically created
        final ownerAccount = await personalFinanceService.getOwnerAccount();
        expect(ownerAccount.name, equals("Owner's Account"));
        expect(ownerAccount.openingBalance, equals(0.0));

        final balance = await personalFinanceService.getCurrentBalance();
        expect(balance, equals(0.0));

        // Personal transactions should still be addable and function normally
        final tx = await personalFinanceService.addTransaction(
          type: 'credit',
          amount: 5000.0,
          category: 'Gift',
        );
        expect(tx.amount, equals(5000.0));
        expect(
          await personalFinanceService.getCurrentBalance(),
          equals(5000.0),
        );
      },
    );
  });
}
