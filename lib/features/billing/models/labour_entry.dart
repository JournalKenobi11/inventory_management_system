class LabourEntry {
  final String description;
  final double charge;

  const LabourEntry({
    required this.description,
    required this.charge,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'charge': charge,
      };

  factory LabourEntry.fromJson(Map<String, dynamic> json) => LabourEntry(
        description: json['description'] as String? ?? '',
        charge: (json['charge'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabourEntry &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          charge == other.charge;

  @override
  int get hashCode => Object.hash(description, charge);

  @override
  String toString() => 'LabourEntry(description: $description, charge: $charge)';
}
