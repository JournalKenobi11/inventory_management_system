import '../../models/personal_finance_account.dart';

abstract class PersonalFinanceAccountRepository {
  Future<PersonalFinanceAccount> create(PersonalFinanceAccount account);

  Future<PersonalFinanceAccount?> getById(String id);

  Future<PersonalFinanceAccount?> getDefaultAccount();

  Future<void> update(PersonalFinanceAccount account);

  Future<void> updateOpeningBalance(String accountId, double openingBalance);
}
