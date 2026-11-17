import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../database/app_database.dart';
import '../interfaces/backup_repository.dart';

class SqliteBackupRepository implements BackupRepository {
  final AppDatabase database;

  SqliteBackupRepository(this.database);

  @override
  Future<File> getDatabaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'inventory_management.sqlite'));
  }

  @override
  Future<Map<String, List<Map<String, dynamic>>>> exportAllTables() async {
    final customersRows = await database.select(database.customers).get();
    final partsRows = await database.select(database.parts).get();
    final purchasesRows = await database.select(database.purchases).get();
    final serviceJobRows = await database.select(database.serviceJobs).get();
    final servicePartRows = await database.select(database.serviceParts).get();
    final invoiceRows = await database.select(database.invoices).get();
    final expenseRows = await database.select(database.expenses).get();
    final employeeRows = await database.select(database.employees).get();
    final salaryPaymentRows = await database
        .select(database.salaryPayments)
        .get();
    final counterRows = await database.select(database.counters).get();
    final personalFinanceAccountRows = await database
        .select(database.personalFinanceAccounts)
        .get();
    final personalFinanceTransactionRows = await database
        .select(database.personalFinanceTransactions)
        .get();

    return {
      'customers': customersRows
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'mobile': c.mobile,
              'vehicleName': c.vehicleName,
              'createdDate': c.createdDate,
            },
          )
          .toList(),
      'parts': partsRows
          .map(
            (p) => {
              'id': p.id,
              'partNumber': p.partNumber,
              'partName': p.partName,
              'category': p.category,
              'purchasePrice': p.purchasePrice,
              'sellingPrice': p.sellingPrice,
              'currentStock': p.currentStock,
              'lowStockThreshold': p.lowStockThreshold,
            },
          )
          .toList(),
      'purchases': purchasesRows
          .map(
            (p) => {
              'id': p.id,
              'partId': p.partId,
              'quantity': p.quantity,
              'purchasePrice': p.purchasePrice,
              'purchaseDate': p.purchaseDate,
            },
          )
          .toList(),
      'serviceJobs': serviceJobRows
          .map(
            (s) => {
              'id': s.id,
              'customerId': s.customerId,
              'problemDesc': s.problemDesc,
              'labourCharge': s.labourCharge,
              'serviceDate': s.serviceDate,
              'invoiceId': s.invoiceId,
            },
          )
          .toList(),
      'serviceParts': servicePartRows
          .map(
            (sp) => {
              'id': sp.id,
              'serviceId': sp.serviceId,
              'partId': sp.partId,
              'quantity': sp.quantity,
              'priceEach': sp.priceEach,
            },
          )
          .toList(),
      'invoices': invoiceRows
          .map(
            (i) => {
              'id': i.id,
              'invoiceNumber': i.invoiceNumber,
              'serviceId': i.serviceId,
              'totalAmount': i.totalAmount,
              'createdDate': i.createdDate,
            },
          )
          .toList(),
      'expenses': expenseRows
          .map(
            (e) => {
              'id': e.id,
              'category': e.category,
              'isPersonal': e.isPersonal,
              'amount': e.amount,
              'note': e.note,
              'entryDate': e.entryDate,
            },
          )
          .toList(),
      'employees': employeeRows
          .map(
            (e) => {
              'id': e.id,
              'name': e.name,
              'monthlySalary': e.monthlySalary,
            },
          )
          .toList(),
      'salaryPayments': salaryPaymentRows
          .map(
            (sp) => {
              'id': sp.id,
              'employeeId': sp.employeeId,
              'amount': sp.amount,
              'paymentDate': sp.paymentDate,
              'status': sp.status,
            },
          )
          .toList(),
      'counters': counterRows
          .map((c) => {'name': c.name, 'value': c.value})
          .toList(),
      'personalFinanceAccounts': personalFinanceAccountRows
          .map(
            (a) => {
              'id': a.id,
              'name': a.name,
              'openingBalance': a.openingBalance,
              'createdDate': a.createdDate,
            },
          )
          .toList(),
      'personalFinanceTransactions': personalFinanceTransactionRows
          .map(
            (t) => {
              'id': t.id,
              'accountId': t.accountId,
              'type': t.type,
              'amount': t.amount,
              'category': t.category,
              'payee': t.payee,
              'note': t.note,
              'transactionDate': t.transactionDate,
            },
          )
          .toList(),
    };
  }

  @override
  Future<void> restoreAllTables(
    Map<String, List<Map<String, dynamic>>> tablesData,
  ) async {
    await database.transaction(() async {
      // 1. Delete in reverse dependency order
      await database.delete(database.personalFinanceTransactions).go();
      await database.delete(database.personalFinanceAccounts).go();
      await database.delete(database.serviceParts).go();
      await database.delete(database.invoices).go();
      await database.delete(database.serviceJobs).go();
      await database.delete(database.purchases).go();
      await database.delete(database.salaryPayments).go();
      await database.delete(database.attendances).go();
      await database.delete(database.expenses).go();
      await database.delete(database.parts).go();
      await database.delete(database.customers).go();
      await database.delete(database.employees).go();
      await database.delete(database.counters).go();

      // 2. Insert customers
      final rawCustomers = tablesData['customers'] ?? [];
      for (final c in rawCustomers) {
        await database
            .into(database.customers)
            .insert(
              CustomersCompanion.insert(
                id: c['id'] as String,
                name: c['name'] as String,
                mobile: c['mobile'] as String,
                vehicleName: Value(c['vehicleName'] as String?),
                createdDate: c['createdDate'] as String,
              ),
            );
      }

      // 3. Insert parts
      final rawParts = tablesData['parts'] ?? [];
      for (final p in rawParts) {
        await database
            .into(database.parts)
            .insert(
              PartsCompanion.insert(
                id: p['id'] as String,
                partNumber: p['partNumber'] as String,
                partName: p['partName'] as String,
                category: Value(p['category'] as String?),
                purchasePrice: (p['purchasePrice'] as num).toDouble(),
                sellingPrice: (p['sellingPrice'] as num).toDouble(),
                currentStock: Value((p['currentStock'] as num?)?.toInt() ?? 0),
                lowStockThreshold: Value(
                  (p['lowStockThreshold'] as num?)?.toInt() ?? 5,
                ),
              ),
            );
      }

      // 4. Insert purchases
      final rawPurchases = tablesData['purchases'] ?? [];
      for (final p in rawPurchases) {
        await database
            .into(database.purchases)
            .insert(
              PurchasesCompanion.insert(
                id: p['id'] as String,
                partId: p['partId'] as String,
                quantity: (p['quantity'] as num).toInt(),
                purchasePrice: (p['purchasePrice'] as num).toDouble(),
                purchaseDate: p['purchaseDate'] as String,
              ),
            );
      }

      // 5. Insert service jobs
      final rawServiceJobs = tablesData['serviceJobs'] ?? [];
      for (final s in rawServiceJobs) {
        await database
            .into(database.serviceJobs)
            .insert(
              ServiceJobsCompanion.insert(
                id: s['id'] as String,
                customerId: s['customerId'] as String,
                problemDesc: Value(s['problemDesc'] as String?),
                labourCharge: Value(
                  (s['labourCharge'] as num?)?.toDouble() ?? 0.0,
                ),
                serviceDate: s['serviceDate'] as String,
                invoiceId: Value(s['invoiceId'] as String?),
              ),
            );
      }

      // 6. Insert service parts
      final rawServiceParts = tablesData['serviceParts'] ?? [];
      for (final sp in rawServiceParts) {
        await database
            .into(database.serviceParts)
            .insert(
              ServicePartsCompanion.insert(
                id: sp['id'] as String,
                serviceId: sp['serviceId'] as String,
                partId: sp['partId'] as String,
                quantity: (sp['quantity'] as num).toInt(),
                priceEach: (sp['priceEach'] as num).toDouble(),
              ),
            );
      }

      // 7. Insert invoices
      final rawInvoices = tablesData['invoices'] ?? [];
      for (final i in rawInvoices) {
        await database
            .into(database.invoices)
            .insert(
              InvoicesCompanion.insert(
                id: i['id'] as String,
                invoiceNumber: (i['invoiceNumber'] as num).toInt(),
                serviceId: i['serviceId'] as String,
                totalAmount: (i['totalAmount'] as num).toDouble(),
                createdDate: i['createdDate'] as String,
              ),
            );
      }

      // 8. Insert expenses
      final rawExpenses = tablesData['expenses'] ?? [];
      for (final e in rawExpenses) {
        await database
            .into(database.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: e['id'] as String,
                category: e['category'] as String,
                isPersonal: Value((e['isPersonal'] as bool?) ?? false),
                amount: (e['amount'] as num).toDouble(),
                note: Value(e['note'] as String?),
                entryDate: e['entryDate'] as String,
              ),
            );
      }

      // 9. Insert employees
      final rawEmployees = tablesData['employees'] ?? [];
      for (final emp in rawEmployees) {
        await database
            .into(database.employees)
            .insert(
              EmployeesCompanion.insert(
                id: emp['id'] as String,
                name: emp['name'] as String,
                monthlySalary: (emp['monthlySalary'] as num).toDouble(),
              ),
            );
      }

      // 10. Insert salary payments
      final rawSalaryPayments = tablesData['salaryPayments'] ?? [];
      for (final sp in rawSalaryPayments) {
        await database
            .into(database.salaryPayments)
            .insert(
              SalaryPaymentsCompanion.insert(
                id: sp['id'] as String,
                employeeId: sp['employeeId'] as String,
                amount: (sp['amount'] as num).toDouble(),
                paymentDate: sp['paymentDate'] as String,
                status: sp['status'] as String,
              ),
            );
      }

      // 11. Insert counters
      final rawCounters = tablesData['counters'] ?? [];
      var hasInvoiceCounter = false;
      for (final c in rawCounters) {
        final name = c['name'] as String;
        if (name == 'invoice_number') hasInvoiceCounter = true;
        await database
            .into(database.counters)
            .insert(
              CountersCompanion.insert(
                name: name,
                value: Value((c['value'] as num?)?.toInt() ?? 0),
              ),
            );
      }

      if (!hasInvoiceCounter) {
        final maxInv = rawInvoices.fold<int>(0, (max, inv) {
          final numVal = (inv['invoiceNumber'] as num?)?.toInt() ?? 0;
          return numVal > max ? numVal : max;
        });
        await database
            .into(database.counters)
            .insert(
              CountersCompanion.insert(
                name: 'invoice_number',
                value: Value(maxInv),
              ),
            );
      }

      // 12. Insert personal finance accounts
      final rawAccounts = tablesData['personalFinanceAccounts'] ?? [];
      for (final a in rawAccounts) {
        await database
            .into(database.personalFinanceAccounts)
            .insert(
              PersonalFinanceAccountsCompanion.insert(
                id: a['id'] as String,
                name: a['name'] as String,
                openingBalance: Value(
                  (a['openingBalance'] as num?)?.toDouble() ?? 0.0,
                ),
                createdDate: a['createdDate'] as String,
              ),
            );
      }

      // If restoring an old backup without Personal Finance tables, ensure default Owner's Account
      final existingAccounts = await database
          .select(database.personalFinanceAccounts)
          .get();
      if (existingAccounts.isEmpty) {
        await database
            .into(database.personalFinanceAccounts)
            .insert(
              PersonalFinanceAccountsCompanion.insert(
                id: 'default-owner-account',
                name: "Owner's Account",
                openingBalance: const Value(0.0),
                createdDate: DateTime.now().toIso8601String(),
              ),
            );
      }

      // 13. Insert personal finance transactions
      final rawTransactions = tablesData['personalFinanceTransactions'] ?? [];
      for (final t in rawTransactions) {
        await database
            .into(database.personalFinanceTransactions)
            .insert(
              PersonalFinanceTransactionsCompanion.insert(
                id: t['id'] as String,
                accountId: t['accountId'] as String,
                type: t['type'] as String,
                amount: (t['amount'] as num).toDouble(),
                category: t['category'] as String,
                payee: Value(t['payee'] as String?),
                note: Value(t['note'] as String?),
                transactionDate: t['transactionDate'] as String,
              ),
            );
      }
    });
  }

  @override
  Future<int> deleteFakeData() async {
    return await database.transaction(() async {
      int count = 0;
      count += await (database.delete(database.personalFinanceTransactions)
            ..where((t) => t.id.like('fake_%')))
          .go();
      count += await (database.delete(database.attendances)
            ..where((t) => t.id.like('fake_%')))
          .go();
      count += await (database.delete(database.salaryPayments)
            ..where((t) => t.id.like('fake_%')))
          .go();
      count += await (database.delete(database.employees)
            ..where((t) => t.id.like('fake_%')))
          .go();
      count += await (database.delete(database.invoices)
            ..where((t) => t.id.like('fake_%')))
          .go();
      count += await (database.delete(database.serviceParts)
            ..where((t) => t.id.like('fake_%')))
          .go();
      count += await (database.delete(database.serviceJobs)
            ..where((t) => t.id.like('fake_%')))
          .go();
      count += await (database.delete(database.purchases)
            ..where((t) => t.id.like('fake_%')))
          .go();
      count += await (database.delete(database.parts)
            ..where((t) => t.id.like('fake_%')))
          .go();
      count += await (database.delete(database.customers)
            ..where((t) => t.id.like('fake_%')))
          .go();
      count += await (database.delete(database.expenses)
            ..where((t) => t.id.like('fake_%')))
          .go();
      return count;
    });
  }

  @override
  Future<int> seedExtremeFakeData() async {
    return await database.transaction(() async {
      // First clean up any existing fake data
      await deleteFakeData();

      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final sixMonthsAgoIso =
          now.subtract(const Duration(days: 185)).toIso8601String();
      int insertedCount = 0;

      // 1. Customers with extreme length names and vehicle names
      await database.into(database.customers).insert(
            CustomersCompanion.insert(
              id: 'fake_cust_1',
              name:
                  '[FAKE] Dr. Shri Rameshchandra Venkatanarasimharajuvaripeta',
              mobile: '+91 99999 00001',
              vehicleName: const Value(
                  '[FAKE] Mercedes-Benz AMG GT 4-Door Coupe 63 S E Performance 4MATIC+'),
              createdDate: nowIso,
            ),
          );
      insertedCount++;

      await database.into(database.customers).insert(
            CustomersCompanion.insert(
              id: 'fake_cust_2',
              name: '[FAKE] Smt. Padmavati Vijayalakshmi Radhakrishnan',
              mobile: '+91 99999 00002',
              vehicleName: const Value(
                  '[FAKE] Royal Enfield Continental GT 650 Chrome Special Edition'),
              createdDate: sixMonthsAgoIso,
            ),
          );
      insertedCount++;

      // 2. Parts with large numbers, long names, high prices
      await database.into(database.parts).insert(
            PartsCompanion.insert(
              id: 'fake_part_1',
              partNumber: 'FAKE-PART-999999',
              partName:
                  '[FAKE] Bosch High Performance Dual-Core Platinum Spark Plug Extra Long Edition',
              category: const Value('[FAKE] Electrical & Ignition Systems'),
              purchasePrice: 25000.0,
              sellingPrice: 45000.0,
              currentStock: const Value(9999),
              lowStockThreshold: const Value(10),
            ),
          );
      insertedCount++;

      await database.into(database.parts).insert(
            PartsCompanion.insert(
              id: 'fake_part_2',
              partNumber: 'FAKE-PART-888888',
              partName:
                  '[FAKE] Brembo Carbon-Ceramic Ultra-Braking Caliper & Rotor Assembly',
              category: const Value('[FAKE] High-Performance Braking'),
              purchasePrice: 75000.0,
              sellingPrice: 125000.0,
              currentStock: const Value(1),
              lowStockThreshold: const Value(5),
            ),
          );
      insertedCount++;

      // 3. Purchase entry
      await database.into(database.purchases).insert(
            PurchasesCompanion.insert(
              id: 'fake_purch_1',
              partId: 'fake_part_1',
              quantity: 500,
              purchasePrice: 25000.0,
              purchaseDate: nowIso,
            ),
          );
      insertedCount++;

      // 4. Service Jobs and Invoices
      await database.into(database.serviceJobs).insert(
            ServiceJobsCompanion.insert(
              id: 'fake_job_1',
              customerId: 'fake_cust_1',
              problemDesc: const Value(
                  '[FAKE] Comprehensive Powertrain Overhaul, Twin-Turbocharger Tuning, and Transmission Precision Diagnostics'),
              labourCharge: const Value(150000.0),
              serviceDate: nowIso,
              invoiceId: const Value('fake_inv_1'),
              serviceReport: const Value(
                  '[FAKE] Complete multi-point mechanical inspection, hydraulic pressure test, and digital engine diagnostics verified with zero fault codes.'),
              labourEntries: const Value(
                  '[{"description":"[FAKE] Complete Powertrain Overhaul & Twin-Turbo Tuning","charge":100000.0},{"description":"[FAKE] Electronic Control Unit Sensor Calibration","charge":50000.0}]'),
            ),
          );
      insertedCount++;

      await database.into(database.serviceParts).insert(
            ServicePartsCompanion.insert(
              id: 'fake_sp_1',
              serviceId: 'fake_job_1',
              partId: 'fake_part_1',
              quantity: 4,
              priceEach: 45000.0,
            ),
          );
      insertedCount++;

      await database.into(database.serviceParts).insert(
            ServicePartsCompanion.insert(
              id: 'fake_sp_2',
              serviceId: 'fake_job_1',
              partId: 'fake_part_2',
              quantity: 2,
              priceEach: 125000.0,
            ),
          );
      insertedCount++;

      // Total: 4*45000 (180,000) + 2*125000 (250,000) + 150000 (labour) = 580,000.0
      await database.into(database.invoices).insert(
            InvoicesCompanion.insert(
              id: 'fake_inv_1',
              invoiceNumber: 999999,
              serviceId: 'fake_job_1',
              totalAmount: 580000.0,
              createdDate: nowIso,
            ),
          );
      insertedCount++;

      // Second service job (6 months ago) for customer 2 so service reminder triggers
      await database.into(database.serviceJobs).insert(
            ServiceJobsCompanion.insert(
              id: 'fake_job_2',
              customerId: 'fake_cust_2',
              problemDesc: const Value(
                  '[FAKE] Periodic Scheduled Service & Oil Flush'),
              labourCharge: const Value(25000.0),
              serviceDate: sixMonthsAgoIso,
              invoiceId: const Value('fake_inv_2'),
              serviceReport: const Value(
                  '[FAKE] Routine 90-day interval maintenance check.'),
              labourEntries: const Value(
                  '[{"description":"[FAKE] Routine Service & Oil Flush","charge":25000.0}]'),
            ),
          );
      insertedCount++;

      await database.into(database.invoices).insert(
            InvoicesCompanion.insert(
              id: 'fake_inv_2',
              invoiceNumber: 999998,
              serviceId: 'fake_job_2',
              totalAmount: 25000.0,
              createdDate: sixMonthsAgoIso,
            ),
          );
      insertedCount++;

      // 5. Expenses
      await database.into(database.expenses).insert(
            ExpensesCompanion.insert(
              id: 'fake_exp_1',
              category:
                  '[FAKE] Commercial Showroom Heavy Equipment Lease & Annual Retrofitting Maintenance',
              isPersonal: const Value(false),
              amount: 950000.0,
              note: const Value(
                  '[FAKE] Annual facility lease and heavy precision machinery maintenance invoice #99988'),
              entryDate: nowIso,
            ),
          );
      insertedCount++;

      // 6. Employees, Salary Payments, Attendances
      await database.into(database.employees).insert(
            EmployeesCompanion.insert(
              id: 'fake_emp_1',
              name:
                  '[FAKE] Vikramaditya Chandrashekhar Surendranath Banerjee',
              monthlySalary: 350000.0,
            ),
          );
      insertedCount++;

      await database.into(database.salaryPayments).insert(
            SalaryPaymentsCompanion.insert(
              id: 'fake_sal_1',
              employeeId: 'fake_emp_1',
              amount: 350000.0,
              paymentDate: nowIso,
              status: 'paid',
            ),
          );
      insertedCount++;

      await database.into(database.salaryPayments).insert(
            SalaryPaymentsCompanion.insert(
              id: 'fake_sal_2',
              employeeId: 'fake_emp_1',
              amount: 175000.0,
              paymentDate: nowIso,
              status: 'pending',
            ),
          );
      insertedCount++;

      await database.into(database.attendances).insert(
            AttendancesCompanion.insert(
              id: 'fake_att_1',
              employeeId: 'fake_emp_1',
              date: nowIso.substring(0, 10),
              status: 'present',
              reportingTime: const Value('09:45'),
            ),
          );
      insertedCount++;

      // 7. Personal Finance Transactions
      await database.into(database.personalFinanceTransactions).insert(
            PersonalFinanceTransactionsCompanion.insert(
              id: 'fake_pftx_1',
              accountId: 'default-owner-account',
              type: 'credit',
              amount: 5000000.0,
              category:
                  '[FAKE] Capital Injection & Strategic Partner Equity Disbursement',
              payee: const Value(
                  '[FAKE] Apex International Financial Holdings Group Corp'),
              note: const Value('[FAKE] Strategic growth infusion tranche 1'),
              transactionDate: nowIso,
            ),
          );
      insertedCount++;

      await database.into(database.personalFinanceTransactions).insert(
            PersonalFinanceTransactionsCompanion.insert(
              id: 'fake_pftx_2',
              accountId: 'default-owner-account',
              type: 'debit',
              amount: 1500000.0,
              category:
                  '[FAKE] High-Yield Industrial Equipment Purchase & Import Duty',
              payee: const Value(
                  '[FAKE] Heavy Machinery Logistics Worldwide Pvt Ltd'),
              note: const Value(
                  '[FAKE] Industrial 5-Axis CNC Precision Milling System'),
              transactionDate: nowIso,
            ),
          );
      insertedCount++;

      return insertedCount;
    });
  }
}
