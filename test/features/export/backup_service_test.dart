import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/core/errors/app_exceptions.dart';
import 'package:inventory_management_system/database/app_database.dart' hide Attendance;
import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_service_part_repository.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_service_repository.dart';
import 'package:inventory_management_system/features/customers/customers.dart';
import 'package:inventory_management_system/features/customers/repositories/sqlite/sqlite_customer_repository.dart';
import 'package:inventory_management_system/features/expenses/expenses.dart';
import 'package:inventory_management_system/features/expenses/repositories/sqlite/sqlite_expense_repository.dart';
import 'package:inventory_management_system/features/export/export.dart';
import 'package:inventory_management_system/features/export/repositories/sqlite/sqlite_backup_repository.dart';
import 'package:inventory_management_system/features/parts/parts.dart';
import 'package:inventory_management_system/features/parts/repositories/sqlite/sqlite_part_repository.dart';
import 'package:inventory_management_system/features/salaries/salaries.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_employee_repository.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_attendance_repository.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_salary_payment_repository.dart';

void main() {
  late AppDatabase database;
  late BackupService backupService;
  late CustomerService customerService;
  late PartService partService;
  late BillingService billingService;
  late ExpenseService expenseService;
  late SalaryService salaryService;
  late SqliteAttendanceRepository attendanceRepo;
  late SqliteServiceRepository serviceRepo;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    final customerRepo = SqliteCustomerRepository(database);
    final partRepo = SqlitePartRepository(database);
    serviceRepo = SqliteServiceRepository(database);
    final servicePartRepo = SqliteServicePartRepository(database);
    final invoiceRepo = SqliteInvoiceRepository(database);
    final expenseRepo = SqliteExpenseRepository(database);
    final employeeRepo = SqliteEmployeeRepository(database);
    final salaryPaymentRepo = SqliteSalaryPaymentRepository(database);
    attendanceRepo = SqliteAttendanceRepository(database);
    final backupRepo = SqliteBackupRepository(database);

    customerService = CustomerService(customerRepo);
    partService = PartService(partRepo);
    billingService = BillingService(
      serviceRepo,
      servicePartRepo,
      invoiceRepo,
      customerService,
      partService,
      database,
    );
    expenseService = ExpenseService(expenseRepo);
    salaryService = SalaryService(employeeRepo, salaryPaymentRepo, attendanceRepo);
    backupService = BackupService(backupRepo);
  });

  tearDown(() async {
    await database.close();
  });

  test('exports and restores complete database with high fidelity', () async {
    // 1. Seed database with real data
    final cust = await customerService.createCustomer(
      name: 'Ravi Teja',
      mobile: '9988776655',
      vehicleName: 'Tata Nexon',
    );

    final part = await partService.createPart(
      partNumber: 'NEX-FLT-01',
      partName: 'Air Filter',
      category: 'Filters',
      purchasePrice: 150.0,
      sellingPrice: 350.0,
      currentStock: 15,
      lowStockThreshold: 3,
    );

    final invoice = await billingService.billService(
      customerId: cust.id,
      problemDesc: 'Scheduled inspection',
      labourCharge: 250.0,
      partsUsed: [
        ServicePartInput(partId: part.id, quantity: 2),
      ],
    );

    final expense = await expenseService.createExpense(
      category: 'Electricity',
      isPersonal: false,
      amount: 450.0,
      note: 'Workshop bill',
    );

    final emp = await salaryService.createEmployee(
      name: 'Mahesh',
      monthlySalary: 12000.0,
    );

    final payment = await salaryService.recordPayment(
      employeeId: emp.id,
      amount: 6000.0,
      status: 'paid',
    );

    // 2. Export database to JSON
    final jsonString = await backupService.exportBackupJsonString();
    expect(jsonString.contains('Ravi Teja'), isTrue);
    expect(jsonString.contains('NEX-FLT-01'), isTrue);
    expect(jsonString.contains('Electricity'), isTrue);
    expect(jsonString.contains('Mahesh'), isTrue);

    // 3. Clear/modify current database to simulate fresh install or loss
    await database.delete(database.customers).go();
    await database.delete(database.parts).go();
    await database.delete(database.invoices).go();
    await database.delete(database.expenses).go();
    await database.delete(database.employees).go();

    expect(await customerService.getCustomers(), isEmpty);
    expect(await partService.getAllParts(), isEmpty);
    expect(await expenseService.getAllExpenses(), isEmpty);

    // 4. Restore from JSON
    final restoreResult = await backupService.restoreFromJson(jsonString);
    expect(restoreResult.success, isTrue);

    // 5. Verify restored data
    final restoredCustomers = await customerService.getCustomers();
    expect(restoredCustomers.length, equals(1));
    expect(restoredCustomers.first.name, equals('Ravi Teja'));
    expect(restoredCustomers.first.mobile, equals('9988776655'));

    final restoredParts = await partService.getAllParts();
    expect(restoredParts.length, equals(1));
    expect(restoredParts.first.partNumber, equals('NEX-FLT-01'));
    // Stock after 2 were billed: 15 - 2 = 13
    expect(restoredParts.first.currentStock, equals(13));

    final restoredInvoices = await billingService.getAllInvoices();
    expect(restoredInvoices.length, equals(1));
    expect(restoredInvoices.first.id, equals(invoice.id));
    expect(restoredInvoices.first.totalAmount, equals(invoice.totalAmount));

    final restoredExpenses = await expenseService.getAllExpenses();
    expect(restoredExpenses.length, equals(1));
    expect(restoredExpenses.first.id, equals(expense.id));
    expect(restoredExpenses.first.amount, equals(450.0));

    final restoredEmployees = await salaryService.getEmployees();
    expect(restoredEmployees.length, equals(1));
    expect(restoredEmployees.first.name, equals('Mahesh'));

    final restoredPayments = await salaryService.getSalaryPayments();
    expect(restoredPayments.length, equals(1));
    expect(restoredPayments.first.id, equals(payment.id));
    expect(restoredPayments.first.amount, equals(6000.0));
  });

  test('BUG-001 regression: exports and restores attendances and schema v4 serviceReport/labourEntries', () async {
    final cust = await customerService.createCustomer(
      name: 'Priya',
      mobile: '9848012345',
      vehicleName: 'Hyundai i20',
    );

    final part = await partService.createPart(
      partNumber: 'BRK-PAD-01',
      partName: 'Front Brake Pads',
      category: 'Brakes',
      purchasePrice: 400.0,
      sellingPrice: 750.0,
      currentStock: 10,
      lowStockThreshold: 2,
    );

    // Bill service with custom serviceReport and labourEntries (schema v4)
    final invoice = await billingService.billService(
      customerId: cust.id,
      problemDesc: 'Brake inspection and pad replacement',
      serviceReport: 'Front pads worn down to 2mm. Calipers cleaned and greased.',
      labourEntries: [
        const LabourEntry(description: 'Brake service labour', charge: 350.0),
        const LabourEntry(description: 'Wheel alignment inspection', charge: 150.0),
      ],
      partsUsed: [
        ServicePartInput(partId: part.id, quantity: 1),
      ],
    );

    final emp = await salaryService.createEmployee(
      name: 'Ramesh Mechanic',
      monthlySalary: 15000.0,
    );

    // Seed attendance
    await attendanceRepo.create(
      Attendance(
        id: 'att-1',
        employeeId: emp.id,
        date: '2026-10-10',
        status: AttendanceStatus.present,
        reportingTime: const ReportingTime(10, 15),
      ),
    );

    // Export database to JSON
    final jsonString = await backupService.exportBackupJsonString();
    expect(jsonString.contains('attendances'), isTrue);
    expect(jsonString.contains('serviceReport'), isTrue);
    expect(jsonString.contains('labourEntries'), isTrue);
    expect(jsonString.contains('Ramesh Mechanic'), isTrue);

    // Clear database
    await database.delete(database.attendances).go();
    await database.delete(database.serviceJobs).go();
    await database.delete(database.invoices).go();
    await database.delete(database.employees).go();

    expect(await attendanceRepo.getByEmployeeId(emp.id), isEmpty);
    expect(await billingService.getAllInvoices(), isEmpty);

    // Restore from JSON
    final restoreResult = await backupService.restoreFromJson(jsonString);
    expect(restoreResult.success, isTrue);

    // Verify attendances restored
    final restoredAttendance = await attendanceRepo.getByEmployeeId(emp.id);
    expect(restoredAttendance.length, equals(1));
    expect(restoredAttendance.first.employeeId, equals(emp.id));
    expect(restoredAttendance.first.status, equals(AttendanceStatus.present));
    expect(restoredAttendance.first.reportingTime?.to24HourString(), equals('10:15'));

    // Verify service job with serviceReport and labourEntries restored
    final restoredService = await serviceRepo.getById(invoice.serviceId);
    expect(restoredService, isNotNull);
    expect(restoredService!.serviceReport, equals('Front pads worn down to 2mm. Calipers cleaned and greased.'));
    expect(restoredService.labourEntries.length, equals(2));
    expect(restoredService.labourEntries.first.description, equals('Brake service labour'));
    expect(restoredService.labourEntries.first.charge, equals(350.0));
  });

  test('rejects invalid or corrupted backup payloads', () async {
    // Empty content
    expect(
      () => backupService.restoreFromJson(''),
      throwsA(isA<ValidationException>()),
    );

    // Invalid JSON
    expect(
      () => backupService.restoreFromJson('{ invalid json }'),
      throwsA(isA<ValidationException>()),
    );

    // Incompatible app identifier
    const wrongAppJson = '''
    {
      "app": "different_app",
      "version": 1,
      "exportDate": "2026-10-06T00:00:00.000Z",
      "data": {}
    }
    ''';
    expect(
      () => backupService.restoreFromJson(wrongAppJson),
      throwsA(isA<ValidationException>()),
    );
  });
}
