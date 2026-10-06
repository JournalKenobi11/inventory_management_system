import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

import '../../billing/repositories/interfaces/invoice_repository.dart';
import '../../billing/repositories/interfaces/service_part_repository.dart';
import '../../billing/repositories/interfaces/service_repository.dart';

import '../../billing/repositories/sqlite/sqlite_invoice_repository.dart';
import '../../billing/repositories/sqlite/sqlite_service_part_repository.dart';
import '../../billing/repositories/sqlite/sqlite_service_repository.dart';

import '../../expenses/repositories/interfaces/expense_repository.dart';
import '../../expenses/repositories/sqlite/sqlite_expense_repository.dart';

import '../../parts/repositories/interfaces/part_repository.dart';
import '../../parts/repositories/sqlite/sqlite_part_repository.dart';

import '../../salaries/repositories/interfaces/salary_payment_repository.dart';
import '../../salaries/repositories/sqlite/sqlite_salary_payment_repository.dart';

import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';

final dashboardInvoiceRepositoryProvider =
    Provider<InvoiceRepository>((ref) {
  return SqliteInvoiceRepository(
    ref.read(appDatabaseProvider),
  );
});

final dashboardServiceRepositoryProvider =
    Provider<ServiceRepository>((ref) {
  return SqliteServiceRepository(
    ref.read(appDatabaseProvider),
  );
});

final dashboardServicePartRepositoryProvider =
    Provider<ServicePartRepository>((ref) {
  return SqliteServicePartRepository(
    ref.read(appDatabaseProvider),
  );
});

final dashboardExpenseRepositoryProvider =
    Provider<ExpenseRepository>((ref) {
  return SqliteExpenseRepository(
    ref.read(appDatabaseProvider),
  );
});

final dashboardSalaryPaymentRepositoryProvider =
    Provider<SalaryPaymentRepository>((ref) {
  return SqliteSalaryPaymentRepository(
    ref.read(appDatabaseProvider),
  );
});

final dashboardPartRepositoryProvider =
    Provider<PartRepository>((ref) {
  return SqlitePartRepository(
    ref.read(appDatabaseProvider),
  );
});

final dashboardServiceProvider =
    Provider<DashboardService>((ref) {
  return DashboardService(
    invoiceRepository:
        ref.read(dashboardInvoiceRepositoryProvider),
    serviceRepository:
        ref.read(dashboardServiceRepositoryProvider),
    servicePartRepository:
        ref.read(
          dashboardServicePartRepositoryProvider,
        ),
    expenseRepository:
        ref.read(dashboardExpenseRepositoryProvider),
    salaryPaymentRepository:
        ref.read(
          dashboardSalaryPaymentRepositoryProvider,
        ),
    partRepository:
        ref.read(dashboardPartRepositoryProvider),
  );
});

final dashboardProvider = FutureProvider.family<
    DashboardSummary,
    DashboardDateRange>(
  (ref, range) {
    return ref
        .read(dashboardServiceProvider)
        .getSummary(range);
  },
);