import 'reporting_time.dart';

/// Centralized configuration for employee attendance.
/// Standard reporting time defaults to 10:30 AM as per requirement.
class AttendanceConfig {
  final ReportingTime standardReportingTime;

  const AttendanceConfig({
    this.standardReportingTime = const ReportingTime(10, 30),
  });

  static const AttendanceConfig defaultConfig = AttendanceConfig();

  AttendanceConfig copyWith({
    ReportingTime? standardReportingTime,
  }) {
    return AttendanceConfig(
      standardReportingTime:
          standardReportingTime ?? this.standardReportingTime,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttendanceConfig &&
            runtimeType == other.runtimeType &&
            standardReportingTime == other.standardReportingTime;
  }

  @override
  int get hashCode => standardReportingTime.hashCode;

  @override
  String toString() =>
      'AttendanceConfig(standardReportingTime: $standardReportingTime)';
}
