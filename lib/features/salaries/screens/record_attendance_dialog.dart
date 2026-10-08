import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance.dart';
import '../models/employee.dart';
import '../models/reporting_time.dart';
import '../providers/salary_provider.dart';
import '../services/attendance_service.dart';

class RecordAttendanceDialog extends ConsumerStatefulWidget {
  final Employee? initialEmployee;
  final Attendance? existingAttendance;
  final String? initialDate;

  const RecordAttendanceDialog({
    super.key,
    this.initialEmployee,
    this.existingAttendance,
    this.initialDate,
  });

  static Future<bool?> show(
    BuildContext context, {
    Employee? employee,
    Attendance? existingAttendance,
    String? initialDate,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RecordAttendanceDialog(
        initialEmployee: employee,
        existingAttendance: existingAttendance,
        initialDate: initialDate,
      ),
    );
  }

  @override
  ConsumerState<RecordAttendanceDialog> createState() =>
      _RecordAttendanceDialogState();
}

class _RecordAttendanceDialogState
    extends ConsumerState<RecordAttendanceDialog> {
  Employee? _selectedEmployee;
  late DateTime _selectedDate;
  AttendanceStatus _status = AttendanceStatus.present;
  TimeOfDay _reportingTime = const TimeOfDay(hour: 10, minute: 15);
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = widget.initialEmployee;

    if (widget.existingAttendance != null) {
      final existing = widget.existingAttendance!;
      _selectedDate = DateTime.tryParse(existing.date) ?? DateTime.now();
      _status = existing.status;
      if (existing.reportingTime != null) {
        _reportingTime = TimeOfDay(
          hour: existing.reportingTime!.hour,
          minute: existing.reportingTime!.minute,
        );
      }
    } else {
      if (widget.initialDate != null) {
        _selectedDate =
            DateTime.tryParse(widget.initialDate!) ?? DateTime.now();
      } else {
        _selectedDate = DateTime.now();
      }
      final nowTime = TimeOfDay.now();
      _reportingTime = nowTime;
    }
  }

  Future<void> _checkExistingForDate(String empId, String dateStr) async {
    final service = ref.read(attendanceServiceProvider);
    final existing = await service.getTodayAttendance(empId, date: dateStr);
    if (existing != null && mounted) {
      setState(() {
        _status = existing.status;
        if (existing.reportingTime != null) {
          _reportingTime = TimeOfDay(
            hour: existing.reportingTime!.hour,
            minute: existing.reportingTime!.minute,
          );
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (_selectedEmployee != null) {
        final dateStr = AttendanceService.formatDate(picked);
        await _checkExistingForDate(_selectedEmployee!.id, dateStr);
      }
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reportingTime,
    );
    if (picked != null) {
      setState(() {
        _reportingTime = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_selectedEmployee == null) {
      setState(() {
        _errorMessage = 'Please select an employee.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final dateStr = AttendanceService.formatDate(_selectedDate);
      final reportingTimeModel = _status == AttendanceStatus.present
          ? ReportingTime(_reportingTime.hour, _reportingTime.minute)
          : null;

      final service = ref.read(attendanceServiceProvider);
      await service.recordAttendance(
        employeeId: _selectedEmployee!.id,
        date: dateStr,
        status: _status,
        reportingTime: reportingTimeModel,
      );

      // Invalidate attendance providers so UI updates immediately
      ref.invalidate(todayAttendanceMapProvider);
      ref.invalidate(employeeAttendanceSummariesProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance recorded for ${_selectedEmployee!.name} (${_status == AttendanceStatus.present ? (_reportingTime.hour * 60 + _reportingTime.minute > 10 * 60 + 30 ? "Late" : "On Time") : "Absent"}).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final config = ref.watch(attendanceConfigProvider);
    final standardTime = config.standardReportingTime;

    final selectedReporting =
        ReportingTime(_reportingTime.hour, _reportingTime.minute);
    final isLate = selectedReporting.isAfter(standardTime);

    final dateDisplay =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Text(widget.existingAttendance != null
          ? 'Edit Attendance'
          : 'Record Attendance'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
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
                const SizedBox(height: 12),
              ],

              // Employee Selection
              if (widget.initialEmployee != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(
                    widget.initialEmployee!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Monthly salary: ₹${widget.initialEmployee!.monthlySalary.toStringAsFixed(2)}',
                  ),
                ),
              ] else ...[
                employeesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading employees: $e'),
                  data: (employees) {
                    if (employees.isEmpty) {
                      return const Text('No employees found.');
                    }
                    return DropdownButtonFormField<Employee>(
                      initialValue: _selectedEmployee ?? employees.first,
                      decoration: const InputDecoration(
                        labelText: 'Employee',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: employees.map((emp) {
                        return DropdownMenuItem(
                          value: emp,
                          child: Text(emp.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedEmployee = val;
                        });
                        if (val != null) {
                          final dateStr =
                              AttendanceService.formatDate(_selectedDate);
                          _checkExistingForDate(val.id, dateStr);
                        }
                      },
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),

              // Date Picker Field
              InkWell(
                onTap: _saving ? null : _selectDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(
                    dateDisplay,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Selector: Present / Absent
              const Text(
                'Attendance Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<AttendanceStatus>(
                segments: const [
                  ButtonSegment(
                    value: AttendanceStatus.present,
                    icon: Icon(Icons.check_circle_outline),
                    label: Text('Present'),
                  ),
                  ButtonSegment(
                    value: AttendanceStatus.absent,
                    icon: Icon(Icons.cancel_outlined),
                    label: Text('Absent'),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (set) {
                  setState(() {
                    _status = set.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Reporting Time if Present
              if (_status == AttendanceStatus.present) ...[
                const Text(
                  'Reporting Time',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _saving ? null : _selectTime,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Actual Time of Arrival',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time_rounded),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedReporting.toDisplayString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.edit, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Automatic Punctuality Calculation Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLate
                        ? Colors.amber.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLate
                          ? Colors.amber.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLate
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_rounded,
                        color: isLate
                            ? Colors.amber.shade900
                            : Colors.green.shade900,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isLate
                              ? 'LATE (Reporting after ${standardTime.toDisplayString()})'
                              : 'ON TIME (Standard: ${standardTime.toDisplayString()})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLate
                                ? Colors.amber.shade900
                                : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Marked Absent. Reporting time not required and does not count as late.',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Attendance'),
        ),
      ],
    );
  }
}
