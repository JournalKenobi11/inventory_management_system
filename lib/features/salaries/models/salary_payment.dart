class SalaryPayment {
  final String id;
  final String employeeId;
  final double amount;
  final String paymentDate;
  final String status;

  const SalaryPayment({
    required this.id,
    required this.employeeId,
    required this.amount,
    required this.paymentDate,
    required this.status,
  });

  SalaryPayment copyWith({
    String? id,
    String? employeeId,
    double? amount,
    String? paymentDate,
    String? status,
  }) {
    return SalaryPayment(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'amount': amount,
      'paymentDate': paymentDate,
      'status': status,
    };
  }

  factory SalaryPayment.fromJson(Map<String, dynamic> json) {
    return SalaryPayment(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: json['paymentDate'] as String,
      status: json['status'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SalaryPayment &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            employeeId == other.employeeId &&
            amount == other.amount &&
            paymentDate == other.paymentDate &&
            status == other.status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      employeeId,
      amount,
      paymentDate,
      status,
    );
  }

  @override
  String toString() {
    return 'SalaryPayment('
        'id: $id, '
        'employeeId: $employeeId, '
        'amount: $amount, '
        'paymentDate: $paymentDate, '
        'status: $status'
        ')';
  }
}