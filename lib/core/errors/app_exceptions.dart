/// Custom exception types — Services throw these, never raw SQLite/Drift errors.

class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

class InsufficientStockException extends AppException {
  InsufficientStockException(String partName)
      : super('Insufficient stock for part: $partName');
}

class DuplicatePartNumberException extends AppException {
  DuplicatePartNumberException(String partNumber)
      : super('Part number already exists: $partNumber');
}

class NotFoundException extends AppException {
  NotFoundException(String entity, String id)
      : super('$entity not found: $id');
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message);
}