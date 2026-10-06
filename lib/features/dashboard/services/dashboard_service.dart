
import '../../billing/models/service.dart';
import '../../billing/repositories/interfaces/invoice_repository.dart';
import '../../billing/repositories/interfaces/service_part_repository.dart';
import '../../billing/repositories/interfaces/service_repository.dart';

import '../../expenses/repositories/interfaces/expense_repository.dart';
import '../../parts/models/part.dart';
import '../../parts/repositories/interfaces/part_repository.dart';

import '../../salaries/repositories/interfaces/salary_payment_repository.dart';
import '../models/dashboard_summary.dart';

class DashboardDateRange {
  final DateTime start;
  final DateTime end;

  DashboardDateRange({
    required DateTime start,
    required DateTime end,
  })  : start = _dateOnly(start),
        end = _dateOnly(end);

  DashboardDateRange.month(DateTime date)
      : start = DateTime(date.year, date.month, 1),
        end = DateTime(date.year, date.month + 1, 0);

  DashboardDateRange.year(DateTime date)
      : start = DateTime(date.year, 1, 1),
        end = DateTime(date.year, 12, 31);

  bool contains(DateTime date) {
    final value = _dateOnly(date);

    return !value.isBefore(start) &&
        !value.isAfter(end);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DashboardDateRange &&
            start == other.start &&
            end == other.end;
  }

  @override
  int get hashCode {
    return Object.hash(start, end);
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }
}

class DashboardService {
  final InvoiceRepository invoiceRepository;
  final ServiceRepository serviceRepository;
  final ServicePartRepository servicePartRepository;
  final ExpenseRepository expenseRepository;
  final SalaryPaymentRepository salaryPaymentRepository;
  final PartRepository partRepository;

  DashboardService({
    required this.invoiceRepository,
    required this.serviceRepository,
    required this.servicePartRepository,
    required this.expenseRepository,
    required this.salaryPaymentRepository,
    required this.partRepository,
  });

  Future<DashboardSummary> getSummary(
    DashboardDateRange range,
  ) async {
    final invoices = await invoiceRepository.getAll();
    final services = await serviceRepository.getAll();

    final expenses = await expenseRepository.getByDateRange(
      start: range.start,
      end: _endOfDay(range.end),
    );

    final salaryPayments =
        await salaryPaymentRepository.getByDateRange(
      start: range.start,
      end: _endOfDay(range.end),
    );

    final parts = await partRepository.getAll();
    final lowStockParts = await partRepository.getLowStock();

    final totalSales = invoices
        .where(
          (invoice) =>
              _isDateInRange(invoice.createdDate, range),
        )
        .fold<double>(
          0,
          (total, invoice) =>
              total + invoice.totalAmount,
        );

    final businessExpenses = expenses
        .where(
          (expense) =>
              !expense.isPersonal &&
              _isDateInRange(expense.entryDate, range),
        )
        .fold<double>(
          0,
          (total, expense) =>
              total + expense.amount,
        );

    final salaryExpenses = salaryPayments
        .where(
          (payment) =>
              payment.status.toLowerCase() == 'paid' &&
              _isDateInRange(payment.paymentDate, range),
        )
        .fold<double>(
          0,
          (total, payment) =>
              total + payment.amount,
        );

    final totalExpenses =
        businessExpenses + salaryExpenses;

    final profit = totalSales - totalExpenses;

    final servicesCompleted = services
        .where(
          (service) =>
              _isDateInRange(service.serviceDate, range),
        )
        .length;

    final inventoryValue = parts.fold<double>(
      0,
      (total, part) =>
          total +
          (part.currentStock * part.purchasePrice),
    );

    final topSellingParts =
        await _calculateTopSellingParts(
      services: services,
      range: range,
      parts: parts,
    );

    return DashboardSummary(
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      profit: profit,
      servicesCompleted: servicesCompleted,
      inventoryValue: inventoryValue,
      lowStockParts: List<Part>.unmodifiable(
        lowStockParts,
      ),
      topSellingParts:
          List<DashboardPartSales>.unmodifiable(
        topSellingParts,
      ),
    );
  }

  Future<List<DashboardPartSales>>
      _calculateTopSellingParts({
    required List<Service> services,
    required DashboardDateRange range,
    required List<Part> parts,
  }) async {
    final relevantServices = services
        .where(
          (service) =>
              _isDateInRange(service.serviceDate, range),
        )
        .toList();

    final quantityByPart = <String, int>{};
    final revenueByPart = <String, double>{};

    for (final service in relevantServices) {
      final serviceParts =
          await servicePartRepository.getByServiceId(
        service.id,
      );

      for (final servicePart in serviceParts) {
        quantityByPart.update(
          servicePart.partId,
          (value) => value + servicePart.quantity,
          ifAbsent: () => servicePart.quantity,
        );

        revenueByPart.update(
          servicePart.partId,
          (value) => value + servicePart.lineTotal,
          ifAbsent: () => servicePart.lineTotal,
        );
      }
    }

    final partById = <String, Part>{
      for (final part in parts)
        part.id: part,
    };

    final result = <DashboardPartSales>[];

    for (final entry in quantityByPart.entries) {
      final Part? part = partById[entry.key];

      if (part == null) {
        continue;
      }

      result.add(
        DashboardPartSales(
          partId: part.id,
          partName: part.partName,
          quantitySold: entry.value,
          revenue: revenueByPart[entry.key] ?? 0,
        ),
      );
    }

    result.sort(
      (DashboardPartSales a, DashboardPartSales b) {
        final quantityComparison =
            b.quantitySold.compareTo(a.quantitySold);

        if (quantityComparison != 0) {
          return quantityComparison;
        }

        final revenueComparison =
            b.revenue.compareTo(a.revenue);

        if (revenueComparison != 0) {
          return revenueComparison;
        }

        return a.partName
            .toLowerCase()
            .compareTo(
              b.partName.toLowerCase(),
            );
      },
    );

    return result.take(5).toList();
  }

  bool _isDateInRange(
    String isoDate,
    DashboardDateRange range,
  ) {
    final parsed = DateTime.tryParse(isoDate);

    if (parsed == null) {
      return false;
    }

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