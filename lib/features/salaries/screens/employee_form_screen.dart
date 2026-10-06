import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../providers/salary_provider.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final Employee? employee;

  const EmployeeFormScreen({
    super.key,
    this.employee,
  });

  bool get isEditing => employee != null;

  @override
  ConsumerState<EmployeeFormScreen> createState() =>
      _EmployeeFormScreenState();
}

class _EmployeeFormScreenState
    extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _salaryController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.employee?.name ?? '',
    );

    _salaryController = TextEditingController(
      text: widget.employee?.monthlySalary
              .toStringAsFixed(2) ??
          '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salaryController.dispose();
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
      final name = _nameController.text.trim();
      final salary =
          double.parse(_salaryController.text.trim());

      if (widget.isEditing) {
        await ref
            .read(employeesProvider.notifier)
            .updateEmployee(
              widget.employee!.copyWith(
                name: name,
                monthlySalary: salary,
              ),
            );
      } else {
        await ref
            .read(employeesProvider.notifier)
            .addEmployee(
              name: name,
              monthlySalary: salary,
            );
      }

      final state = ref.read(employeesProvider);

      if (state.hasError) {
        throw state.error!;
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Employee updated successfully.'
                : 'Employee added successfully.',
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
        title: Text(
          widget.isEditing
              ? 'Edit Employee'
              : 'Add Employee',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Employee Name',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter employee name';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _salaryController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Monthly Salary',
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
                  return 'Enter monthly salary';
                }

                final salary =
                    double.tryParse(value.trim());

                if (salary == null) {
                  return 'Enter a valid salary';
                }

                if (salary <= 0) {
                  return 'Salary must be greater than zero';
                }

                return null;
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
                    : Text(
                        widget.isEditing
                            ? 'Update Employee'
                            : 'Save Employee',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}