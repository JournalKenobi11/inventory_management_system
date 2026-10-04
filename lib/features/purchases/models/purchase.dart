class Purchase {
  final String id;
  final String partId;
  final int quantity;
  final double purchasePrice;
  final String purchaseDate;

  const Purchase({
    required this.id,
    required this.partId,
    required this.quantity,
    required this.purchasePrice,
    required this.purchaseDate,
  });

  Purchase copyWith({
    String? id,
    String? partId,
    int? quantity,
    double? purchasePrice,
    String? purchaseDate,
  }) {
    return Purchase(
      id: id ?? this.id,
      partId: partId ?? this.partId,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partId': partId,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate,
    };
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as String,
      partId: json['partId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      purchaseDate: json['purchaseDate'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Purchase &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            partId == other.partId &&
            quantity == other.quantity &&
            purchasePrice == other.purchasePrice &&
            purchaseDate == other.purchaseDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      partId,
      quantity,
      purchasePrice,
      purchaseDate,
    );
  }

  @override
  String toString() {
    return 'Purchase('
        'id: $id, '
        'partId: $partId, '
        'quantity: $quantity, '
        'purchasePrice: $purchasePrice, '
        'purchaseDate: $purchaseDate'
        ')';
  }
}