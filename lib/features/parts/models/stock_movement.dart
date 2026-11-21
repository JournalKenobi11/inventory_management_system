class StockMovement {
  final String id;
  final String partId;
  final int quantityChange;
  final int balanceAfter;
  final String movementType;
  final String? referenceId;
  final String? notes;
  final String createdDate;

  const StockMovement({
    required this.id,
    required this.partId,
    required this.quantityChange,
    required this.balanceAfter,
    required this.movementType,
    this.referenceId,
    this.notes,
    required this.createdDate,
  });

  StockMovement copyWith({
    String? id,
    String? partId,
    int? quantityChange,
    int? balanceAfter,
    String? movementType,
    String? referenceId,
    String? notes,
    String? createdDate,
  }) {
    return StockMovement(
      id: id ?? this.id,
      partId: partId ?? this.partId,
      quantityChange: quantityChange ?? this.quantityChange,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      movementType: movementType ?? this.movementType,
      referenceId: referenceId ?? this.referenceId,
      notes: notes ?? this.notes,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partId': partId,
      'quantityChange': quantityChange,
      'balanceAfter': balanceAfter,
      'movementType': movementType,
      'referenceId': referenceId,
      'notes': notes,
      'createdDate': createdDate,
    };
  }

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      partId: json['partId'] as String,
      quantityChange: (json['quantityChange'] as num).toInt(),
      balanceAfter: (json['balanceAfter'] as num).toInt(),
      movementType: json['movementType'] as String,
      referenceId: json['referenceId'] as String?,
      notes: json['notes'] as String?,
      createdDate: json['createdDate'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StockMovement &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            partId == other.partId &&
            quantityChange == other.quantityChange &&
            balanceAfter == other.balanceAfter &&
            movementType == other.movementType &&
            referenceId == other.referenceId &&
            notes == other.notes &&
            createdDate == other.createdDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      partId,
      quantityChange,
      balanceAfter,
      movementType,
      referenceId,
      notes,
      createdDate,
    );
  }

  @override
  String toString() {
    return 'StockMovement('
        'id: $id, '
        'partId: $partId, '
        'quantityChange: $quantityChange, '
        'balanceAfter: $balanceAfter, '
        'movementType: $movementType, '
        'referenceId: $referenceId, '
        'notes: $notes, '
        'createdDate: $createdDate'
        ')';
  }
}
