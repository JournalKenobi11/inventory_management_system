class PersonalFinanceCategories {
  static const List<String> debitCategories = [
    'Food',
    'Transport',
    'Family',
    'Shopping',
    'Bills',
    'Medical',
    'Entertainment',
    'Miscellaneous',
    'Other',
  ];

  static const List<String> creditCategories = [
    'Salary',
    'Business Withdrawal',
    'Gift',
    'Refund',
    'Other Income',
    'Miscellaneous',
    'Other',
  ];

  static List<String> forType(String type) {
    if (type.toLowerCase() == 'credit') {
      return creditCategories;
    }
    return debitCategories;
  }
}
