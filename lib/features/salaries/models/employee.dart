class Employee {
  final String id;
  final String name;
  final double monthlySalary;

  const Employee({
    required this.id,
    required this.name,
    required this.monthlySalary,
  });

  Employee copyWith({
    String? id,
    String? name,
    double? monthlySalary,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlySalary: monthlySalary ?? this.monthlySalary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'monthlySalary': monthlySalary,
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      monthlySalary: (json['monthlySalary'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Employee &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            monthlySalary == other.monthlySalary;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      monthlySalary,
    );
  }

  @override
  String toString() {
    return 'Employee('
        'id: $id, '
        'name: $name, '
        'monthlySalary: $monthlySalary'
        ')';
  }
}