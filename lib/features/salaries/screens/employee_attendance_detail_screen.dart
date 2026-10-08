import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance.dart';
import '../models/attendance_config.dart';
import '../models/attendance_period.dart';
import '../models/employee.dart';
import '../models/employee_attendance_summary.dart';
import '../providers/salary_provider.dart';
import 'record_attendance_dialog.dart';

class EmployeeAttendanceDetailScreen extends ConsumerStatefulWidget {
  final Employee employee;

  const EmployeeAttendanceDetailScreen({
    super.key,
    required this.employee,
  });

  @override
  ConsumerState<EmployeeAttendanceDetailScreen> createState() =>
      _EmployeeAttendanceDetailScreenState();
}

class _EmployeeAttendanceDetailScreenState
    extends ConsumerState<EmployeeAttendanceDetailScreen> {
  AttendancePeriod _selectedPeriod = AttendancePeriod.thisMonth;

  Future<void> _editRecord(Attendance record) async {
    final updated = await RecordAttendanceDialog.show(
      context,
      employee: widget.employee,
      existingAttendance: record,
    );
    if (updated == true) {
      setState(() {});
    }
  }

  Future<void> _deleteRecord(Attendance record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Attendance Record'),
        content: Text('Delete attendance record for ${record.date}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(attendanceServiceProvider).deleteAttendance(record.id);
      ref.invalidate(todayAttendanceMapProvider);
      ref.invalidate(employeeAttendanceSummariesProvider);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance record deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(attendanceServiceProvider);
    final config = ref.watch(attendanceConfigProvider);
    final range = _selectedPeriod.getDateRange();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee.name),
      ),
      body: FutureBuilder<List<Attendance>>(
        future: service.getEmployeeHistory(
          widget.employee.id,
          startDate: range.startDate,
          endDate: range.endDate,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          final records = snapshot.data ?? [];
          final summary = EmployeeAttendanceSummary.fromRecords(
            employeeId: widget.employee.id,
            records: records,
            config: config,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Employee Info Banner
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          widget.employee.name.isNotEmpty
                              ? widget.employee.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.employee.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Monthly Salary: ₹${widget.employee.monthlySalary.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Standard Reporting: ${config.standardReportingTime.toDisplayString()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Period Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Period',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  DropdownButton<AttendancePeriod>(
                    value: _selectedPeriod,
                    underline: const SizedBox(),
                    items: AttendancePeriod.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPeriod = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Attendance Summary Card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Attendance Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedPeriod.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          _buildSummaryItem(
                            'Total Days',
                            '${summary.totalDays}',
                            Colors.blueGrey,
                          ),
                          _buildSummaryItem(
                            'Present',
                            '${summary.presentDays}',
                            Colors.blue,
                          ),
                          _buildSummaryItem(
                            'Absent',
                            '${summary.absentDays}',
                            Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildSummaryItem(
                            'Late Days',
                            '${summary.lateDays}',
                            Colors.amber.shade800,
                            isHighlighted: summary.lateDays > 0,
                          ),
                          _buildSummaryItem(
                            'On Time',
                            '${summary.onTimeDays}',
                            Colors.green.shade700,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Attendance History Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendance History (${records.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Mark Date'),
                    onPressed: () async {
                      final updated = await RecordAttendanceDialog.show(
                        context,
                        employee: widget.employee,
                      );
                      if (updated == true) {
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Attendance History List
              if (records.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No attendance records found for ${_selectedPeriod.label.toLowerCase()}.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                ...records.map((rec) {
                  final isLate = rec.isLate(config);
                  final isAbsent = rec.status == AttendanceStatus.absent;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAbsent
                            ? Colors.grey.shade200
                            : isLate
                                ? Colors.amber.shade100
                                : Colors.green.shade100,
                        child: Icon(
                          isAbsent
                              ? Icons.cancel_outlined
                              : isLate
                                  ? Icons.access_time_filled_rounded
                                  : Icons.check_circle_rounded,
                          color: isAbsent
                              ? Colors.grey.shade700
                              : isLate
                                  ? Colors.amber.shade900
                                  : Colors.green.shade800,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            rec.date,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(rec, config),
                        ],
                      ),
                      subtitle: Text(
                        isAbsent
                            ? 'Marked Absent'
                            : 'Reporting Time: ${rec.reportingTime?.toDisplayString() ?? "-"}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Edit Record',
                            onPressed: () => _editRecord(rec),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            tooltip: 'Delete Record',
                            onPressed: () => _deleteRecord(rec),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final updated = await RecordAttendanceDialog.show(
            context,
            employee: widget.employee,
          );
          if (updated == true) {
            setState(() {});
          }
        },
        icon: const Icon(Icons.how_to_reg_rounded),
        label: const Text('Mark Attendance'),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color, {
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.red.shade700 : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Attendance rec, AttendanceConfig config) {
    if (rec.status == AttendanceStatus.absent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'ABSENT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      );
    }

    final isLate = rec.isLate(config);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLate ? Colors.amber.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isLate ? Colors.amber.shade700 : Colors.green.shade700,
          width: 0.5,
        ),
      ),
      child: Text(
        isLate ? 'LATE' : 'ON TIME',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isLate ? Colors.amber.shade900 : Colors.green.shade900,
        ),
      ),
    );
  }
}
