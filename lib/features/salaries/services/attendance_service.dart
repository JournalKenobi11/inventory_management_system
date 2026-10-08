import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/id_generator.dart';
import '../models/attendance.dart';
import '../models/attendance_config.dart';
import '../models/employee_attendance_summary.dart';
import '../models/reporting_time.dart';
import '../repositories/interfaces/attendance_repository.dart';
import '../repositories/interfaces/employee_repository.dart';

class AttendanceService {
  final EmployeeRepository employeeRepository;
  final AttendanceRepository attendanceRepository;
  final AttendanceConfig config;

  AttendanceService(
    this.employeeRepository,
    this.attendanceRepository, {
    this.config = AttendanceConfig.defaultConfig,
  });

  /// Formats a DateTime as YYYY-MM-DD
  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Returns today's date formatted as YYYY-MM-DD
  static String todayDate() => formatDate(DateTime.now());

  /// Records attendance for an employee on a given date.
  /// If a record already exists for (employeeId, date), updates it automatically.
  Future<Attendance> recordAttendance({
    required String employeeId,
    required String date,
    required AttendanceStatus status,
    ReportingTime? reportingTime,
  }) async {
    final cleanEmpId = employeeId.trim();
    if (cleanEmpId.isEmpty) {
      throw ValidationException('Employee ID cannot be empty.');
    }

    final employee = await employeeRepository.getById(cleanEmpId);
    if (employee == null) {
      throw NotFoundException('Employee', cleanEmpId);
    }

    final cleanDate = date.trim();
    _validateDateFormat(cleanDate);

    ReportingTime? effectiveReportingTime;
    if (status == AttendanceStatus.present) {
      if (reportingTime == null) {
        throw ValidationException(
          'Reporting time is required when marking Present.',
        );
      }
      effectiveReportingTime = reportingTime;
    } else {
      // For Absent, reporting time must be null and does not count as late
      effectiveReportingTime = null;
    }

    final existing = await attendanceRepository.getByEmployeeAndDate(
      cleanEmpId,
      cleanDate,
    );

    if (existing != null) {
      final updated = existing.copyWith(
        status: status,
        reportingTime: effectiveReportingTime,
        clearReportingTime: status == AttendanceStatus.absent,
      );
      await attendanceRepository.update(updated);
      return updated;
    }

    final newAttendance = Attendance(
      id: IdGenerator.generate(),
      employeeId: cleanEmpId,
      date: cleanDate,
      status: status,
      reportingTime: effectiveReportingTime,
    );

    return attendanceRepository.create(newAttendance);
  }

  /// Updates an existing attendance record.
  Future<void> updateAttendance(Attendance attendance) async {
    final existing = await attendanceRepository.getById(attendance.id);
    if (existing == null) {
      throw NotFoundException('Attendance', attendance.id);
    }

    if (attendance.status == AttendanceStatus.present &&
        attendance.reportingTime == null) {
      throw ValidationException(
        'Reporting time is required when marking Present.',
      );
    }

    final effectiveReportingTime = attendance.status == AttendanceStatus.present
        ? attendance.reportingTime
        : null;

    final updated = attendance.copyWith(
      reportingTime: effectiveReportingTime,
      clearReportingTime: attendance.status == AttendanceStatus.absent,
    );

    await attendanceRepository.update(updated);
  }

  /// Retrieves today's attendance for a specific employee.
  Future<Attendance?> getTodayAttendance(String employeeId, {String? date}) {
    final targetDate = date ?? todayDate();
    return attendanceRepository.getByEmployeeAndDate(employeeId, targetDate);
  }

  /// Retrieves today's attendance for all employees as a Map of employeeId -> Attendance.
  /// Executes a single SQL query.
  Future<Map<String, Attendance>> getTodayAttendanceForAll({
    String? date,
  }) async {
    final targetDate = date ?? todayDate();
    final records = await attendanceRepository.getByDate(targetDate);
    return {for (final record in records) record.employeeId: record};
  }

  /// Returns attendance history for an employee in reverse chronological order.
  Future<List<Attendance>> getEmployeeHistory(
    String employeeId, {
    String? startDate,
    String? endDate,
  }) async {
    final employee = await employeeRepository.getById(employeeId);
    if (employee == null) {
      throw NotFoundException('Employee', employeeId);
    }

    return attendanceRepository.getByEmployeeAndDateRange(
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Calculates summary statistics (present, absent, late, onTime) for an employee in a given period.
  Future<EmployeeAttendanceSummary> getEmployeeSummary(
    String employeeId, {
    String? startDate,
    String? endDate,
  }) async {
    final records = await attendanceRepository.getByEmployeeAndDateRange(
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
    );

    return EmployeeAttendanceSummary.fromRecords(
      employeeId: employeeId,
      records: records,
      config: config,
    );
  }

  /// Efficiently calculates attendance summaries for all employees in a single batch query.
  /// Avoids N+1 database queries on the employee list screen.
  Future<Map<String, EmployeeAttendanceSummary>> getSummariesForPeriod({
    List<String>? employeeIds,
    String? startDate,
    String? endDate,
  }) async {
    final allRecords = await attendanceRepository.getByDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    // Group records by employeeId
    final recordsByEmp = <String, List<Attendance>>{};
    for (final record in allRecords) {
      recordsByEmp.putIfAbsent(record.employeeId, () => []).add(record);
    }

    // Determine target employee IDs
    final targetIds = employeeIds ??
        (await employeeRepository.getAll()).map((e) => e.id).toList();

    final result = <String, EmployeeAttendanceSummary>{};
    for (final id in targetIds) {
      final records = recordsByEmp[id] ?? const [];
      result[id] = EmployeeAttendanceSummary.fromRecords(
        employeeId: id,
        records: records,
        config: config,
      );
    }

    return result;
  }

  /// Deletes an attendance record by ID.
  Future<void> deleteAttendance(String id) async {
    final existing = await attendanceRepository.getById(id);
    if (existing == null) {
      throw NotFoundException('Attendance', id);
    }
    await attendanceRepository.delete(id);
  }

  void _validateDateFormat(String date) {
    final regExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regExp.hasMatch(date)) {
      throw ValidationException(
        'Date must be in YYYY-MM-DD format (received: "$date").',
      );
    }
    try {
      DateTime.parse(date);
    } catch (_) {
      throw ValidationException('Invalid date: "$date".');
    }
  }
}
