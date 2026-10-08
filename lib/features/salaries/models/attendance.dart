import 'attendance_config.dart';
import 'reporting_time.dart';

enum AttendanceStatus {
  present,
  absent;

  String get value => name;

  static AttendanceStatus fromString(String value) {
    return value.toLowerCase() == 'present'
        ? AttendanceStatus.present
        : AttendanceStatus.absent;
  }
}

class Attendance {
  final String id;
  final String employeeId;
  final String date; // YYYY-MM-DD
  final AttendanceStatus status;
  final ReportingTime? reportingTime;

  const Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.reportingTime,
  });

  /// An employee is late if marked Present and reporting time is strictly after the standard reporting time.
  /// Absent is NEVER late.
  bool isLate([AttendanceConfig config = AttendanceConfig.defaultConfig]) {
    if (status != AttendanceStatus.present || reportingTime == null) {
      return false;
    }
    return reportingTime!.isAfter(config.standardReportingTime);
  }

  /// An employee is on time if marked Present and reporting time is at or before standard reporting time.
  bool isOnTime([AttendanceConfig config = AttendanceConfig.defaultConfig]) {
    if (status != AttendanceStatus.present || reportingTime == null) {
      return false;
    }
    return reportingTime!.isAtOrBefore(config.standardReportingTime);
  }

  String displayStatus([AttendanceConfig config = AttendanceConfig.defaultConfig]) {
    if (status == AttendanceStatus.absent) {
      return 'Absent';
    }
    return isLate(config) ? 'Late' : 'On Time';
  }

  Attendance copyWith({
    String? id,
    String? employeeId,
    String? date,
    AttendanceStatus? status,
    ReportingTime? reportingTime,
    bool clearReportingTime = false,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      status: status ?? this.status,
      reportingTime:
          clearReportingTime ? null : (reportingTime ?? this.reportingTime),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date,
      'status': status.value,
      'reportingTime': reportingTime?.to24HourString(),
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      date: json['date'] as String,
      status: AttendanceStatus.fromString(json['status'] as String),
      reportingTime: ReportingTime.tryParse(json['reportingTime'] as String?),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Attendance &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            employeeId == other.employeeId &&
            date == other.date &&
            status == other.status &&
            reportingTime == other.reportingTime;
  }

  @override
  int get hashCode => Object.hash(
        id,
        employeeId,
        date,
        status,
        reportingTime,
      );

  @override
  String toString() {
    return 'Attendance('
        'id: $id, '
        'employeeId: $employeeId, '
        'date: $date, '
        'status: ${status.name}, '
        'reportingTime: $reportingTime'
        ')';
  }
}
