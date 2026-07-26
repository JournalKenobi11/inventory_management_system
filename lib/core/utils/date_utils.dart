/// ISO8601 helpers — every date in the DB is stored/read through here.
class AppDateUtils {
  static String nowIso() => DateTime.now().toIso8601String();
  static String toIso(DateTime date) => date.toIso8601String();
  static DateTime fromIso(String iso) => DateTime.parse(iso);
}