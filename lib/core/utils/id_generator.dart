import 'package:uuid/uuid.dart';

/// Single place IDs are generated — keeps UUID generation swappable.
class IdGenerator {
  static const _uuid = Uuid();
  static String generate() => _uuid.v4();
}