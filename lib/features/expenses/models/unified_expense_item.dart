/// Represents a unified expense entry that can come from
/// manual expenses, salary payments, or stock purchases.
class UnifiedExpenseItem {
  final String id;
  final String type; // 'expense', 'salary', 'purchase'
  final String category;
  final double amount;
  final String? note;
  final String entryDate;

  const UnifiedExpenseItem({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    this.note,
    required this.entryDate,
  });

  String get typeLabel {
    switch (type) {
      case 'salary':
        return 'Salary';
      case 'purchase':
        return 'Stock Purchase';
      default:
        return 'Expense';
    }
  }
}
