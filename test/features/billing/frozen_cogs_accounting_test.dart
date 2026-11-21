import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/database/app_database.dart' as db;
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
import 'package:inventory_management_system/features/reports/reports.dart';
import 'package:inventory_management_system/features/salaries/salaries.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_employee_repository.dart';
import 'package:inventory_management_system/features/salaries/repositories/sqlite/sqlite_salary_payment_repository.dart';

void main() {
  late db.AppDatabase database;
  late PartService partService;
  late BillingService billingService;
  late CustomerService customerService;
  late ReportService reportService;
  late DashboardService dashboardService;
  late SqlitePartRepository partRepository;
  late SqliteInvoiceRepository invoiceRepository;
  late SqliteServiceRepository serviceRepository;
  late SqliteServicePartRepository servicePartRepository;
  late SqliteExpenseRepository expenseRepository;
  late SqliteSalaryPaymentRepository salaryPaymentRepository;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    partRepository = SqlitePartRepository(database);
    partService = PartService(partRepository);

    final customerRepo = SqliteCustomerRepository(database);
    customerService = CustomerService(customerRepo);

    serviceRepository = SqliteServiceRepository(database);
    servicePartRepository = SqliteServicePartRepository(database);
    invoiceRepository = SqliteInvoiceRepository(database);
    expenseRepository = SqliteExpenseRepository(database);
    salaryPaymentRepository = SqliteSalaryPaymentRepository(database);

    billingService = BillingService(
      serviceRepository,
      servicePartRepository,
      invoiceRepository,
      customerService,
      partService,
      database,
    );

    reportService = ReportService(
      billingService: billingService,
      customerService: customerService,
      partService: partService,
      expenseService: ExpenseService(expenseRepository),
      salaryService: SalaryService(
        SqliteEmployeeRepository(database),
        salaryPaymentRepository,
      ),
    );

    dashboardService = DashboardService(
      invoiceRepository: invoiceRepository,
      serviceRepository: serviceRepository,
      servicePartRepository: servicePartRepository,
      expenseRepository: expenseRepository,
      salaryPaymentRepository: salaryPaymentRepository,
      partRepository: partRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Frozen COGS Accounting', () {
    test(
        'snapshots purchasePriceEach on billing and keeps historical profit reports frozen when part purchase price changes',
        () async {
      final customer = await customerService.createCustomer(
        name: 'Anita Verma',
        mobile: '9123456780',
      );

      // Part created with purchase price ₹200 and selling price ₹350
      final part = await partService.createPart(
        partNumber: 'BAT-12V',
        partName: '12V Exide Battery',
        purchasePrice: 200.0,
        sellingPrice: 350.0,
        currentStock: 10,
      );

      // Bill 2 batteries: revenue = 2 * 350 = 700, cost = 2 * 200 = 400, gross profit = 300
      final invoice = await billingService.billService(
        customerId: customer.id,
        problemDesc: 'Battery replacement',
        partsUsed: [
          ServicePartInput(partId: part.id, quantity: 2),
        ],
      );

      final serviceParts =
          await billingService.getServiceParts(invoice.serviceId);
      expect(serviceParts.length, equals(1));
      expect(serviceParts.first.purchasePriceEach, equals(200.0));
      expect(serviceParts.first.costLineTotal, equals(400.0));

      final now = DateTime.now();

      // Check initial profit report
      final initialProfit = await reportService.getProfitReport(
        ReportDateRange(
          start: now.subtract(const Duration(days: 1)),
          end: now.add(const Duration(days: 1)),
        ),
      );
      expect(initialProfit.cogs, equals(400.0));
      expect(initialProfit.grossProfit, equals(300.0));

      // Now, manufacturer inflates battery purchase price to ₹320!
      final currentPart = await partService.getPartById(part.id);
      await partService.updatePart(
        currentPart!.copyWith(purchasePrice: 320.0),
      );

      // Verify the part purchase price in DB is indeed 320
      final updatedPart = await partService.getPartById(part.id);
      expect(updatedPart!.purchasePrice, equals(320.0));

      // Verify the historical invoice's COGS and Profit in ReportService REMAIN FROZEN at 400 & 300!
      final frozenProfit = await reportService.getProfitReport(
        ReportDateRange(
          start: now.subtract(const Duration(days: 1)),
          end: now.add(const Duration(days: 1)),
        ),
      );
      expect(frozenProfit.cogs, equals(400.0),
          reason:
              'COGS must not recalculate using current part price of 320!');
      expect(frozenProfit.grossProfit, equals(300.0));

      // Also verify DashboardService respects the frozen COGS!
      final dashboardSummary = await dashboardService.getSummary(
        DashboardDateRange.singleDay(now),
      );
      expect(dashboardSummary.cogs, equals(400.0));
    });
  });
}
