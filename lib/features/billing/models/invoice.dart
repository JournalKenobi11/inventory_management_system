class Invoice {
  final String id;
  final int invoiceNumber;
  final String serviceId;
  final double totalAmount;
  final String createdDate;
  final double advanceAmount;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.serviceId,
    required this.totalAmount,
    required this.createdDate,
    this.advanceAmount = 0.0,
  });

  double get balanceDue =>
      (totalAmount - advanceAmount).clamp(0.0, double.infinity);

  Invoice copyWith({
    String? id,
    int? invoiceNumber,
    String? serviceId,
    double? totalAmount,
    String? createdDate,
    double? advanceAmount,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      serviceId: serviceId ?? this.serviceId,
      totalAmount: totalAmount ?? this.totalAmount,
      createdDate: createdDate ?? this.createdDate,
      advanceAmount: advanceAmount ?? this.advanceAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'serviceId': serviceId,
      'totalAmount': totalAmount,
      'createdDate': createdDate,
      'advanceAmount': advanceAmount,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: (json['invoiceNumber'] as num).toInt(),
      serviceId: json['serviceId'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      createdDate: json['createdDate'] as String,
      advanceAmount: (json['advanceAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Invoice &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            invoiceNumber == other.invoiceNumber &&
            serviceId == other.serviceId &&
            totalAmount == other.totalAmount &&
            createdDate == other.createdDate &&
            advanceAmount == other.advanceAmount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      invoiceNumber,
      serviceId,
      totalAmount,
      createdDate,
      advanceAmount,
    );
  }

  @override
  String toString() {
    return 'Invoice('
        'id: $id, '
        'invoiceNumber: $invoiceNumber, '
        'serviceId: $serviceId, '
        'totalAmount: $totalAmount, '
        'createdDate: $createdDate, '
        'advanceAmount: $advanceAmount'
        ')';
  }
}