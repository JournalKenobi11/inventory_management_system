import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/database/app_database.dart'
    as db;
import 'package:inventory_management_system/features/salaries/models/attendance.dart';
import 'package:inventory_management_system/features/salaries/models/employee.dart';
import 'package:inventory_management_system/features/salaries/models/reporting_time.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_attendance_repository.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_employee_repository.dart';

void main() {
  late db.AppDatabase database;
  late SqliteEmployeeRepository employeeRepository;
  late SqliteAttendanceRepository attendanceRepository;

  setUp(() async {
    database = db.AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    employeeRepository = SqliteEmployeeRepository(database);
    attendanceRepository = SqliteAttendanceRepository(database);

    await employeeRepository.create(
      const Employee(
        id: 'emp-1',
        name: 'Rahul',
        monthlySalary: 25000,
      ),
    );

    await employeeRepository.create(
      const Employee(
        id: 'emp-2',
        name: 'Amit',
        monthlySalary: 30000,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and retrieves attendance record', () async {
    const attendance = Attendance(
      id: 'att-1',
      employeeId: 'emp-1',
      date: '2026-10-08',
      status: AttendanceStatus.present,
      reportingTime: ReportingTime(10, 18),
    );

    final created = await attendanceRepository.create(attendance);
    expect(created, equals(attendance));

    final fetched = await attendanceRepository.getById('att-1');
    expect(fetched, isNotNull);
    expect(fetched!.employeeId, 'emp-1');
    expect(fetched.date, '2026-10-08');
    expect(fetched.status, AttendanceStatus.present);
    expect(fetched.reportingTime, const ReportingTime(10, 18));
  });

  test('retrieves attendance by employee and date', () async {
    await attendanceRepository.create(
      const Attendance(
        id: 'att-1',
        employeeId: 'emp-1',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: ReportingTime(10, 25),
      ),
    );

    final record = await attendanceRepository.getByEmployeeAndDate(
      'emp-1',
      '2026-10-08',
    );
    expect(record, isNotNull);
    expect(record!.id, 'att-1');

    final nonExistent = await attendanceRepository.getByEmployeeAndDate(
      'emp-1',
      '2026-10-09',
    );
    expect(nonExistent, isNull);
  });

  test('updates attendance record', () async {
    await attendanceRepository.create(
      const Attendance(
        id: 'att-1',
        employeeId: 'emp-1',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: ReportingTime(10, 50),
      ),
    );

    await attendanceRepository.update(
      const Attendance(
        id: 'att-1',
        employeeId: 'emp-1',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: ReportingTime(10, 20),
      ),
    );

    final updated = await attendanceRepository.getById('att-1');
    expect(updated!.reportingTime, const ReportingTime(10, 20));
  });

  test('filters by date range and employee', () async {
    await attendanceRepository.create(
      const Attendance(
        id: 'att-1',
        employeeId: 'emp-1',
        date: '2026-10-01',
        status: AttendanceStatus.present,
        reportingTime: ReportingTime(10, 15),
      ),
    );

    await attendanceRepository.create(
      const Attendance(
        id: 'att-2',
        employeeId: 'emp-1',
        date: '2026-10-15',
        status: AttendanceStatus.present,
        reportingTime: ReportingTime(10, 45),
      ),
    );

    await attendanceRepository.create(
      const Attendance(
        id: 'att-3',
        employeeId: 'emp-1',
        date: '2026-11-01',
        status: AttendanceStatus.absent,
      ),
    );

    final octoberRecords =
        await attendanceRepository.getByEmployeeAndDateRange(
      employeeId: 'emp-1',
      startDate: '2026-10-01',
      endDate: '2026-10-31',
    );

    expect(octoberRecords.length, 2);
    expect(octoberRecords.map((r) => r.id).toList(), ['att-2', 'att-1']);
  });

  test('retrieves all attendances for a single date', () async {
    await attendanceRepository.create(
      const Attendance(
        id: 'att-1',
        employeeId: 'emp-1',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: ReportingTime(10, 15),
      ),
    );

    await attendanceRepository.create(
      const Attendance(
        id: 'att-2',
        employeeId: 'emp-2',
        date: '2026-10-08',
        status: AttendanceStatus.absent,
      ),
    );

    final records = await attendanceRepository.getByDate('2026-10-08');
    expect(records.length, 2);
    expect(records.map((r) => r.employeeId).toSet(), {'emp-1', 'emp-2'});
  });

  test('deletes attendance record', () async {
    await attendanceRepository.create(
      const Attendance(
        id: 'att-1',
        employeeId: 'emp-1',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: ReportingTime(10, 15),
      ),
    );

    await attendanceRepository.delete('att-1');
    final fetched = await attendanceRepository.getById('att-1');
    expect(fetched, isNull);
  });
}
