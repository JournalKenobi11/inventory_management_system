import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../models/personal_finance_account.dart';
import '../models/personal_finance_monthly_summary.dart';
import '../models/personal_finance_transaction.dart';
import '../repositories/interfaces/personal_finance_account_repository.dart';
import '../repositories/interfaces/personal_finance_transaction_repository.dart';
import '../repositories/sqlite/sqlite_personal_finance_account_repository.dart';
import '../repositories/sqlite/sqlite_personal_finance_transaction_repository.dart';
import '../services/personal_finance_service.dart';

final personalFinanceAccountRepositoryProvider =
    Provider<PersonalFinanceAccountRepository>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return SqlitePersonalFinanceAccountRepository(database);
    });

final personalFinanceTransactionRepositoryProvider =
    Provider<PersonalFinanceTransactionRepository>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return SqlitePersonalFinanceTransactionRepository(database);
    });

final personalFinanceServiceProvider = Provider<PersonalFinanceService>((ref) {
  return PersonalFinanceService(
    ref.watch(personalFinanceAccountRepositoryProvider),
    ref.watch(personalFinanceTransactionRepositoryProvider),
  );
});

final ownerAccountProvider = FutureProvider<PersonalFinanceAccount>((
  ref,
) async {
  final service = ref.watch(personalFinanceServiceProvider);
  return service.getOwnerAccount();
});

final personalFinanceBalanceProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(personalFinanceServiceProvider);
  return service.getCurrentBalance();
});

final personalFinanceMonthlySummaryProvider =
    FutureProvider<PersonalFinanceMonthlySummary>((ref) async {
      final service = ref.watch(personalFinanceServiceProvider);
      return service.getMonthlySummary();
    });

final personalFinanceTransactionsProvider =
    AsyncNotifierProvider<
      PersonalFinanceTransactionsNotifier,
      List<PersonalFinanceTransaction>
    >(PersonalFinanceTransactionsNotifier.new);

class PersonalFinanceTransactionsNotifier
    extends AsyncNotifier<List<PersonalFinanceTransaction>> {
  PersonalFinanceService get service =>
      ref.read(personalFinanceServiceProvider);

  @override
  Future<List<PersonalFinanceTransaction>> build() async {
    return service.getTransactions();
  }

  Future<void> loadTransactions() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => service.getTransactions());
  }

  Future<PersonalFinanceTransaction> addTransaction({
    String? accountId,
    required String type,
    required double amount,
    required String category,
    String? payee,
    String? note,
    String? transactionDate,
  }) async {
    final transaction = await service.addTransaction(
      accountId: accountId,
      type: type,
      amount: amount,
      category: category,
      payee: payee,
      note: note,
      transactionDate: transactionDate,
    );

    // Refresh balance, summary, and transaction list
    ref.invalidate(personalFinanceBalanceProvider);
    ref.invalidate(personalFinanceMonthlySummaryProvider);
    ref.invalidate(ownerAccountProvider);

    state = await AsyncValue.guard(() => service.getTransactions());

    return transaction;
  }

  Future<void> updateOpeningBalance({
    String? accountId,
    required double openingBalance,
  }) async {
    await service.updateOpeningBalance(
      accountId: accountId,
      openingBalance: openingBalance,
    );

    ref.invalidate(ownerAccountProvider);
    ref.invalidate(personalFinanceBalanceProvider);
    ref.invalidate(personalFinanceMonthlySummaryProvider);

    state = await AsyncValue.guard(() => service.getTransactions());
  }
}
