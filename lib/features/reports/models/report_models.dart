class ReportDateRange {
  final DateTime start;
  final DateTime end;
  final String label;

  ReportDateRange({
    required DateTime start,
    required DateTime end,
    String? label,
  })  : start = _dateOnly(start),
        end = _dateOnly(end),
        label = label ?? '${_formatDate(start)} - ${_formatDate(end)}';

  ReportDateRange.month(DateTime date)
      : start = DateTime(date.year, date.month, 1),
        end = DateTime(date.year, date.month + 1, 0),
        label = _monthName(date.month) + ' ' + date.year.toString();

  ReportDateRange.year(DateTime date)
      : start = DateTime(date.year, 1, 1),
        end = DateTime(date.year, 12, 31),
        label = 'Year ${date.year}';

  bool contains(DateTime date) {
    final value = _dateOnly(date);
    return !value.isBefore(start) && !value.isAfter(end);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReportDateRange &&
            start == other.start &&
            end == other.end &&
            label == other.label;
  }

  @override
  int get hashCode => Object.hash(start, end, label);

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

class SalesTrendPoint {
  final String periodLabel;
  final DateTime date;
  final double totalSales;
  final int invoiceCount;

  const SalesTrendPoint({
    required this.periodLabel,
    required this.date,
    required this.totalSales,
    required this.invoiceCount,
  });
}

class SalesReportData {
  final double totalSales;
  final int invoiceCount;
  final double averageInvoiceValue;
  final List<SalesTrendPoint> trends;

  const SalesReportData({
    required this.totalSales,
    required this.invoiceCount,
    required this.averageInvoiceValue,
    required this.trends,
  });
}

class ExpenseCategoryBreakdown {
  final String category;
  final double amount;
  final int count;
  final double percentage;

  const ExpenseCategoryBreakdown({
    required this.category,
    required this.amount,
    required this.count,
    required this.percentage,
  });
}

class ExpenseReportData {
  final double totalBusinessExpenses;
  final double totalPersonalExpenses;
  final double totalSalaryExpenses;
  final double totalExpenses;
  final List<ExpenseCategoryBreakdown> categories;

  const ExpenseReportData({
    required this.totalBusinessExpenses,
    required this.totalPersonalExpenses,
    required this.totalSalaryExpenses,
    required this.totalExpenses,
    required this.categories,
  });
}

class ProfitReportData {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double profitMarginPercentage;

  const ProfitReportData({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMarginPercentage,
  });
}

class CustomerReportItem {
  final String customerId;
  final String customerName;
  final String customerMobile;
  final String? vehicleName;
  final int serviceCount;
  final double totalSpent;

  const CustomerReportItem({
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    this.vehicleName,
    required this.serviceCount,
    required this.totalSpent,
  });
}

class PartReportItem {
  final String partId;
  final String partNumber;
  final String partName;
  final String? category;
  final int quantitySold;
  final double totalRevenue;
  final int currentStock;

  const PartReportItem({
    required this.partId,
    required this.partNumber,
    required this.partName,
    this.category,
    required this.quantitySold,
    required this.totalRevenue,
    required this.currentStock,
  });
}

class SalaryReportItem {
  final String employeeId;
  final String employeeName;
  final double monthlySalary;
  final double paidAmount;
  final double pendingAmount;
  final int paymentCount;

  const SalaryReportItem({
    required this.employeeId,
    required this.employeeName,
    required this.monthlySalary,
    required this.paidAmount,
    required this.pendingAmount,
    required this.paymentCount,
  });
}

class SalaryExpenseReportData {
  final double totalPaid;
  final double totalPending;
  final double totalSalaryExpense;
  final List<SalaryReportItem> items;

  const SalaryExpenseReportData({
    required this.totalPaid,
    required this.totalPending,
    required this.totalSalaryExpense,
    required this.items,
  });
}

class InventorySummaryReportData {
  final int totalPartCount;
  final int totalStockUnits;
  final double totalInventoryValue;
  final int lowStockCount;
  final Map<String, int> categoryBreakdown;

  const InventorySummaryReportData({
    required this.totalPartCount,
    required this.totalStockUnits,
    required this.totalInventoryValue,
    required this.lowStockCount,
    required this.categoryBreakdown,
  });
}

class ComprehensiveReport {
  final ReportDateRange range;
  final DateTime generatedAt;
  final SalesReportData sales;
  final ExpenseReportData expenses;
  final ProfitReportData profit;
  final int servicesCompleted;
  final List<CustomerReportItem> topCustomers;
  final List<PartReportItem> topParts;
  final SalaryExpenseReportData salaries;
  final InventorySummaryReportData inventory;

  const ComprehensiveReport({
    required this.range,
    required this.generatedAt,
    required this.sales,
    required this.expenses,
    required this.profit,
    required this.servicesCompleted,
    required this.topCustomers,
    required this.topParts,
    required this.salaries,
    required this.inventory,
  });
}
