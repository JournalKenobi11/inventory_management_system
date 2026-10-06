import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../providers/salary_provider.dart';
import 'employee_form_screen.dart';
import 'salary_payment_entry_screen.dart';

class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  Future<void> _deleteEmployee(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Employee'),
          content: Text(
            'Delete ${employee.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(employeesProvider.notifier)
          .deleteEmployee(employee.id);

      final state = ref.read(employeesProvider);

      if (state.hasError) {
        throw state.error!;
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(error.toString()),
          ),
        ),
        data: (employees) {
          if (employees.isEmpty) {
            return const Center(
              child: Text(
                'No employees added yet.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(employeesProvider.notifier)
                    .loadEmployees(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: employees.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final employee = employees[index];

                return Card(
                  child: ListTile(
                    title: Text(employee.name),
                    subtitle: Text(
                      'Monthly salary: ₹${employee.monthlySalary.toStringAsFixed(2)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EmployeeFormScreen(
                                employee: employee,
                              ),
                            ),
                          );

                          ref.invalidate(
                            employeesProvider,
                          );
                        } else if (value == 'payment') {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SalaryPaymentEntryScreen(
                                employee: employee,
                              ),
                            ),
                          );
                        } else if (value == 'delete') {
                          await _deleteEmployee(
                            context,
                            ref,
                            employee,
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'payment',
                          child: Text(
                            'Record Salary Payment',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const EmployeeFormScreen(),
            ),
          );

          ref.invalidate(employeesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}