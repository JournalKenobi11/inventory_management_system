import '../../billing/billing.dart';
import '../../customers/customers.dart';
import '../../expenses/expenses.dart';
import '../../parts/parts.dart';
import '../../salaries/salaries.dart';
import '../models/report_models.dart';

class ReportService {
  final BillingService billingService;
  final CustomerService customerService;
  final PartService partService;
  final ExpenseService expenseService;
  final SalaryService salaryService;

  ReportService({
    required this.billingService,
    required this.customerService,
    required this.partService,
    required this.expenseService,
    required this.salaryService,
  });

  Future<ComprehensiveReport> getComprehensiveReport(
    ReportDateRange range,
  ) async {
    final sales = await getSalesReport(range);
    final expenses = await getExpenseReport(range);
    final profit = await getProfitReport(range);
    final topCustomers = await getTopCustomers(range);
    final topParts = await getTopSellingParts(range);
    final salaries = await getSalaryExpenseReport(range);
    final inventory = await getInventorySummaryReport();

    final allServices = await billingService.getAllServices();
    final servicesCompleted = allServices
        .where((service) => _isDateInRange(service.serviceDate, range))
        .length;

    return ComprehensiveReport(
      range: range,
      generatedAt: DateTime.now(),
      sales: sales,
      expenses: expenses,
      profit: profit,
      servicesCompleted: servicesCompleted,
      topCustomers: topCustomers,
      topParts: topParts,
      salaries: salaries,
      inventory: inventory,
    );
  }

  Future<SalesReportData> getSalesReport(
    ReportDateRange range,
  ) async {
    final allInvoices = await billingService.getAllInvoices();
    final inRangeInvoices = allInvoices
        .where((inv) => _isDateInRange(inv.createdDate, range))
        .toList();

    final totalSales = inRangeInvoices.fold<double>(
      0.0,
      (sum, inv) => sum + inv.totalAmount,
    );
    final invoiceCount = inRangeInvoices.length;
    final averageInvoiceValue =
        invoiceCount > 0 ? totalSales / invoiceCount : 0.0;

    // Group sales by day/date for trends
    final trendMap = <String, _TrendAccumulator>{};
    for (final inv in inRangeInvoices) {
      final parsedDate = DateTime.tryParse(inv.createdDate);
      if (parsedDate == null) continue;
      final key =
          '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
      final existing = trendMap.putIfAbsent(
        key,
        () => _TrendAccumulator(date: parsedDate),
      );
      existing.totalSales += inv.totalAmount;
      existing.count += 1;
    }

    final sortedKeys = trendMap.keys.toList()..sort();
    final trends = sortedKeys.map((key) {
      final acc = trendMap[key]!;
      return SalesTrendPoint(
        periodLabel: key,
        date: acc.date,
        totalSales: acc.totalSales,
        invoiceCount: acc.count,
      );
    }).toList();

    return SalesReportData(
      totalSales: totalSales,
      invoiceCount: invoiceCount,
      averageInvoiceValue: averageInvoiceValue,
      trends: List<SalesTrendPoint>.unmodifiable(trends),
    );
  }

