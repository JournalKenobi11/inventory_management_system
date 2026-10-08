class PersonalFinanceMonthlySummary {
  final double openingBalance;
  final double totalCredits;
  final double totalDebits;
  final double netChange;
  final double currentBalance;

  const PersonalFinanceMonthlySummary({
    required this.openingBalance,
    required this.totalCredits,
    required this.totalDebits,
    required this.netChange,
    required this.currentBalance,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PersonalFinanceMonthlySummary &&
            runtimeType == other.runtimeType &&
            openingBalance == other.openingBalance &&
            totalCredits == other.totalCredits &&
            totalDebits == other.totalDebits &&
            netChange == other.netChange &&
            currentBalance == other.currentBalance;
  }

  @override
  int get hashCode => Object.hash(
    openingBalance,
    totalCredits,
    totalDebits,
    netChange,
    currentBalance,
  );

  @override
  String toString() {
    return 'PersonalFinanceMonthlySummary(openingBalance: $openingBalance, totalCredits: $totalCredits, totalDebits: $totalDebits, netChange: $netChange, currentBalance: $currentBalance)';
  }
}
