import '../../models/personal_finance_transaction.dart';

abstract class PersonalFinanceTransactionRepository {
  Future<PersonalFinanceTransaction> create(
    PersonalFinanceTransaction transaction,
  );

  Future<PersonalFinanceTransaction?> getById(String id);

  Future<List<PersonalFinanceTransaction>> getAll();

  Future<List<PersonalFinanceTransaction>> getForAccount(String accountId);

  Future<List<PersonalFinanceTransaction>> getByDateRange({
    required String accountId,
    required DateTime start,
    required DateTime end,
  });

  Future<List<PersonalFinanceTransaction>> getByType({
    required String accountId,
    required String type,
  });

  Future<List<PersonalFinanceTransaction>> getByCategory({
    required String accountId,
    required String category,
  });

  Future<double> getTotalCredits({
    required String accountId,
    DateTime? start,
    DateTime? end,
  });

  Future<double> getTotalDebits({
    required String accountId,
    DateTime? start,
    DateTime? end,
  });

  Future<void> delete(String id);
}