  Future<ExpenseReportData> getExpenseReport(
    ReportDateRange range,
  ) async {
    final expenses = await expenseService.getExpensesByDateRange(
      start: range.start,
      end: _endOfDay(range.end),
    );

    final salaryPayments = await salaryService.getPaymentsByDateRange(
      start: range.start,
      end: _endOfDay(range.end),
    );

    double totalBusiness = 0.0;
    double totalPersonal = 0.0;
    final categoryTotals = <String, _CategoryAccumulator>{};

    for (final exp in expenses) {
      if (exp.isPersonal) {
        totalPersonal += exp.amount;
      } else {
        totalBusiness += exp.amount;
        final cat = exp.category.trim();
        final acc = categoryTotals.putIfAbsent(
          cat,
          () => _CategoryAccumulator(),
        );
        acc.total += exp.amount;
        acc.count += 1;
      }
    }

    final totalSalaryExpenses = salaryPayments
        .where((p) => p.status.toLowerCase() == 'paid')
        .fold<double>(0.0, (sum, p) => sum + p.amount);

    final totalExpenses = totalBusiness + totalSalaryExpenses;

    final categories = categoryTotals.entries.map((entry) {
      final percentage =
          totalBusiness > 0 ? (entry.value.total / totalBusiness) * 100 : 0.0;
      return ExpenseCategoryBreakdown(
        category: entry.key,
        amount: entry.value.total,
        count: entry.value.count,
        percentage: percentage,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return ExpenseReportData(
      totalBusinessExpenses: totalBusiness,
      totalPersonalExpenses: totalPersonal,
      totalSalaryExpenses: totalSalaryExpenses,
      totalExpenses: totalExpenses,
      categories: List<ExpenseCategoryBreakdown>.unmodifiable(categories),
    );
  }

  Future<ProfitReportData> getProfitReport(
    ReportDateRange range,
  ) async {
    final salesReport = await getSalesReport(range);
    final expenseReport = await getExpenseReport(range);

    final totalRevenue = salesReport.totalSales;
    final totalExpenses = expenseReport.totalExpenses;
    final netProfit = totalRevenue - totalExpenses;
    final margin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;

    return ProfitReportData(
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      profitMarginPercentage: margin,
    );
  }

  Future<List<CustomerReportItem>> getTopCustomers(
    ReportDateRange range, {
    int limit = 10,
  }) async {
    final allInvoices = await billingService.getAllInvoices();
    final allServices = await billingService.getAllServices();
    final allCustomers = await customerService.getCustomers();

    final customerById = {for (final c in allCustomers) c.id: c};
    final serviceById = {for (final s in allServices) s.id: s};

    final inRangeInvoices = allInvoices
        .where((inv) => _isDateInRange(inv.createdDate, range))
        .toList();

    final customerSpend = <String, double>{};
    final customerServiceCount = <String, int>{};

    for (final inv in inRangeInvoices) {
      final service = serviceById[inv.serviceId];
      if (service == null) continue;
      final customerId = service.customerId;

      customerSpend[customerId] =
          (customerSpend[customerId] ?? 0.0) + inv.totalAmount;
      customerServiceCount[customerId] =
          (customerServiceCount[customerId] ?? 0) + 1;
    }

    final items = <CustomerReportItem>[];
    for (final entry in customerSpend.entries) {
      final customer = customerById[entry.key];
      if (customer == null) continue;

      items.add(
        CustomerReportItem(
          customerId: customer.id,
          customerName: customer.name,
          customerMobile: customer.mobile,
          vehicleName: customer.vehicleName,
          serviceCount: customerServiceCount[entry.key] ?? 0,
          totalSpent: entry.value,
        ),
      );
    }

    items.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return List<CustomerReportItem>.unmodifiable(items.take(limit));
  }

  Future<List<PartReportItem>> getTopSellingParts(
    ReportDateRange range, {
    int limit = 10,
  }) async {
    final allServices = await billingService.getAllServices();
    final allParts = await partService.getAllParts();
    final partById = {for (final p in allParts) p.id: p};

    final relevantServices = allServices
        .where((s) => _isDateInRange(s.serviceDate, range))
        .toList();

    final quantityByPart = <String, int>{};
    final revenueByPart = <String, double>{};

    for (final service in relevantServices) {
      final serviceParts =
          await billingService.getServiceParts(service.id);
      for (final sp in serviceParts) {
        quantityByPart.update(
          sp.partId,
          (val) => val + sp.quantity,
          ifAbsent: () => sp.quantity,
        );
        revenueByPart.update(
          sp.partId,
          (val) => val + sp.lineTotal,
          ifAbsent: () => sp.lineTotal,
        );
      }
    }

    final items = <PartReportItem>[];
    for (final entry in quantityByPart.entries) {
      final part = partById[entry.key];
      if (part == null) continue;

      items.add(
        PartReportItem(
          partId: part.id,
          partNumber: part.partNumber,
          partName: part.partName,
          category: part.category,
          quantitySold: entry.value,
          totalRevenue: revenueByPart[entry.key] ?? 0.0,
          currentStock: part.currentStock,
        ),
      );
    }

    items.sort((a, b) {
      final cmp = b.quantitySold.compareTo(a.quantitySold);
      if (cmp != 0) return cmp;
      return b.totalRevenue.compareTo(a.totalRevenue);
    });

    return List<PartReportItem>.unmodifiable(items.take(limit));
  }

  Future<SalaryExpenseReportData> getSalaryExpenseReport(
    ReportDateRange range,
  ) async {
    final employees = await salaryService.getEmployees();
    final payments = await salaryService.getPaymentsByDateRange(
      start: range.start,
      end: _endOfDay(range.end),
    );

    double totalPaid = 0.0;
    double totalPending = 0.0;

    final employeePaidMap = <String, double>{};
    final employeePendingMap = <String, double>{};
    final employeeCountMap = <String, int>{};

    for (final p in payments) {
      final isPaid = p.status.toLowerCase() == 'paid';
      if (isPaid) {
        totalPaid += p.amount;
        employeePaidMap[p.employeeId] =
            (employeePaidMap[p.employeeId] ?? 0.0) + p.amount;
      } else {
        totalPending += p.amount;
        employeePendingMap[p.employeeId] =
            (employeePendingMap[p.employeeId] ?? 0.0) + p.amount;
      }
      employeeCountMap[p.employeeId] =
          (employeeCountMap[p.employeeId] ?? 0) + 1;
    }

    final items = employees.map((emp) {
      return SalaryReportItem(
        employeeId: emp.id,
        employeeName: emp.name,
        monthlySalary: emp.monthlySalary,
        paidAmount: employeePaidMap[emp.id] ?? 0.0,
        pendingAmount: employeePendingMap[emp.id] ?? 0.0,
        paymentCount: employeeCountMap[emp.id] ?? 0,
      );
    }).toList();

    return SalaryExpenseReportData(
      totalPaid: totalPaid,
      totalPending: totalPending,
      totalSalaryExpense: totalPaid,
      items: List<SalaryReportItem>.unmodifiable(items),
    );
  }

  Future<InventorySummaryReportData> getInventorySummaryReport() async {
    final parts = await partService.getAllParts();
    final lowStockParts = await partService.getLowStockParts();

    int totalUnits = 0;
    double totalValuation = 0.0;
    final catBreakdown = <String, int>{};

    for (final part in parts) {
      totalUnits += part.currentStock;
      totalValuation += part.currentStock * part.purchasePrice;
      final cat = part.category ?? 'Uncategorized';
      catBreakdown[cat] = (catBreakdown[cat] ?? 0) + 1;
    }

    return InventorySummaryReportData(
      totalPartCount: parts.length,
      totalStockUnits: totalUnits,
      totalInventoryValue: totalValuation,
      lowStockCount: lowStockParts.length,
      categoryBreakdown: Map<String, int>.unmodifiable(catBreakdown),
    );
  }

  bool _isDateInRange(String isoDate, ReportDateRange range) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return false;
    return range.contains(parsed);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
    );
  }
}

class _TrendAccumulator {
  final DateTime date;
  double totalSales = 0.0;
  int count = 0;

  _TrendAccumulator({required this.date});
}

class _CategoryAccumulator {
  double total = 0.0;
  int count = 0;
}
