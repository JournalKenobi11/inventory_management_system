class Service {
  final String id;
  final String customerId;
  final String? problemDesc;
  final double labourCharge;
  final String serviceDate;
  final String? invoiceId;

  const Service({
    required this.id,
    required this.customerId,
    this.problemDesc,
    required this.labourCharge,
    required this.serviceDate,
    this.invoiceId,
  });

  Service copyWith({
    String? id,
    String? customerId,
    String? problemDesc,
    double? labourCharge,
    String? serviceDate,
    String? invoiceId,
  }) {
    return Service(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      problemDesc: problemDesc ?? this.problemDesc,
      labourCharge: labourCharge ?? this.labourCharge,
      serviceDate: serviceDate ?? this.serviceDate,
      invoiceId: invoiceId ?? this.invoiceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'problemDesc': problemDesc,
      'labourCharge': labourCharge,
      'serviceDate': serviceDate,
      'invoiceId': invoiceId,
    };
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      problemDesc: json['problemDesc'] as String?,
      labourCharge: (json['labourCharge'] as num).toDouble(),
      serviceDate: json['serviceDate'] as String,
      invoiceId: json['invoiceId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Service &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            customerId == other.customerId &&
            problemDesc == other.problemDesc &&
            labourCharge == other.labourCharge &&
            serviceDate == other.serviceDate &&
            invoiceId == other.invoiceId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      problemDesc,
      labourCharge,
      serviceDate,
      invoiceId,
    );
  }

  @override
  String toString() {
    return 'Service('
        'id: $id, '
        'customerId: $customerId, '
        'problemDesc: $problemDesc, '
        'labourCharge: $labourCharge, '
        'serviceDate: $serviceDate, '
        'invoiceId: $invoiceId'
        ')';
  }
}