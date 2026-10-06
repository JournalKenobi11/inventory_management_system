import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_service_part_repository.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_service_repository.dart';
import 'package:inventory_management_system/features/customers/customers.dart';
import 'package:inventory_management_system/features/customers/repositories/sqlite/sqlite_customer_repository.dart';
import 'package:inventory_management_system/features/expenses/expenses.dart';
import 'package:inventory_management_system/features/expenses/repositories/sqlite/sqlite_expense_repository.dart';
import 'package:inventory_management_system/features/parts/parts.dart';
import 'package:inventory_management_system/features/parts/repositories/sqlite/sqlite_part_repository.dart';
import 'package:inventory_management_system/features/reports/reports.dart';
import 'package:inventory_management_system/features/salaries/salaries.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_employee_repository.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_salary_payment_repository.dart';

void main() {
  late AppDatabase database;
  late CustomerService customerService;
  late PartService partService;
  late BillingService billingService;
  late ExpenseService expenseService;
  late SalaryService salaryService;
  late ReportService reportService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    final customerRepo = SqliteCustomerRepository(database);
    final partRepo = SqlitePartRepository(database);
    final serviceRepo = SqliteServiceRepository(database);
    final servicePartRepo = SqliteServicePartRepository(database);
    final invoiceRepo = SqliteInvoiceRepository(database);
    final expenseRepo = SqliteExpenseRepository(database);
    final employeeRepo = SqliteEmployeeRepository(database);
    final salaryPaymentRepo = SqliteSalaryPaymentRepository(database);

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
    salaryService = SalaryService(employeeRepo, salaryPaymentRepo);

    reportService = ReportService(
      billingService: billingService,
      customerService: customerService,
      partService: partService,
      expenseService: expenseService,
      salaryService: salaryService,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('generates comprehensive report with accurate calculations and rankings',
      () async {
    final now = DateTime.now();
    final range = ReportDateRange.month(now);

    // 1. Create customers
    final cust1 = await customerService.createCustomer(
      name: 'Ramesh Kumar',
      mobile: '9876543210',
      vehicleName: 'Honda Activa',
    );
    final cust2 = await customerService.createCustomer(
      name: 'Suresh Raina',
      mobile: '9123456780',
      vehicleName: 'Hyundai i20',
    );

    // 2. Create parts
    final part1 = await partService.createPart(
      partNumber: 'P-OIL-01',
      partName: 'Engine Oil 10W40',
      category: 'Fluids',
      purchasePrice: 300.0,
      sellingPrice: 500.0,
      currentStock: 20,
      lowStockThreshold: 5,
    );
    final part2 = await partService.createPart(
      partNumber: 'P-BRK-02',
      partName: 'Brake Pad Set',
      category: 'Brakes',
      purchasePrice: 200.0,
      sellingPrice: 400.0,
      currentStock: 10,
      lowStockThreshold: 12, // this one is low stock (10 <= 12)
    );

    // 3. Bill services
    // Billing 1: Ramesh, 2x Oil + labour 200 = (2 * 500) + 200 = 1200
    await billingService.billService(
      customerId: cust1.id,
      problemDesc: 'Oil change service',
      labourCharge: 200.0,
      partsUsed: [
        ServicePartInput(partId: part1.id, quantity: 2),
      ],
    );

    // Billing 2: Suresh, 1x Brake pad + labour 300 = 400 + 300 = 700
    await billingService.billService(
      customerId: cust2.id,
      problemDesc: 'Brake replacement',
      labourCharge: 300.0,
      partsUsed: [
        ServicePartInput(partId: part2.id, quantity: 1),
      ],
    );

    // 4. Expenses: 1 Business (Rent 500), 1 Personal (Groceries 300)
    await expenseService.createExpense(
      category: 'Rent',
      isPersonal: false,
      amount: 500.0,
      note: 'Shop rent advance',
    );
    await expenseService.createExpense(
      category: 'Groceries',
      isPersonal: true,
      amount: 300.0,
      note: 'Home food',
    );

    // 5. Employees & Salaries: 1 employee, paid 400, pending 200
    final emp = await salaryService.createEmployee(
      name: 'Vikas',
      monthlySalary: 10000.0,
    );
    await salaryService.recordPayment(
      employeeId: emp.id,
      amount: 400.0,
      status: 'paid',
    );
    await salaryService.recordPayment(
      employeeId: emp.id,
      amount: 200.0,
      status: 'pending',
    );

    // Generate comprehensive report
    final report = await reportService.getComprehensiveReport(range);

    // Verify Sales: 1200 + 700 = 1900
    expect(report.sales.totalSales, equals(1900.0));
    expect(report.sales.invoiceCount, equals(2));
    expect(report.sales.averageInvoiceValue, equals(950.0));
    expect(report.sales.trends.isNotEmpty, isTrue);

    // Verify Expenses:
    // Business expenses = 500
    // Personal expenses = 300
    // Paid salary expenses = 400
    // Total expenses = 500 + 400 = 900
    expect(report.expenses.totalBusinessExpenses, equals(500.0));
    expect(report.expenses.totalPersonalExpenses, equals(300.0));
    expect(report.expenses.totalSalaryExpenses, equals(400.0));
    expect(report.expenses.totalExpenses, equals(900.0));
    expect(report.expenses.categories.length, equals(1));
    expect(report.expenses.categories.first.category, equals('Rent'));

    // Verify Profit: 1900 - 900 = 1000
    expect(report.profit.totalRevenue, equals(1900.0));
    expect(report.profit.totalExpenses, equals(900.0));
    expect(report.profit.netProfit, equals(1000.0));
    expect(report.profit.profitMarginPercentage, closeTo((1000 / 1900) * 100, 0.01));

    // Verify Operations
    expect(report.servicesCompleted, equals(2));

    // Verify Top Customers: Ramesh (1200) > Suresh (700)
    expect(report.topCustomers.length, equals(2));
    expect(report.topCustomers.first.customerName, equals('Ramesh Kumar'));
    expect(report.topCustomers.first.totalSpent, equals(1200.0));
    expect(report.topCustomers[1].customerName, equals('Suresh Raina'));
    expect(report.topCustomers[1].totalSpent, equals(700.0));

    // Verify Top Selling Parts: Oil (2 qty sold, 1000 rev) > Brake pad (1 qty sold, 400 rev)
    expect(report.topParts.length, equals(2));
    expect(report.topParts.first.partName, equals('Engine Oil 10W40'));
    expect(report.topParts.first.quantitySold, equals(2));
    expect(report.topParts.first.totalRevenue, equals(1000.0));
    expect(report.topParts[1].partName, equals('Brake Pad Set'));
    expect(report.topParts[1].quantitySold, equals(1));

    // Verify Salaries
    expect(report.salaries.totalPaid, equals(400.0));
    expect(report.salaries.totalPending, equals(200.0));
    expect(report.salaries.items.first.employeeName, equals('Vikas'));

    // Verify Inventory Summary
    // Part1 stock remaining: 20 - 2 = 18. Value = 18 * 300 = 5400
    // Part2 stock remaining: 10 - 1 = 9. Value = 9 * 200 = 1800
    // Total units: 18 + 9 = 27
    // Total value: 5400 + 1800 = 7200
    // Low stock: part2 is low stock (current stock 9 <= threshold 12)
    expect(report.inventory.totalPartCount, equals(2));
    expect(report.inventory.totalStockUnits, equals(27));
    expect(report.inventory.totalInventoryValue, equals(7200.0));
    expect(report.inventory.lowStockCount, equals(1));
  });

  test('handles empty date range gracefully with zero totals', () async {
    final pastRange = ReportDateRange(
      start: DateTime(2010, 1, 1),
      end: DateTime(2010, 1, 31),
    );

    final report = await reportService.getComprehensiveReport(pastRange);

    expect(report.sales.totalSales, equals(0.0));
    expect(report.sales.invoiceCount, equals(0));
    expect(report.sales.averageInvoiceValue, equals(0.0));
    expect(report.expenses.totalExpenses, equals(0.0));
    expect(report.profit.netProfit, equals(0.0));
    expect(report.profit.profitMarginPercentage, equals(0.0));
    expect(report.topCustomers, isEmpty);
    expect(report.topParts, isEmpty);
    expect(report.servicesCompleted, equals(0));
  });
}
