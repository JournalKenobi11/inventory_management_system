import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../parts/parts.dart';
import '../../purchases/purchases.dart';
import '../../salaries/salaries.dart';
import '../models/unified_expense_item.dart';

/// Provides salary payments formatted as unified expense items.
final salaryExpensesProvider =
    FutureProvider<List<UnifiedExpenseItem>>((ref) async {
  final salaryService = ref.watch(salaryServiceProvider);

  final payments = await salaryService.getSalaryPayments();
  final employees = await salaryService.getEmployees();

  final employeeById = <String, Employee>{
    for (final emp in employees) emp.id: emp,
  };

  // Only include paid salary payments.
  final paidPayments = payments
      .where((p) => p.status.toLowerCase() == 'paid')
      .toList();

  return paidPayments.map((SalaryPayment payment) {
    final employee = employeeById[payment.employeeId];
    final employeeName = employee?.name ?? 'Unknown Employee';

    return UnifiedExpenseItem(
      id: payment.id,
      type: 'salary',
      category: 'Salary',
      amount: payment.amount,
      note: employeeName,
      entryDate: payment.paymentDate,
    );
  }).toList()
    ..sort((a, b) => b.entryDate.compareTo(a.entryDate));
});

/// Provides stock purchases formatted as unified expense items.
final purchaseExpensesProvider =
    FutureProvider<List<UnifiedExpenseItem>>((ref) async {
  final purchaseService = ref.watch(purchaseServiceProvider);
  final partService = ref.watch(partServiceProvider);

  final purchases = await purchaseService.getAllPurchases();
  final parts = await partService.getAllParts();

  final partById = <String, Part>{
    for (final part in parts) part.id: part,
  };

  return purchases.map((Purchase purchase) {
    final part = partById[purchase.partId];
    final partName = part?.partName ?? 'Unknown Part';
    final totalCost = purchase.purchasePrice * purchase.quantity;

    return UnifiedExpenseItem(
      id: purchase.id,
      type: 'purchase',
      category: 'Stock Purchase',
      amount: totalCost,
      note: '$partName × ${purchase.quantity}',
      entryDate: purchase.purchaseDate,
    );
  }).toList()
    ..sort((a, b) => b.entryDate.compareTo(a.entryDate));
});
