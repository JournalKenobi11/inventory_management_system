import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/id_generator.dart';
import '../models/part.dart';
import '../repositories/interfaces/part_repository.dart';

class PartService {
  final PartRepository repository;

  PartService(this.repository);

  Future<Part> createPart({
    required String partNumber,
    required String partName,
    String? category,
    required double purchasePrice,
    required double sellingPrice,
    int currentStock = 0,
    int lowStockThreshold = 5,
  }) async {
    _validatePart(
      partNumber: partNumber,
      partName: partName,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      currentStock: currentStock,
      lowStockThreshold: lowStockThreshold,
    );

    final existing = await repository.getByPartNumber(partNumber.trim());

    if (existing != null) {
      throw DuplicatePartNumberException(partNumber.trim());
    }

    final part = Part(
      id: IdGenerator.generate(),
      partNumber: partNumber.trim(),
      partName: partName.trim(),
      category: _normalizeCategory(category),
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      currentStock: currentStock,
      lowStockThreshold: lowStockThreshold,
    );

    return repository.create(part);
  }

  Future<Part?> getPartById(String id) {
    return repository.getById(id);
  }

  Future<Part?> getPartByNumber(String partNumber) {
    return repository.getByPartNumber(partNumber.trim());
  }

  Future<List<Part>> getAllParts() {
    return repository.getAll();
  }

  Future<List<Part>> getLowStockParts() {
    return repository.getLowStock();
  }

  Future<void> updatePart(Part part) async {
    _validatePart(
      partNumber: part.partNumber,
      partName: part.partName,
      purchasePrice: part.purchasePrice,
      sellingPrice: part.sellingPrice,
      currentStock: part.currentStock,
      lowStockThreshold: part.lowStockThreshold,
    );

    final existing =
        await repository.getByPartNumber(part.partNumber.trim());

    if (existing != null && existing.id != part.id) {
      throw DuplicatePartNumberException(part.partNumber.trim());
    }

    await repository.update(
      part.copyWith(
        partNumber: part.partNumber.trim(),
        partName: part.partName.trim(),
        category: _normalizeCategory(part.category),
      ),
    );
  }

  Future<void> adjustStock(String partId, int delta) async {
    final part = await repository.getById(partId);

    if (part == null) {
      throw NotFoundException('Part', partId);
    }

    final newStock = part.currentStock + delta;

    if (newStock < 0) {
      throw InsufficientStockException(part.partName);
    }

    await repository.adjustStock(partId, delta);
  }

  Future<void> deletePart(String id) async {
    final part = await repository.getById(id);

    if (part == null) {
      throw NotFoundException('Part', id);
    }

    throw UnsupportedError(
      'Part deletion is not supported by PartRepository.',
    );
  }

  void _validatePart({
    required String partNumber,
    required String partName,
    required double purchasePrice,
    required double sellingPrice,
    required int currentStock,
    required int lowStockThreshold,
  }) {
    if (partNumber.trim().isEmpty) {
      throw ValidationException('Part number cannot be empty.');
    }

    if (partName.trim().isEmpty) {
      throw ValidationException('Part name cannot be empty.');
    }

    if (purchasePrice < 0) {
      throw ValidationException('Purchase price cannot be negative.');
    }

    if (sellingPrice < 0) {
      throw ValidationException('Selling price cannot be negative.');
    }

    if (currentStock < 0) {
      throw ValidationException('Current stock cannot be negative.');
    }

    if (lowStockThreshold < 0) {
      throw ValidationException(
        'Low-stock threshold cannot be negative.',
      );
    }
  }

  String? _normalizeCategory(String? category) {
    final value = category?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }
}