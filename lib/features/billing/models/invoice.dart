class Invoice {
  final String id;
  final int invoiceNumber;
  final String serviceId;
  final double totalAmount;
  final String createdDate;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.serviceId,
    required this.totalAmount,
    required this.createdDate,
  });

  Invoice copyWith({
    String? id,
    int? invoiceNumber,
    String? serviceId,
    double? totalAmount,
    String? createdDate,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      serviceId: serviceId ?? this.serviceId,
      totalAmount: totalAmount ?? this.totalAmount,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'serviceId': serviceId,
      'totalAmount': totalAmount,
      'createdDate': createdDate,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: (json['invoiceNumber'] as num).toInt(),
      serviceId: json['serviceId'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      createdDate: json['createdDate'] as String,
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
            createdDate == other.createdDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      invoiceNumber,
      serviceId,
      totalAmount,
      createdDate,
    );
  }

  @override
  String toString() {
    return 'Invoice('
        'id: $id, '
        'invoiceNumber: $invoiceNumber, '
        'serviceId: $serviceId, '
        'totalAmount: $totalAmount, '
        'createdDate: $createdDate'
        ')';
  }
}