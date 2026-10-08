import '../../models/attendance.dart';

abstract class AttendanceRepository {
  Future<Attendance> create(Attendance attendance);

  Future<void> update(Attendance attendance);

  Future<Attendance?> getById(String id);

  Future<Attendance?> getByEmployeeAndDate(String employeeId, String date);

  Future<List<Attendance>> getByEmployeeId(String employeeId);

  Future<List<Attendance>> getByDate(String date);

  Future<List<Attendance>> getByDateRange({
    String? startDate,
    String? endDate,
  });

  Future<List<Attendance>> getByEmployeeAndDateRange({
    required String employeeId,
    String? startDate,
    String? endDate,
  });

  Future<void> delete(String id);
}
