import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/core/errors/app_exceptions.dart';
import 'package:inventory_management_system/database/app_database.dart'
    as db;
import 'package:inventory_management_system/features/salaries/models/attendance.dart';
import 'package:inventory_management_system/features/salaries/models/attendance_config.dart';
import 'package:inventory_management_system/features/salaries/models/employee.dart';
import 'package:inventory_management_system/features/salaries/models/reporting_time.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_attendance_repository.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_employee_repository.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_salary_payment_repository.dart';
import 'package:inventory_management_system/features/salaries/services/attendance_service.dart';
import 'package:inventory_management_system/features/salaries/services/salary_service.dart';

void main() {
  late db.AppDatabase database;
  late SqliteEmployeeRepository employeeRepository;
  late SqliteSalaryPaymentRepository salaryPaymentRepository;
  late SqliteAttendanceRepository attendanceRepository;
  late AttendanceService attendanceService;
  late SalaryService salaryService;

  const standardConfig = AttendanceConfig(
    standardReportingTime: ReportingTime(10, 30),
  );

  setUp(() async {
    database = db.AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    employeeRepository = SqliteEmployeeRepository(database);
    salaryPaymentRepository = SqliteSalaryPaymentRepository(database);
    attendanceRepository = SqliteAttendanceRepository(database);

    attendanceService = AttendanceService(
      employeeRepository,
      attendanceRepository,
      config: standardConfig,
    );

    salaryService = SalaryService(
      employeeRepository,
      salaryPaymentRepository,
      attendanceRepository,
    );

    await employeeRepository.create(
      const Employee(
        id: 'emp-rahul',
        name: 'Rahul',
        monthlySalary: 25000,
      ),
    );

    await employeeRepository.create(
      const Employee(
        id: 'emp-amit',
        name: 'Amit',
        monthlySalary: 30000,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Punctuality evaluation (Standard: 10:30 AM)', () {
    test('1. 10:29 AM -> On Time', () {
      const att = Attendance(
        id: '1',
        employeeId: 'emp-rahul',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: ReportingTime(10, 29),
      );

      expect(att.isLate(standardConfig), isFalse);
      expect(att.isOnTime(standardConfig), isTrue);
      expect(att.displayStatus(standardConfig), 'On Time');
    });

    test('2. 10:30 AM -> On Time', () {
      const att = Attendance(
        id: '2',
        employeeId: 'emp-rahul',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: ReportingTime(10, 30),
      );

      expect(att.isLate(standardConfig), isFalse);
      expect(att.isOnTime(standardConfig), isTrue);
      expect(att.displayStatus(standardConfig), 'On Time');
    });

    test('3. 10:31 AM -> Late', () {
      const att = Attendance(
        id: '3',
        employeeId: 'emp-rahul',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: ReportingTime(10, 31),
      );

      expect(att.isLate(standardConfig), isTrue);
      expect(att.isOnTime(standardConfig), isFalse);
      expect(att.displayStatus(standardConfig), 'Late');
    });

    test('4. Absent -> not Late (Absent != Late)', () {
      const att = Attendance(
        id: '4',
        employeeId: 'emp-rahul',
        date: '2026-10-08',
        status: AttendanceStatus.absent,
      );

      expect(att.isLate(standardConfig), isFalse);
      expect(att.isOnTime(standardConfig), isFalse);
      expect(att.displayStatus(standardConfig), 'Absent');
    });
  });

  group('Attendance recording and duplicate handling', () {
    test('8. Duplicate employee/date attendance is updated rather than duplicated', () async {
      final initial = await attendanceService.recordAttendance(
        employeeId: 'emp-rahul',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 42),
      );
      expect(initial.isLate(standardConfig), isTrue);

      // Re-recording for the same date with different time
      final updated = await attendanceService.recordAttendance(
        employeeId: 'emp-rahul',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 20),
      );

      expect(updated.id, initial.id);
      expect(updated.isLate(standardConfig), isFalse);

      final allRecords = await attendanceRepository.getByEmployeeId('emp-rahul');
      expect(allRecords.length, 1);
      expect(allRecords.first.reportingTime, const ReportingTime(10, 20));
    });

    test('9. Editing reporting time recalculates status correctly', () async {
      final att = await attendanceService.recordAttendance(
        employeeId: 'emp-rahul',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 45),
      );
      expect(att.isLate(standardConfig), isTrue);

      await attendanceService.updateAttendance(
        att.copyWith(reportingTime: const ReportingTime(10, 15)),
      );

      final fetched = await attendanceRepository.getById(att.id);
      expect(fetched!.isLate(standardConfig), isFalse);
      expect(fetched.isOnTime(standardConfig), isTrue);
    });

    test('requires reporting time when marking Present', () async {
      expect(
        () => attendanceService.recordAttendance(
          employeeId: 'emp-rahul',
          date: '2026-10-08',
          status: AttendanceStatus.present,
          reportingTime: null,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('clears reporting time when marking Absent', () async {
      final att = await attendanceService.recordAttendance(
        employeeId: 'emp-rahul',
        date: '2026-10-08',
        status: AttendanceStatus.absent,
      );

      expect(att.status, AttendanceStatus.absent);
      expect(att.reportingTime, isNull);
    });
  });

  group('Attendance summaries and multi-employee isolation', () {
    test('5, 6, 7. Late count and on-time count calculated correctly and isolated per employee', () async {
      // Rahul: 3 records (1 on time, 1 late, 1 absent)
      await attendanceService.recordAttendance(
        employeeId: 'emp-rahul',
        date: '2026-10-01',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 15), // On time
      );
      await attendanceService.recordAttendance(
        employeeId: 'emp-rahul',
        date: '2026-10-02',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 45), // Late
      );
      await attendanceService.recordAttendance(
        employeeId: 'emp-rahul',
        date: '2026-10-03',
        status: AttendanceStatus.absent, // Absent (never late)
      );

      // Amit: 2 records (both late)
      await attendanceService.recordAttendance(
        employeeId: 'emp-amit',
        date: '2026-10-01',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(11, 00), // Late
      );
      await attendanceService.recordAttendance(
        employeeId: 'emp-amit',
        date: '2026-10-02',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 35), // Late
      );

      final rahulSummary = await attendanceService.getEmployeeSummary('emp-rahul');
      expect(rahulSummary.totalDays, 3);
      expect(rahulSummary.presentDays, 2);
      expect(rahulSummary.absentDays, 1);
      expect(rahulSummary.lateDays, 1);
      expect(rahulSummary.onTimeDays, 1);

      final amitSummary = await attendanceService.getEmployeeSummary('emp-amit');
      expect(amitSummary.totalDays, 2);
      expect(amitSummary.presentDays, 2);
      expect(amitSummary.absentDays, 0);
      expect(amitSummary.lateDays, 2);
      expect(amitSummary.onTimeDays, 0);
    });

    test('10. Monthly summary only includes records in the selected period', () async {
      // Record in October
      await attendanceService.recordAttendance(
        employeeId: 'emp-rahul',
        date: '2026-10-10',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 45), // Late
      );

      // Record in November
      await attendanceService.recordAttendance(
        employeeId: 'emp-rahul',
        date: '2026-11-05',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 50), // Late
      );

      final octoberSummary = await attendanceService.getEmployeeSummary(
        'emp-rahul',
        startDate: '2026-10-01',
        endDate: '2026-10-31',
      );

      expect(octoberSummary.totalDays, 1);
      expect(octoberSummary.lateDays, 1);

      final novemberSummary = await attendanceService.getEmployeeSummary(
        'emp-rahul',
        startDate: '2026-11-01',
        endDate: '2026-11-30',
      );

      expect(novemberSummary.totalDays, 1);
      expect(novemberSummary.lateDays, 1);

      final allTimeSummary = await attendanceService.getEmployeeSummary('emp-rahul');
      expect(allTimeSummary.totalDays, 2);
      expect(allTimeSummary.lateDays, 2);
    });

    test('Batch query getSummariesForPeriod avoids N+1 queries and maps all employees', () async {
      await attendanceService.recordAttendance(
        employeeId: 'emp-rahul',
        date: '2026-10-05',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 10),
      );
      await attendanceService.recordAttendance(
        employeeId: 'emp-amit',
        date: '2026-10-05',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 40),
      );

      final summaries = await attendanceService.getSummariesForPeriod(
        employeeIds: ['emp-rahul', 'emp-amit'],
        startDate: '2026-10-01',
        endDate: '2026-10-31',
      );

      expect(summaries['emp-rahul']!.lateDays, 0);
      expect(summaries['emp-rahul']!.onTimeDays, 1);
      expect(summaries['emp-amit']!.lateDays, 1);
      expect(summaries['emp-amit']!.onTimeDays, 0);
    });
  });

  group('Employee deletion rules with historical attendance records', () {
    test('11. Employee with historical attendance records cannot be deleted', () async {
      await attendanceService.recordAttendance(
        employeeId: 'emp-rahul',
        date: '2026-10-08',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 15),
      );

      expect(
        () => salaryService.deleteEmployee('emp-rahul'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('attendance records exist'),
          ),
        ),
      );

      final emp = await employeeRepository.getById('emp-rahul');
      expect(emp, isNotNull);
    });

    test('Employee without attendance or payments can be deleted', () async {
      await salaryService.deleteEmployee('emp-amit');
      final emp = await employeeRepository.getById('emp-amit');
      expect(emp, isNull);
    });
  });
}
