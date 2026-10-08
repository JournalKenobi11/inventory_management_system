enum AttendancePeriod {
  thisMonth('This Month'),
  lastMonth('Last Month'),
  thisYear('This Year'),
  allTime('All Time');

  final String label;
  const AttendancePeriod(this.label);

  /// Returns date boundaries `(startDate, endDate)` in 'YYYY-MM-DD' format,
  /// or null for all time.
  ({String? startDate, String? endDate}) getDateRange([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();

    switch (this) {
      case AttendancePeriod.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0); // last day of month
        return (
          startDate: _formatDate(start),
          endDate: _formatDate(end),
        );

      case AttendancePeriod.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        final start = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
        final end = DateTime(lastMonthDate.year, lastMonthDate.month + 1, 0);
        return (
          startDate: _formatDate(start),
          endDate: _formatDate(end),
        );

      case AttendancePeriod.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31);
        return (
          startDate: _formatDate(start),
          endDate: _formatDate(end),
        );

      case AttendancePeriod.allTime:
        return (startDate: null, endDate: null);
    }
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
