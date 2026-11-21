class ServicePartInput {
  final String partId;
  final int quantity;

  const ServicePartInput({
    required this.partId,
    required this.quantity,
  });
}

class ServicePart {
  final String id;
  final String serviceId;
  final String partId;
  final int quantity;
  final double priceEach;
  final double purchasePriceEach;

  const ServicePart({
    required this.id,
    required this.serviceId,
    required this.partId,
    required this.quantity,
    required this.priceEach,
    this.purchasePriceEach = 0.0,
  });

  double get lineTotal => quantity * priceEach;
  double get costLineTotal => quantity * purchasePriceEach;

  ServicePart copyWith({
    String? id,
    String? serviceId,
    String? partId,
    int? quantity,
    double? priceEach,
    double? purchasePriceEach,
  }) {
    return ServicePart(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      partId: partId ?? this.partId,
      quantity: quantity ?? this.quantity,
      priceEach: priceEach ?? this.priceEach,
      purchasePriceEach: purchasePriceEach ?? this.purchasePriceEach,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'partId': partId,
      'quantity': quantity,
      'priceEach': priceEach,
      'purchasePriceEach': purchasePriceEach,
    };
  }

  factory ServicePart.fromJson(Map<String, dynamic> json) {
    return ServicePart(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      partId: json['partId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      priceEach: (json['priceEach'] as num).toDouble(),
      purchasePriceEach: (json['purchasePriceEach'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServicePart &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            serviceId == other.serviceId &&
            partId == other.partId &&
            quantity == other.quantity &&
            priceEach == other.priceEach &&
            purchasePriceEach == other.purchasePriceEach;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      serviceId,
      partId,
      quantity,
      priceEach,
      purchasePriceEach,
    );
  }

  @override
  String toString() {
    return 'ServicePart('
        'id: $id, '
        'serviceId: $serviceId, '
        'partId: $partId, '
        'quantity: $quantity, '
        'priceEach: $priceEach, '
        'purchasePriceEach: $purchasePriceEach'
        ')';
  }
}