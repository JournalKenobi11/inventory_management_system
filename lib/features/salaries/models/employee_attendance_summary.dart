import 'attendance.dart';
import 'attendance_config.dart';

class EmployeeAttendanceSummary {
  final String employeeId;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int onTimeDays;

  const EmployeeAttendanceSummary({
    required this.employeeId,
    this.totalDays = 0,
    this.presentDays = 0,
    this.absentDays = 0,
    this.lateDays = 0,
    this.onTimeDays = 0,
  });

  factory EmployeeAttendanceSummary.fromRecords({
    required String employeeId,
    required Iterable<Attendance> records,
    AttendanceConfig config = AttendanceConfig.defaultConfig,
  }) {
    var present = 0;
    var absent = 0;
    var late = 0;
    var onTime = 0;

    for (final record in records) {
      if (record.status == AttendanceStatus.present) {
        present++;
        if (record.isLate(config)) {
          late++;
        } else {
          onTime++;
        }
      } else if (record.status == AttendanceStatus.absent) {
        absent++;
      }
    }

    return EmployeeAttendanceSummary(
      employeeId: employeeId,
      totalDays: present + absent,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      onTimeDays: onTime,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EmployeeAttendanceSummary &&
            runtimeType == other.runtimeType &&
            employeeId == other.employeeId &&
            totalDays == other.totalDays &&
            presentDays == other.presentDays &&
            absentDays == other.absentDays &&
            lateDays == other.lateDays &&
            onTimeDays == other.onTimeDays;
  }

  @override
  int get hashCode => Object.hash(
        employeeId,
        totalDays,
        presentDays,
        absentDays,
        lateDays,
        onTimeDays,
      );

  @override
  String toString() {
    return 'EmployeeAttendanceSummary('
        'employeeId: $employeeId, '
        'totalDays: $totalDays, '
        'present: $presentDays, '
        'absent: $absentDays, '
        'late: $lateDays, '
        'onTime: $onTimeDays'
        ')';
  }
}
