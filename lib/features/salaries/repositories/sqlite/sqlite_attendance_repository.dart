import 'package:drift/drift.dart';

import '../../../../database/app_database.dart' as db;
import '../../models/attendance.dart';
import '../../models/reporting_time.dart';
import '../interfaces/attendance_repository.dart';

class SqliteAttendanceRepository implements AttendanceRepository {
  final db.AppDatabase database;

  SqliteAttendanceRepository(this.database);

  @override
  Future<Attendance> create(Attendance attendance) async {
    await database.into(database.attendances).insert(
          db.AttendancesCompanion.insert(
            id: attendance.id,
            employeeId: attendance.employeeId,
            date: attendance.date,
            status: attendance.status.value,
            reportingTime: Value(attendance.reportingTime?.to24HourString()),
          ),
        );

    return attendance;
  }

  @override
  Future<void> update(Attendance attendance) async {
    await (database.update(database.attendances)
          ..where((tbl) => tbl.id.equals(attendance.id)))
        .write(
      db.AttendancesCompanion(
        status: Value(attendance.status.value),
        reportingTime: Value(attendance.reportingTime?.to24HourString()),
      ),
    );
  }

  @override
  Future<Attendance?> getById(String id) async {
    final query = database.select(database.attendances)
      ..where((tbl) => tbl.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<Attendance?> getByEmployeeAndDate(
      String employeeId, String date) async {
    final query = database.select(database.attendances)
      ..where((tbl) =>
          tbl.employeeId.equals(employeeId) & tbl.date.equals(date));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<List<Attendance>> getByEmployeeId(String employeeId) async {
    final query = database.select(database.attendances)
      ..where((tbl) => tbl.employeeId.equals(employeeId))
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.date,
              mode: OrderingMode.desc,
            ),
      ]);

    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Attendance>> getByDate(String date) async {
    final query = database.select(database.attendances)
      ..where((tbl) => tbl.date.equals(date))
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.employeeId,
              mode: OrderingMode.asc,
            ),
      ]);

    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Attendance>> getByDateRange({
    String? startDate,
    String? endDate,
  }) async {
    final query = database.select(database.attendances);

    if (startDate != null && endDate != null) {
      query.where((tbl) =>
          tbl.date.isBiggerOrEqualValue(startDate) &
          tbl.date.isSmallerOrEqualValue(endDate));
    } else if (startDate != null) {
      query.where((tbl) => tbl.date.isBiggerOrEqualValue(startDate));
    } else if (endDate != null) {
      query.where((tbl) => tbl.date.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([
      (tbl) => OrderingTerm(
            expression: tbl.date,
            mode: OrderingMode.desc,
          ),
    ]);

    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Attendance>> getByEmployeeAndDateRange({
    required String employeeId,
    String? startDate,
    String? endDate,
  }) async {
    final query = database.select(database.attendances)
      ..where((tbl) => tbl.employeeId.equals(employeeId));

    if (startDate != null && endDate != null) {
      query.where((tbl) =>
          tbl.date.isBiggerOrEqualValue(startDate) &
          tbl.date.isSmallerOrEqualValue(endDate));
    } else if (startDate != null) {
      query.where((tbl) => tbl.date.isBiggerOrEqualValue(startDate));
    } else if (endDate != null) {
      query.where((tbl) => tbl.date.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([
      (tbl) => OrderingTerm(
            expression: tbl.date,
            mode: OrderingMode.desc,
          ),
    ]);

    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(database.attendances)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Attendance _toModel(db.Attendance row) {
    return Attendance(
      id: row.id,
      employeeId: row.employeeId,
      date: row.date,
      status: AttendanceStatus.fromString(row.status),
      reportingTime: ReportingTime.tryParse(row.reportingTime),
    );
  }
}
