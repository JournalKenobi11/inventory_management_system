class ReportingTime implements Comparable<ReportingTime> {
  final int hour; // 0..23
  final int minute; // 0..59

  const ReportingTime(this.hour, this.minute)
      : assert(hour >= 0 && hour <= 23, 'Hour must be between 0 and 23'),
        assert(minute >= 0 && minute <= 59, 'Minute must be between 0 and 59');

  int get totalMinutes => hour * 60 + minute;

  bool isAfter(ReportingTime other) => totalMinutes > other.totalMinutes;

  bool isAtOrBefore(ReportingTime other) => totalMinutes <= other.totalMinutes;

  bool isBefore(ReportingTime other) => totalMinutes < other.totalMinutes;

  /// Returns 24-hour time representation: "HH:mm" (e.g. "10:30", "09:05")
  String to24HourString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Returns 12-hour display string: "10:30 AM", "01:15 PM"
  String toDisplayString() {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  /// Parses strings like "10:30", "10:30 AM", "10:30:00"
  static ReportingTime parse(String value) {
    final parsed = tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid reporting time format: "$value"');
    }
    return parsed;
  }

  /// Tries to parse strings like "10:30", "10:30 AM", "10:30 PM", "10:30:00"
  static ReportingTime? tryParse(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final upper = trimmed.toUpperCase();
    final isPm = upper.contains('PM');
    final isAm = upper.contains('AM');

    final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
    final parts = clean.split(':');
    if (parts.length < 2) return null;

    final parsedHour = int.tryParse(parts[0].trim());
    final parsedMinute = int.tryParse(parts[1].trim());

    if (parsedHour == null || parsedMinute == null) return null;
    if (parsedMinute < 0 || parsedMinute > 59) return null;

    var hour = parsedHour;
    if (isPm || isAm) {
      if (hour < 1 || hour > 12) return null;
      if (isPm && hour != 12) {
        hour += 12;
      } else if (isAm && hour == 12) {
        hour = 0;
      }
    } else {
      if (hour < 0 || hour > 23) return null;
    }

    return ReportingTime(hour, parsedMinute);
  }

  @override
  int compareTo(ReportingTime other) {
    return totalMinutes.compareTo(other.totalMinutes);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReportingTime &&
            runtimeType == other.runtimeType &&
            hour == other.hour &&
            minute == other.minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => toDisplayString();
}
