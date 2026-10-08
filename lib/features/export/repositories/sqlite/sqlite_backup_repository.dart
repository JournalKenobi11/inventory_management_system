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
}
