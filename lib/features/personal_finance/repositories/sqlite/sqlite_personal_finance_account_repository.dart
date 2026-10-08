import 'package:drift/drift.dart';

import '../../../../database/app_database.dart' as db;
import '../../models/personal_finance_account.dart';
import '../interfaces/personal_finance_account_repository.dart';

class SqlitePersonalFinanceAccountRepository
    implements PersonalFinanceAccountRepository {
  final db.AppDatabase database;

  SqlitePersonalFinanceAccountRepository(this.database);

  @override
  Future<PersonalFinanceAccount> create(PersonalFinanceAccount account) async {
    await database
        .into(database.personalFinanceAccounts)
        .insert(
          db.PersonalFinanceAccountsCompanion.insert(
            id: account.id,
            name: account.name,
            openingBalance: Value(account.openingBalance),
            createdDate: account.createdDate,
          ),
        );
    return account;
  }

  @override
  Future<PersonalFinanceAccount?> getById(String id) async {
    final query = database.select(database.personalFinanceAccounts)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<PersonalFinanceAccount?> getDefaultAccount() async {
    // 1. Try finding by default id or default name
    final byIdQuery = database.select(database.personalFinanceAccounts)
      ..where(
        (tbl) =>
            tbl.id.equals('default-owner-account') |
            tbl.name.equals("Owner's Account"),
      )
      ..limit(1);
    final row = await byIdQuery.getSingleOrNull();
    if (row != null) return _toModel(row);

    // 2. Otherwise return the first available account
    final firstQuery = database.select(database.personalFinanceAccounts)
      ..limit(1);
    final firstRow = await firstQuery.getSingleOrNull();
    if (firstRow != null) return _toModel(firstRow);

    return null;
  }

  @override
  Future<void> update(PersonalFinanceAccount account) async {
    await (database.update(
      database.personalFinanceAccounts,
    )..where((tbl) => tbl.id.equals(account.id))).write(
      db.PersonalFinanceAccountsCompanion(
        name: Value(account.name),
        openingBalance: Value(account.openingBalance),
      ),
    );
  }

  @override
  Future<void> updateOpeningBalance(
    String accountId,
    double openingBalance,
  ) async {
    await (database.update(
      database.personalFinanceAccounts,
    )..where((tbl) => tbl.id.equals(accountId))).write(
      db.PersonalFinanceAccountsCompanion(
        openingBalance: Value(openingBalance),
      ),
    );
  }

  PersonalFinanceAccount _toModel(db.PersonalFinanceAccount row) {
    return PersonalFinanceAccount(
      id: row.id,
      name: row.name,
      openingBalance: row.openingBalance,
      createdDate: row.createdDate,
    );
  }
}
