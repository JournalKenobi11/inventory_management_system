
class Expense {
  final String id;
  final String category;
  final bool isPersonal;
  final double amount;
  final String? note;
  final String entryDate;

  const Expense({
    required this.id,
    required this.category,
    required this.isPersonal,
    required this.amount,
    this.note,
    required this.entryDate,
  });

  Expense copyWith({
    String? id,
    String? category,
    bool? isPersonal,
    double? amount,
    String? note,
    String? entryDate,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      isPersonal: isPersonal ?? this.isPersonal,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      entryDate: entryDate ?? this.entryDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'isPersonal': isPersonal,
      'amount': amount,
      'note': note,
      'entryDate': entryDate,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      category: json['category'] as String,
      isPersonal: json['isPersonal'] as bool,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      entryDate: json['entryDate'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Expense &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            category == other.category &&
            isPersonal == other.isPersonal &&
            amount == other.amount &&
            note == other.note &&
            entryDate == other.entryDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      category,
      isPersonal,
      amount,
      note,
      entryDate,
    );
  }

  @override
  String toString() {
    return 'Expense('
        'id: $id, '
        'category: $category, '
        'isPersonal: $isPersonal, '
        'amount: $amount, '
        'note: $note, '
        'entryDate: $entryDate'
        ')';
  }
}
