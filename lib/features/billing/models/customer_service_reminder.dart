import '../../customers/models/customer.dart';

class CustomerServiceReminder {
  final Customer customer;
  final DateTime lastServiceDate;
  final DateTime reminderDueDate;
  final bool isDue;
  final int daysOverdue;
  final int daysRemaining;
  final String? lastProblemDesc;
  final String? lastServiceReport;

  const CustomerServiceReminder({
    required this.customer,
    required this.lastServiceDate,
    required this.reminderDueDate,
    required this.isDue,
    required this.daysOverdue,
    required this.daysRemaining,
    this.lastProblemDesc,
    this.lastServiceReport,
  });

  /// Calculates a reminder based on the customer's last service date.
  /// Exactly 6 months after the previous service date.
  factory CustomerServiceReminder.fromLastService({
    required Customer customer,
    required DateTime lastServiceDate,
    DateTime? referenceDate,
    String? lastProblemDesc,
    String? lastServiceReport,
  }) {
    final now = referenceDate ?? DateTime.now();
    final dueDate = calculateSixMonthsLater(lastServiceDate);
    final isDue = !now.isBefore(dueDate);
    final diffDays = now.difference(dueDate).inDays;

    return CustomerServiceReminder(
      customer: customer,
      lastServiceDate: lastServiceDate,
      reminderDueDate: dueDate,
      isDue: isDue,
      daysOverdue: isDue ? (diffDays < 0 ? 0 : diffDays) : 0,
      daysRemaining: isDue ? 0 : -diffDays,
      lastProblemDesc: lastProblemDesc,
      lastServiceReport: lastServiceReport,
    );
  }

  static DateTime calculateSixMonthsLater(DateTime date) {
    var newYear = date.year;
    var newMonth = date.month + 6;
    if (newMonth > 12) {
      newYear += (newMonth - 1) ~/ 12;
      newMonth = ((newMonth - 1) % 12) + 1;
    }
    final daysInMonth = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = date.day > daysInMonth ? daysInMonth : date.day;
    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
    );
  }
}
