import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance.dart';
import '../models/attendance_config.dart';
import '../models/attendance_period.dart';
import '../models/employee.dart';
import '../providers/salary_provider.dart';
import 'employee_attendance_detail_screen.dart';
import 'employee_form_screen.dart';
import 'record_attendance_dialog.dart';
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
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

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Employee ${employee.name} deleted successfully.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesState = ref.watch(employeesProvider);
    final selectedPeriod = ref.watch(selectedAttendancePeriodProvider);
    final todayAttendanceAsync = ref.watch(todayAttendanceMapProvider);
    final summariesAsync = ref.watch(employeeAttendanceSummariesProvider);
    final config = ref.watch(attendanceConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.how_to_reg_rounded),
            tooltip: "Record Today's Attendance",
            onPressed: () async {
              await RecordAttendanceDialog.show(context);
            },
          ),
        ],
      ),
      body: employeesState.when(
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

          final todayMap = todayAttendanceAsync.asData?.value ?? const {};
          final summariesMap = summariesAsync.asData?.value ?? const {};

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(employeesProvider.notifier).loadEmployees();
              ref.invalidate(todayAttendanceMapProvider);
              ref.invalidate(employeeAttendanceSummariesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Period Selector & Quick Actions Bar
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Period:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<AttendancePeriod>(
                          value: selectedPeriod,
                          isDense: true,
                          underline: const SizedBox(),
                          items: AttendancePeriod.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                p.label,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(selectedAttendancePeriodProvider.notifier)
                                  .setPeriod(val);
                            }
                          },
                        ),
                        const Spacer(),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Mark Today'),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () async {
                            await RecordAttendanceDialog.show(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Employee Cards List
                ...employees.map((employee) {
                  final todayRecord = todayMap[employee.id];
                  final summary = summariesMap[employee.id];
                  final lateCount = summary?.lateDays ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EmployeeAttendanceDetailScreen(
                              employee: employee,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Name and Popup Menu
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Text(
                                    employee.name.isNotEmpty
                                        ? employee.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Monthly salary: ₹${employee.monthlySalary.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'attendance') {
                                      await RecordAttendanceDialog.show(
                                        context,
                                        employee: employee,
                                        existingAttendance: todayRecord,
                                      );
                                    } else if (value == 'edit') {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => EmployeeFormScreen(
                                            employee: employee,
                                          ),
                                        ),
                                      );
                                      ref.invalidate(employeesProvider);
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
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'attendance',
                                      child: Text('Record Attendance'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'payment',
                                      child: Text('Record Salary Payment'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),

                            // Bottom Row: Today's Status Badge & Late Days Count
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                // Today's Attendance Status
                                Expanded(
                                  child: _buildTodayStatus(
                                    todayRecord,
                                    config,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Late-day Count for the Period
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lateCount > 0
                                        ? Colors.red.shade50
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: lateCount > 0
                                          ? Colors.red.shade300
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.alarm_rounded,
                                        size: 15,
                                        color: lateCount > 0
                                            ? Colors.red.shade800
                                            : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Late days: $lateCount',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: lateCount > 0
                                              ? Colors.red.shade900
                                              : Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EmployeeFormScreen(),
            ),
          );
          ref.invalidate(employeesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayStatus(
    Attendance? record,
    AttendanceConfig config,
  ) {
    if (record == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Not marked today',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      );
    }

    if (record.status == AttendanceStatus.absent) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cancel_outlined,
                  size: 14,
                  color: Colors.grey.shade800,
                ),
                const SizedBox(width: 4),
                Text(
                  'Absent',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Present
    final timeStr = record.reportingTime?.toDisplayString() ?? '';
    final isLate = record.isLate(config);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLate ? Colors.amber.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isLate ? Colors.amber.shade700 : Colors.green.shade700,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLate ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            size: 14,
            color: isLate ? Colors.amber.shade900 : Colors.green.shade900,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              isLate ? 'Present · $timeStr · LATE' : 'Present · $timeStr',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isLate ? Colors.amber.shade900 : Colors.green.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}