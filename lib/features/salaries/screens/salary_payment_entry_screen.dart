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

  Employee? _selectedEmployee;
  double? _owedThisMonth;
  bool _loadingOwed = false;
  Map<String, dynamic>? _attendanceSummary;
  String _status = 'paid';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = widget.employee;

    if (_selectedEmployee != null) {
      _amountController.text =
          _selectedEmployee!.monthlySalary.toStringAsFixed(2);
      _fetchOwed(_selectedEmployee!);
      _fetchAttendance(_selectedEmployee!);
    }
  }

  Future<void> _fetchOwed(Employee emp) async {
    setState(() => _loadingOwed = true);
    try {
      final owed = await ref
          .read(salaryServiceProvider)
          .getTotalOwedThisMonth(emp.id);
      if (mounted) {
        setState(() {
          _owedThisMonth = owed;
          _loadingOwed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingOwed = false);
      }
    }
  }

  Future<void> _fetchAttendance(Employee emp) async {
    try {
      final summary = await ref
          .read(salaryServiceProvider)
          .getMonthlyAttendanceSummary(emp.id);
      if (mounted) {
        setState(() {
          _attendanceSummary = summary;
        });
      }
    } catch (_) {}
  }

  void _onEmployeeChanged(Employee? emp) {
    if (emp == null) return;
    setState(() {
      _selectedEmployee = emp;
      _amountController.text = emp.monthlySalary.toStringAsFixed(2);
    });
    _fetchOwed(emp);
    _fetchAttendance(emp);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final emp = _selectedEmployee;
    if (emp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());

      await ref.read(salaryPaymentsProvider.notifier).recordPayment(
            employeeId: emp.id,
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
        SnackBar(
          content: Text(
            'Salary payment of ₹${amount.toStringAsFixed(2)} recorded for ${emp.name}.',
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
    final employeesAsync = ref.watch(employeesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Salary Payment'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
            // Employee Picker / Header
            if (widget.employee != null) ...[
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withAlpha(80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withAlpha(60),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          widget.employee!.name.isNotEmpty
                              ? widget.employee!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.employee!.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Monthly Salary: ₹${widget.employee!.monthlySalary.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (_owedThisMonth != null)
                              Text(
                                'Owed This Month: ₹${_owedThisMonth!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _owedThisMonth! > 0
                                      ? Colors.orange.shade800
                                      : Colors.green.shade800,
                                ),
                              )
                            else if (_loadingOwed)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                  'Calculating balance owed...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              employeesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading employees: $e'),
                data: (employees) {
                  if (employees.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No employees found. Add an employee first.'),
                      ),
                    );
                  }

                  return DropdownButtonFormField<Employee>(
                    isExpanded: true,
                    key: ValueKey(_selectedEmployee?.id),
                    initialValue: _selectedEmployee,
                    decoration: const InputDecoration(
                      labelText: 'Select Employee',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: employees.map((emp) {
                      return DropdownMenuItem<Employee>(
                        value: emp,
                        child: Text(
                          '${emp.name} (₹${emp.monthlySalary.toStringAsFixed(0)}/mo)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _saving ? null : _onEmployeeChanged,
                    validator: (val) =>
                        val == null ? 'Please select an employee' : null,
                  );
                },
              ),
              if (_selectedEmployee != null && _owedThisMonth != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Monthly: ₹${_selectedEmployee!.monthlySalary.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Owed This Month: ₹${_owedThisMonth!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _owedThisMonth! > 0
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Attendance Summary Synergy Card
            if (_selectedEmployee != null &&
                _attendanceSummary != null &&
                _attendanceSummary!['hasAttendance'] == true) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.event_available,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Month Attendance: ${_attendanceSummary!['presentDays']} Present, '
                          '${_attendanceSummary!['absentDays']} Absent'
                          '${_attendanceSummary!['lateDays'] > 0 ? " (${_attendanceSummary!['lateDays']} Late)" : ""}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Quick Fill Amount Chips
            if (_selectedEmployee != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_owedThisMonth != null && _owedThisMonth! > 0)
                    ActionChip(
                      avatar: const Icon(Icons.bolt, size: 16),
                      label: Text(
                        'Owed (₹${_owedThisMonth!.toStringAsFixed(0)})',
                      ),
                      onPressed: () {
                        setState(() {
                          _amountController.text =
                              _owedThisMonth!.toStringAsFixed(2);
                        });
                      },
                    ),
                  if (_attendanceSummary?['suggestedSalary'] != null)
                    ActionChip(
                      avatar:
                          const Icon(Icons.calculate_outlined, size: 16),
                      label: Text(
                        'Prorated (₹${(_attendanceSummary!['suggestedSalary'] as double).toStringAsFixed(0)})',
                      ),
                      onPressed: () {
                        setState(() {
                          _amountController.text =
                              (_attendanceSummary!['suggestedSalary']
                                      as double)
                                  .toStringAsFixed(2);
                        });
                      },
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_month, size: 16),
                    label: Text(
                      'Full (₹${_selectedEmployee!.monthlySalary.toStringAsFixed(0)})',
                    ),
                    onPressed: () {
                      setState(() {
                        _amountController.text = _selectedEmployee!.monthlySalary
                            .toStringAsFixed(2);
                      });
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.pie_chart_outline, size: 16),
                    label: Text(
                      '50% (₹${(_selectedEmployee!.monthlySalary / 2).toStringAsFixed(0)})',
                    ),
                    onPressed: () {
                      setState(() {
                        _amountController.text =
                            (_selectedEmployee!.monthlySalary / 2)
                                .toStringAsFixed(2);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Amount field
            TextFormField(
              controller: _amountController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Payment Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter payment amount';
                }

                final amount = double.tryParse(value.trim());

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

            // Status Dropdown
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Payment Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'paid',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text('Paid (Disbursed now)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'pending',
                  child: Row(
                    children: [
                      Icon(Icons.pending, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Text('Pending (Record as accrued/due)'),
                    ],
                  ),
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

            // Save button
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.payment_rounded),
                label: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Record Salary Payment',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
          ),
        ),
      ),
    );
  }
}