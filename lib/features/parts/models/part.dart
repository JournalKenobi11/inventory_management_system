class Part {
  final String id;
  final String partNumber;
  final String partName;
  final String? category;
  final double purchasePrice;
  final double sellingPrice;
  final int currentStock;
  final int lowStockThreshold;

  const Part({
    required this.id,
    required this.partNumber,
    required this.partName,
    this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.currentStock,
    required this.lowStockThreshold,
  });

  Part copyWith({
    String? id,
    String? partNumber,
    String? partName,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    int? currentStock,
    int? lowStockThreshold,
  }) {
    return Part(
      id: id ?? this.id,
      partNumber: partNumber ?? this.partNumber,
      partName: partName ?? this.partName,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partNumber': partNumber,
      'partName': partName,
      'category': category,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'currentStock': currentStock,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      id: json['id'] as String,
      partNumber: json['partNumber'] as String,
      partName: json['partName'] as String,
      category: json['category'] as String?,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      currentStock: (json['currentStock'] as num).toInt(),
      lowStockThreshold: (json['lowStockThreshold'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Part &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            partNumber == other.partNumber &&
            partName == other.partName &&
            category == other.category &&
            purchasePrice == other.purchasePrice &&
            sellingPrice == other.sellingPrice &&
            currentStock == other.currentStock &&
            lowStockThreshold == other.lowStockThreshold;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      partNumber,
      partName,
      category,
      purchasePrice,
      sellingPrice,
      currentStock,
      lowStockThreshold,
    );
  }

  @override
  String toString() {
    return 'Part('
        'id: $id, '
        'partNumber: $partNumber, '
        'partName: $partName, '
        'category: $category, '
        'purchasePrice: $purchasePrice, '
        'sellingPrice: $sellingPrice, '
        'currentStock: $currentStock, '
        'lowStockThreshold: $lowStockThreshold'
        ')';
  }
}