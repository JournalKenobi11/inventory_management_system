import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/personal_finance_categories.dart';
import '../providers/personal_finance_provider.dart';

class PersonalFinanceTransactionEntryScreen extends ConsumerStatefulWidget {
  const PersonalFinanceTransactionEntryScreen({super.key});

  @override
  ConsumerState<PersonalFinanceTransactionEntryScreen> createState() =>
      _PersonalFinanceTransactionEntryScreenState();
}

class _PersonalFinanceTransactionEntryScreenState
    extends ConsumerState<PersonalFinanceTransactionEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'debit';
  late String _category;
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _category = PersonalFinanceCategories.forType(_type).first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payeeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    if (_type != newType) {
      setState(() {
        _type = newType;
        final availableCategories = PersonalFinanceCategories.forType(newType);
        if (!availableCategories.contains(_category)) {
          _category = availableCategories.first;
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final now = DateTime.now();
      // Combine picked date with current time for exact ordering
      final fullDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      ).toIso8601String();

      await ref
          .read(personalFinanceTransactionsProvider.notifier)
          .addTransaction(
            type: _type,
            amount: amount,
            category: _category,
            payee: _payeeController.text,
            note: _noteController.text,
            transactionDate: fullDate,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_type == "credit" ? "Credit" : "Debit"} of ₹${amount.toStringAsFixed(2)} added successfully.',
          ),
          backgroundColor: _type == 'credit'
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = PersonalFinanceCategories.forType(_type);
    final dateDisplay =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Transaction Type Toggle
              const Text(
                'Transaction Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'credit',
                    icon: Icon(
                      Icons.arrow_downward_rounded,
                      color: Colors.green,
                    ),
                    label: Text('Credit (In)'),
                  ),
                  ButtonSegment(
                    value: 'debit',
                    icon: Icon(Icons.arrow_upward_rounded, color: Colors.red),
                    label: Text('Debit (Out)'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (set) => _onTypeChanged(set.first),
              ),
              const SizedBox(height: 20),

              // 2. Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    _type == 'credit'
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    color: _type == 'credit' ? Colors.green : Colors.red,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid amount greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Category Dropdown
              DropdownButtonFormField<String>(
                key: ValueKey('$_type-$_category'),
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _category = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // 4. Payee / From Field
              TextFormField(
                controller: _payeeController,
                decoration: InputDecoration(
                  labelText: _type == 'credit'
                      ? 'From / Received From'
                      : 'Payee / Given To',
                  hintText: _type == 'credit'
                      ? 'e.g. Client, Shop, Friend'
                      : 'e.g. Mother, Grocery, Petrol Pump',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Note Field
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note / Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Date Field
              InkWell(
                onTap: _isSaving ? null : _selectDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateDisplay, style: const TextStyle(fontSize: 16)),
                      const Icon(Icons.edit, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 7. Save Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSaving
                      ? 'Saving Transaction...'
                      : 'Save ${_type == "credit" ? "Credit" : "Debit"}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
