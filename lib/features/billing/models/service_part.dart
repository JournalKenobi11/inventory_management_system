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

  const ServicePart({
    required this.id,
    required this.serviceId,
    required this.partId,
    required this.quantity,
    required this.priceEach,
  });

  double get lineTotal => quantity * priceEach;

  ServicePart copyWith({
    String? id,
    String? serviceId,
    String? partId,
    int? quantity,
    double? priceEach,
  }) {
    return ServicePart(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      partId: partId ?? this.partId,
      quantity: quantity ?? this.quantity,
      priceEach: priceEach ?? this.priceEach,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'partId': partId,
      'quantity': quantity,
      'priceEach': priceEach,
    };
  }

  factory ServicePart.fromJson(Map<String, dynamic> json) {
    return ServicePart(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      partId: json['partId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      priceEach: (json['priceEach'] as num).toDouble(),
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
            priceEach == other.priceEach;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      serviceId,
      partId,
      quantity,
      priceEach,
    );
  }

  @override
  String toString() {
    return 'ServicePart('
        'id: $id, '
        'serviceId: $serviceId, '
        'partId: $partId, '
        'quantity: $quantity, '
        'priceEach: $priceEach'
        ')';
  }
}