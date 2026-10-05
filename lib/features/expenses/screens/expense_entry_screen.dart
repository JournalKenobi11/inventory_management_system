
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/expense_provider.dart';

class ExpenseEntryScreen extends ConsumerStatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  ConsumerState<ExpenseEntryScreen> createState() =>
      _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState
    extends ConsumerState<ExpenseEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  static const _categories = [
    'Rent',
    'Electricity',
    'Internet',
    'Fuel',
    'Equipment',
    'Tools',
    'Tea & Snacks',
    'Miscellaneous',
  ];

  String _category = _categories.first;
  bool _isPersonal = false;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ref.read(expensesProvider.notifier).addExpense(
            category: _category,
            isPersonal: _isPersonal,
            amount: double.parse(
              _amountController.text.trim(),
            ),
            note: _noteController.text,
          );

      final state = ref.read(expensesProvider);

      if (state.hasError) {
        throw state.error!;
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Expense recorded successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _category = value;
                        });
                      }
                    },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Personal expense'),
              subtitle: Text(
                _isPersonal
                    ? 'Tracked separately from business expenses'
                    : 'Recorded as a business expense',
              ),
              value: _isPersonal,
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _isPersonal = value;
                      });
                    },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter amount';
                }

                final amount =
                    double.tryParse(value.trim());

                if (amount == null) {
                  return 'Enter a valid amount';
                }

                if (amount <= 0) {
                  return 'Amount must be greater than zero';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_saving,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(),
                      )
                    : const Text('Save Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
