import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../models/unified_expense_item.dart';
import '../providers/expense_provider.dart';
import '../providers/unified_expense_provider.dart';
import 'expense_entry_screen.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() =>
      _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Expenses'),
            Tab(text: 'Salary'),
            Tab(text: 'Stock Purchases'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ManualExpensesTab(filter: _filter, onFilterChanged: _applyFilter),
          const _SalaryExpensesTab(),
          const _PurchaseExpensesTab(),
        ],
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

/// Tab 1: Manual expenses (original list with filter).
class _ManualExpensesTab extends ConsumerWidget {
  final String filter;
  final Future<void> Function(String) onFilterChanged;

  const _ManualExpensesTab({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Row(
            children: [
              const Text(
                'Filter: ',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('All'),
                selected: filter == 'all',
                onSelected: (_) => onFilterChanged('all'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Business'),
                selected: filter == 'business',
                onSelected: (_) => onFilterChanged('business'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Personal'),
                selected: filter == 'personal',
                onSelected: (_) => onFilterChanged('personal'),
              ),
            ],
          ),
        ),
        Expanded(
          child: expensesAsync.when(
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
        ),
      ],
    );
  }
}

/// Tab 2: Salary payments shown as expenses.
class _SalaryExpensesTab extends ConsumerWidget {
  const _SalaryExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salaryExpensesAsync = ref.watch(salaryExpensesProvider);

    return salaryExpensesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(error.toString()),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('No salary payments recorded.'),
          );
        }

        final totalSalary = items.fold<double>(
          0,
          (sum, item) => sum + item.amount,
        );

        return Column(
          children: [
            _SummaryBanner(
              label: 'Total Salary Expense',
              amount: totalSalary,
              icon: Icons.badge,
              color: Colors.orange,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(salaryExpensesProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _UnifiedExpenseCard(
                      item: items[index],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Tab 3: Stock purchases shown as expenses.
class _PurchaseExpensesTab extends ConsumerWidget {
  const _PurchaseExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseExpensesAsync = ref.watch(purchaseExpensesProvider);

    return purchaseExpensesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(error.toString()),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('No stock purchases recorded.'),
          );
        }

        final totalPurchase = items.fold<double>(
          0,
          (sum, item) => sum + item.amount,
        );

        return Column(
          children: [
            _SummaryBanner(
              label: 'Total Stock Purchase Expense',
              amount: totalPurchase,
              icon: Icons.shopping_cart,
              color: Colors.blue,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(purchaseExpensesProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _UnifiedExpenseCard(
                      item: items[index],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Summary banner at the top of salary and purchase tabs.
class _SummaryBanner extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryBanner({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for the original manual expenses.
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

/// Card for unified expense items (salary / purchase).
class _UnifiedExpenseCard extends StatelessWidget {
  final UnifiedExpenseItem item;

  const _UnifiedExpenseCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(item.entryDate);

    final dateText = date == null
        ? item.entryDate
        : '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}';

    final iconData = item.type == 'salary'
        ? Icons.badge
        : Icons.shopping_cart;

    final iconColor = item.type == 'salary'
        ? Colors.orange
        : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withAlpha(38),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Text(
          item.note ?? item.category,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(dateText),
        trailing: Text(
          '₹${item.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}