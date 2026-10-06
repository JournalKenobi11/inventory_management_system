import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../billing/billing.dart';
import '../../customers/customers.dart';
import '../../expenses/expenses.dart';
import '../../parts/parts.dart';
import '../../salaries/salaries.dart';
import '../models/report_models.dart';
import '../services/report_service.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(
    billingService: ref.watch(billingServiceProvider),
    customerService: ref.watch(customerServiceProvider),
    partService: ref.watch(partServiceProvider),
    expenseService: ref.watch(expenseServiceProvider),
    salaryService: ref.watch(salaryServiceProvider),
  );
});

final selectedReportRangeProvider =
    NotifierProvider<ReportDateRangeNotifier, ReportDateRange>(
  ReportDateRangeNotifier.new,
);

class ReportDateRangeNotifier extends Notifier<ReportDateRange> {
  @override
  ReportDateRange build() {
    return ReportDateRange.month(DateTime.now());
  }

  void setThisMonth() {
    state = ReportDateRange.month(DateTime.now());
  }

  void setThisYear() {
    state = ReportDateRange.year(DateTime.now());
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = ReportDateRange(start: start, end: end);
  }

  void setRange(ReportDateRange range) {
    state = range;
  }
}

final comprehensiveReportProvider =
    FutureProvider.family<ComprehensiveReport, ReportDateRange>(
  (ref, range) {
    final service = ref.watch(reportServiceProvider);
    return service.getComprehensiveReport(range);
  },
);

final currentComprehensiveReportProvider =
    FutureProvider<ComprehensiveReport>((ref) {
  final range = ref.watch(selectedReportRangeProvider);
  return ref.watch(comprehensiveReportProvider(range).future);
});

final inventorySummaryProvider =
    FutureProvider<InventorySummaryReportData>((ref) {
  final service = ref.watch(reportServiceProvider);
  return service.getInventorySummaryReport();
});
