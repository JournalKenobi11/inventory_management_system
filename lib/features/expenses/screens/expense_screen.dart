import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'expense_entry_screen.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() =>
      _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String _filter = 'all';

  Future<void> _applyFilter(String value) async {
    setState(() {
      _filter = value;
    });

    final notifier = ref.read(expensesProvider.notifier);

    if (value == 'all') {
      await notifier.loadExpenses();
    } else if (value == 'business') {
      await notifier.loadByType(false);
    } else {
      await notifier.loadByType(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filter,
            onSelected: _applyFilter,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'all',
                child: Text('All'),
              ),
              PopupMenuItem(
                value: 'business',
                child: Text('Business'),
              ),
              PopupMenuItem(
                value: 'personal',
                child: Text('Personal'),
              ),
            ],
          ),
        ],
      ),
      body: expensesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(error.toString()),
          ),
        ),
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              child: Text('No expenses recorded.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref
                .read(expensesProvider.notifier)
                .loadExpenses(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                return _ExpenseCard(
                  expense: expenses[index],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const ExpenseEntryScreen(),
            ),
          );

          if (saved == true && mounted) {
            await ref
                .read(expensesProvider.notifier)
                .loadExpenses();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;

  const _ExpenseCard({
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(expense.entryDate);

    final dateText = date == null
        ? expense.entryDate
        : '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year} '
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(expense.category),
        subtitle: Text(
          [
            expense.isPersonal ? 'Personal' : 'Business',
            if (expense.note != null) expense.note!,
            dateText,
          ].join(' • '),
        ),
        trailing: Text(
          '₹${expense.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}