import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/personal_finance_transaction.dart';
import '../providers/personal_finance_provider.dart';
import 'personal_finance_transaction_entry_screen.dart';

class PersonalFinanceScreen extends ConsumerStatefulWidget {
  const PersonalFinanceScreen({super.key});

  @override
  ConsumerState<PersonalFinanceScreen> createState() =>
      _PersonalFinanceScreenState();
}

class _PersonalFinanceScreenState extends ConsumerState<PersonalFinanceScreen> {
  Future<void> _refreshAll() async {
    ref.invalidate(ownerAccountProvider);
    ref.invalidate(personalFinanceBalanceProvider);
    ref.invalidate(personalFinanceMonthlySummaryProvider);
    await ref
        .read(personalFinanceTransactionsProvider.notifier)
        .loadTransactions();
  }

  Future<void> _showEditOpeningBalanceDialog(
    double currentOpeningBalance,
  ) async {
    final controller = TextEditingController(
      text: currentOpeningBalance == 0
          ? ''
          : currentOpeningBalance.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set Opening Balance'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Configure the initial starting balance for your personal account.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Opening Balance (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an opening balance';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Please enter a valid amount (>= 0)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == true && mounted) {
      final newAmount = double.parse(controller.text.trim());
      try {
        await ref
            .read(personalFinanceTransactionsProvider.notifier)
            .updateOpeningBalance(openingBalance: newAmount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening balance updated.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update opening balance: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(personalFinanceBalanceProvider);
    final summaryAsync = ref.watch(personalFinanceMonthlySummaryProvider);
    final accountAsync = ref.watch(ownerAccountProvider);
    final transactionsAsync = ref.watch(personalFinanceTransactionsProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Current Balance Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: theme.colorScheme.primaryContainer.withAlpha(120),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Balance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Set Opening Balance',
                          onPressed: () {
                            final currentOpening =
                                accountAsync.value?.openingBalance ?? 0.0;
                            _showEditOpeningBalanceDialog(currentOpening);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    balanceAsync.when(
                      data: (balance) => Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: 36,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (err, _) => Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Opening Balance: ₹${(accountAsync.value?.openingBalance ?? 0.0).toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Monthly Summary Card
            summaryAsync.when(
              data: (summary) => Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      // Credits
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 16,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Credits',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '+₹${summary.totalCredits.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      // Debits
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 16,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Debits',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '-₹${summary.totalDebits.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      // Net Change
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Net Change',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${summary.netChange >= 0 ? '+' : ''}₹${summary.netChange.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: summary.netChange >= 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error loading summary: $err'),
            ),

            const SizedBox(height: 24),

            // 3. Transactions List Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Newest first',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transactions list
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No personal transactions yet.',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Add Transaction" below to record credits or debits.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return _PersonalTransactionCard(transaction: tx);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading transactions: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const PersonalFinanceTransactionEntryScreen(),
            ),
          );
          if (added == true && mounted) {
            await _refreshAll();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }
}

class _PersonalTransactionCard extends StatelessWidget {
  final PersonalFinanceTransaction transaction;

  const _PersonalTransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.isCredit;

    final date = DateTime.tryParse(transaction.transactionDate);
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : transaction.transactionDate;

    final color = isCredit ? Colors.green.shade700 : Colors.red.shade700;
    final bgColor = isCredit ? Colors.green.shade50 : Colors.red.shade50;
    final icon = isCredit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    final details = <String>[];
    if (transaction.payee != null && transaction.payee!.trim().isNotEmpty) {
      details.add(
        isCredit
            ? 'From: ${transaction.payee!.trim()}'
            : 'To: ${transaction.payee!.trim()}',
      );
    }
    if (transaction.note != null && transaction.note!.trim().isNotEmpty) {
      details.add(transaction.note!.trim());
    }
    details.add(dateStr);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: bgColor,
          foregroundColor: color,
          child: Icon(icon, size: 20),
        ),
        title: Text(
          transaction.category,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          details.join(' • '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
