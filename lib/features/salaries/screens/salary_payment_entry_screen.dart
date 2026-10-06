import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../providers/salary_provider.dart';

class SalaryPaymentEntryScreen extends ConsumerStatefulWidget {
  final Employee? employee;

  const SalaryPaymentEntryScreen({
    super.key,
    this.employee,
  });

  @override
  ConsumerState<SalaryPaymentEntryScreen> createState() =>
      _SalaryPaymentEntryScreenState();
}

class _SalaryPaymentEntryScreenState
    extends ConsumerState<SalaryPaymentEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();

  String _status = 'paid';
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.employee != null) {
      _amountController.text =
          widget.employee!.monthlySalary.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.employee == null) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final amount =
          double.parse(_amountController.text.trim());

      await ref
          .read(salaryPaymentsProvider.notifier)
          .recordPayment(
            employeeId: widget.employee!.id,
            amount: amount,
            status: _status,
          );

      final state = ref.read(salaryPaymentsProvider);

      if (state.hasError) {
        throw state.error!;
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Salary payment recorded successfully.',
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
    if (widget.employee == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Employee is required.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Salary Payment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.employee!.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Monthly salary: ₹${widget.employee!.monthlySalary.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Payment Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter payment amount';
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
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'paid',
                  child: Text('Paid'),
                ),
                DropdownMenuItem(
                  value: 'pending',
                  child: Text('Pending'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _status = value;
                        });
                      }
                    },
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
                    : const Text(
                        'Record Payment',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}