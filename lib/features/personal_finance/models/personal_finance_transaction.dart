class PersonalFinanceTransaction {
  final String id;
  final String accountId;
  final String type; // 'credit' | 'debit'
  final double amount; // Always positive
  final String category;
  final String? payee;
  final String? note;
  final String transactionDate;

  const PersonalFinanceTransaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.category,
    this.payee,
    this.note,
    required this.transactionDate,
  }) : assert(amount > 0, 'Amount must be greater than zero');

  bool get isCredit => type.toLowerCase() == 'credit';
  bool get isDebit => type.toLowerCase() == 'debit';

  PersonalFinanceTransaction copyWith({
    String? id,
    String? accountId,
    String? type,
    double? amount,
    String? category,
    String? payee,
    String? note,
    String? transactionDate,
  }) {
    return PersonalFinanceTransaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      payee: payee ?? this.payee,
      note: note ?? this.note,
      transactionDate: transactionDate ?? this.transactionDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'type': type,
      'amount': amount,
      'category': category,
      'payee': payee,
      'note': note,
      'transactionDate': transactionDate,
    };
  }

  factory PersonalFinanceTransaction.fromJson(Map<String, dynamic> json) {
    return PersonalFinanceTransaction(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      payee: json['payee'] as String?,
      note: json['note'] as String?,
      transactionDate: json['transactionDate'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PersonalFinanceTransaction &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            accountId == other.accountId &&
            type == other.type &&
            amount == other.amount &&
            category == other.category &&
            payee == other.payee &&
            note == other.note &&
            transactionDate == other.transactionDate;
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    type,
    amount,
    category,
    payee,
    note,
    transactionDate,
  );

  @override
  String toString() {
    return 'PersonalFinanceTransaction(id: $id, accountId: $accountId, type: $type, amount: $amount, category: $category, payee: $payee, note: $note, transactionDate: $transactionDate)';
  }
}
