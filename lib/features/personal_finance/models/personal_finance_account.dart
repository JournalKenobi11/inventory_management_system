class PersonalFinanceAccount {
  final String id;
  final String name;
  final double openingBalance;
  final String createdDate;

  const PersonalFinanceAccount({
    required this.id,
    required this.name,
    required this.openingBalance,
    required this.createdDate,
  });

  PersonalFinanceAccount copyWith({
    String? id,
    String? name,
    double? openingBalance,
    String? createdDate,
  }) {
    return PersonalFinanceAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      openingBalance: openingBalance ?? this.openingBalance,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'openingBalance': openingBalance,
      'createdDate': createdDate,
    };
  }

  factory PersonalFinanceAccount.fromJson(Map<String, dynamic> json) {
    return PersonalFinanceAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      openingBalance: (json['openingBalance'] as num).toDouble(),
      createdDate: json['createdDate'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PersonalFinanceAccount &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            openingBalance == other.openingBalance &&
            createdDate == other.createdDate;
  }

  @override
  int get hashCode => Object.hash(id, name, openingBalance, createdDate);

  @override
  String toString() {
    return 'PersonalFinanceAccount(id: $id, name: $name, openingBalance: $openingBalance, createdDate: $createdDate)';
  }
}
