import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/personal_finance_account.dart';
import '../models/personal_finance_monthly_summary.dart';
import '../models/personal_finance_transaction.dart';
import '../repositories/interfaces/personal_finance_account_repository.dart';
import '../repositories/interfaces/personal_finance_transaction_repository.dart';

class PersonalFinanceService {
  final PersonalFinanceAccountRepository accountRepository;
  final PersonalFinanceTransactionRepository transactionRepository;

  PersonalFinanceService(this.accountRepository, this.transactionRepository);

  /// Retrieves the default "Owner's Account". If none exists, creates it.
  Future<PersonalFinanceAccount> getOwnerAccount() async {
    final existing = await accountRepository.getDefaultAccount();
    if (existing != null) {
      return existing;
    }

    final defaultAccount = PersonalFinanceAccount(
      id: 'default-owner-account',
      name: "Owner's Account",
      openingBalance: 0.0,
      createdDate: AppDateUtils.nowIso(),
    );

    return accountRepository.create(defaultAccount);
  }

  /// Creates a personal finance account.
  Future<PersonalFinanceAccount> createAccount({
    required String name,
    double openingBalance = 0.0,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ValidationException('Account name cannot be empty.');
    }
    if (openingBalance < 0) {
      throw ValidationException('Opening balance cannot be negative.');
    }

    final account = PersonalFinanceAccount(
      id: IdGenerator.generate(),
      name: cleanName,
      openingBalance: openingBalance,
      createdDate: AppDateUtils.nowIso(),
    );

    return accountRepository.create(account);
  }

  /// Updates the opening balance for an account.
  Future<void> updateOpeningBalance({
    String? accountId,
    required double openingBalance,
  }) async {
    if (openingBalance < 0) {
      throw ValidationException('Opening balance cannot be negative.');
    }

    final account = accountId != null
        ? await accountRepository.getById(accountId)
        : await getOwnerAccount();

    if (account == null) {
      throw NotFoundException('Personal Finance Account', accountId ?? '');
    }

    await accountRepository.updateOpeningBalance(account.id, openingBalance);
  }

  /// Records a personal credit or debit transaction.
  Future<PersonalFinanceTransaction> addTransaction({
    String? accountId,
    required String type,
    required double amount,
    required String category,
    String? payee,
    String? note,
    String? transactionDate,
  }) async {
    final cleanType = type.trim().toLowerCase();
    if (cleanType != 'credit' && cleanType != 'debit') {
      throw ValidationException(
        "Transaction type must be 'credit' or 'debit'.",
      );
    }

    if (amount <= 0) {
      throw ValidationException('Amount must be greater than zero.');
    }

    final cleanCategory = category.trim();
    if (cleanCategory.isEmpty) {
      throw ValidationException('Category cannot be empty.');
    }

    final targetAccount = accountId != null
        ? await accountRepository.getById(accountId)
        : await getOwnerAccount();

    if (targetAccount == null) {
      throw NotFoundException('Personal Finance Account', accountId ?? '');
    }

    final txDate =
        (transactionDate != null && transactionDate.trim().isNotEmpty)
        ? transactionDate.trim()
        : AppDateUtils.nowIso();

    try {
      DateTime.parse(txDate);
    } catch (_) {
      throw ValidationException('Invalid transaction date.');
    }

    final cleanPayee = payee?.trim().isNotEmpty == true ? payee!.trim() : null;
    final cleanNote = note?.trim().isNotEmpty == true ? note!.trim() : null;

    final transaction = PersonalFinanceTransaction(
      id: IdGenerator.generate(),
      accountId: targetAccount.id,
      type: cleanType,
      amount: amount,
      category: cleanCategory,
      payee: cleanPayee,
      note: cleanNote,
      transactionDate: txDate,
    );

    return transactionRepository.create(transaction);
  }

  /// Calculates the current running balance:
  /// balance = openingBalance + totalCredits - totalDebits
  Future<double> getCurrentBalance([String? accountId]) async {
    final account = accountId != null
        ? await accountRepository.getById(accountId)
        : await getOwnerAccount();

    if (account == null) {
      throw NotFoundException('Personal Finance Account', accountId ?? '');
    }

    final credits = await transactionRepository.getTotalCredits(
      accountId: account.id,
    );
    final debits = await transactionRepository.getTotalDebits(
      accountId: account.id,
    );

    return account.openingBalance + credits - debits;
  }

  /// Returns transactions for an account ordered newest first.
  Future<List<PersonalFinanceTransaction>> getTransactions([
    String? accountId,
  ]) async {
    final account = accountId != null
        ? await accountRepository.getById(accountId)
        : await getOwnerAccount();

    if (account == null) {
      throw NotFoundException('Personal Finance Account', accountId ?? '');
    }

    return transactionRepository.getForAccount(account.id);
  }

  /// Returns transactions filtered by a date range.
  Future<List<PersonalFinanceTransaction>> getTransactionsByDateRange({
    String? accountId,
    required DateTime start,
    required DateTime end,
  }) async {
    if (start.isAfter(end)) {
      throw ValidationException('Start date cannot be after end date.');
    }

    final account = accountId != null
        ? await accountRepository.getById(accountId)
        : await getOwnerAccount();

    if (account == null) {
      throw NotFoundException('Personal Finance Account', accountId ?? '');
    }

    return transactionRepository.getByDateRange(
      accountId: account.id,
      start: start,
      end: end,
    );
  }

  /// Calculates the monthly financial summary:
  /// - opening balance
  /// - total credits for the month
  /// - total debits for the month
  /// - net change (credits - debits)
  /// - current balance
  Future<PersonalFinanceMonthlySummary> getMonthlySummary({
    String? accountId,
    DateTime? month,
  }) async {
    final account = accountId != null
        ? await accountRepository.getById(accountId)
        : await getOwnerAccount();

    if (account == null) {
      throw NotFoundException('Personal Finance Account', accountId ?? '');
    }

    final targetDate = month ?? DateTime.now();
    final start = DateTime(targetDate.year, targetDate.month, 1);
    final end = DateTime(
      targetDate.year,
      targetDate.month + 1,
      0,
      23,
      59,
      59,
      999,
    );

    final credits = await transactionRepository.getTotalCredits(
      accountId: account.id,
      start: start,
      end: end,
    );

    final debits = await transactionRepository.getTotalDebits(
      accountId: account.id,
      start: start,
      end: end,
    );

    final totalBalance = await getCurrentBalance(account.id);

    return PersonalFinanceMonthlySummary(
      openingBalance: account.openingBalance,
      totalCredits: credits,
      totalDebits: debits,
      netChange: credits - debits,
      currentBalance: totalBalance,
    );
  }
}
