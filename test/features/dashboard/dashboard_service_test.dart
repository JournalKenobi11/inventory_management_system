import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_service_part_repository.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_service_repository.dart';
import 'package:inventory_management_system/features/customers/customers.dart';
import 'package:inventory_management_system/features/customers/repositories/sqlite/sqlite_customer_repository.dart';
import 'package:inventory_management_system/features/dashboard/dashboard.dart';
import 'package:inventory_management_system/features/expenses/expenses.dart';
import 'package:inventory_management_system/features/expenses/repositories/sqlite/sqlite_expense_repository.dart';
import 'package:inventory_management_system/features/parts/parts.dart';
import 'package:inventory_management_system/features/parts/repositories/sqlite/sqlite_part_repository.dart';
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
  late DashboardService dashboardService;

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

    dashboardService = DashboardService(
      invoiceRepository: invoiceRepo,
      serviceRepository: serviceRepo,
      servicePartRepository: servicePartRepo,
      expenseRepository: expenseRepo,
      salaryPaymentRepository: salaryPaymentRepo,
      partRepository: partRepo,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('accurately calculates profit by deducting COGS and operating expenses',
      () async {
    final now = DateTime.now();
    final range = DashboardDateRange.month(now);

    // 1. Create a customer
    final customer = await customerService.createCustomer(
      name: 'Rajesh Sharma',
      mobile: '9876501234',
    );

    // 2. Create a part bought at 100, sold at 110
    final part = await partService.createPart(
      partNumber: 'SPK-01',
      partName: 'Spark Plug',
      category: 'Ignition',
      purchasePrice: 100.0,
      sellingPrice: 110.0,
      currentStock: 20,
      lowStockThreshold: 5,
    );

    // 3. Bill 2 spark plugs (2 x 110 = 220) + 80 labour = 300 total invoice
    // Cost of parts used (COGS) = 2 x 100 = 200
    // Gross Profit = 300 - 200 = 100 (Markup 20 + Labour 80)
    await billingService.billService(
      customerId: customer.id,
      problemDesc: 'Plug replacement',
      labourCharge: 80.0,
      partsUsed: [
        ServicePartInput(partId: part.id, quantity: 2),
      ],
    );

    // 4. Record shop operating expense = 50
    await expenseService.createExpense(
      category: 'Electricity',
      isPersonal: false,
      amount: 50.0,
      note: 'Shop power bill',
    );

    // 5. Record employee salary payment = 20
    final employee = await salaryService.createEmployee(
      name: 'Manoj',
      monthlySalary: 10000.0,
    );
    await salaryService.recordPayment(
      employeeId: employee.id,
      amount: 20.0,
      status: 'paid',
    );

    // Get dashboard summary
    final summary = await dashboardService.getSummary(range);

    // Sales = 300
    expect(summary.totalSales, equals(300.0));

    // COGS = 200
    expect(summary.cogs, equals(200.0));

    // Operating expenses = 50 (electricity) + 20 (salary) = 70
    expect(summary.totalExpenses, equals(70.0));

    // Gross Profit = Sales 300 - COGS 200 = 100
    expect(summary.profit, equals(100.0));

    // Services completed = 1
    expect(summary.servicesCompleted, equals(1));

    // Inventory value: 18 remaining @ 100 = 1800
    expect(summary.inventoryValue, equals(1800.0));
  });
}
