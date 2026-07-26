class Customer {
  final String id;
  final String name;
  final String mobile;
  final String? vehicleName;
  final String createdDate;

  const Customer({
    required this.id,
    required this.name,
    required this.mobile,
    this.vehicleName,
    required this.createdDate,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? mobile,
    String? vehicleName,
    String? createdDate,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      vehicleName: vehicleName ?? this.vehicleName,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'vehicleName': vehicleName,
      'createdDate': createdDate,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      vehicleName: json['vehicleName'] as String?,
      createdDate: json['createdDate'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Customer &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            mobile == other.mobile &&
            vehicleName == other.vehicleName &&
            createdDate == other.createdDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      mobile,
      vehicleName,
      createdDate,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, mobile: $mobile, '
        'vehicleName: $vehicleName, createdDate: $createdDate)';
  }
}