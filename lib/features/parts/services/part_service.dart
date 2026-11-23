import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/part.dart';
import '../models/stock_movement.dart';
import '../repositories/interfaces/part_repository.dart';
import '../repositories/interfaces/stock_movement_repository.dart';

class PartService {
  final PartRepository repository;
  final StockMovementRepository? stockMovementRepository;

  PartService(this.repository, [this.stockMovementRepository]);

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
      partName: partName.trim().toUpperCase(),
      category: _normalizeCategory(category),
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      currentStock: currentStock,
      lowStockThreshold: lowStockThreshold,
    );

    final created = await repository.create(part);

    if (currentStock > 0 && stockMovementRepository != null) {
      await stockMovementRepository!.create(
        StockMovement(
          id: IdGenerator.generate(),
          partId: created.id,
          quantityChange: currentStock,
          balanceAfter: currentStock,
          movementType: 'initial',
          referenceId: null,
          notes: 'Initial stock on creation',
          createdDate: AppDateUtils.nowIso(),
        ),
      );
    }

    return created;
  }

  Future<Part?> getPartById(String id) {
    return repository.getById(id);
  }

  Future<Part?> getPartByNumber(String partNumber) {
    return repository.getByPartNumber(partNumber.trim());
  }

  /// Sorts a list of parts according to inventory priority:
  /// 1. Low stock parts first (`currentStock <= lowStockThreshold`).
  /// 2. Among low stock parts, lowest stock first (e.g., 0 stock at the top).
  /// 3. Normal in-stock parts next (`currentStock > lowStockThreshold`), sorted alphabetically by partName.
  List<Part> sortPartsByInventoryPriority(List<Part> parts) {
    return List<Part>.from(parts)..sort(compareByInventoryPriority);
  }

  /// Comparator implementing the inventory priority ordering.
  static int compareByInventoryPriority(Part a, Part b) {
    final aIsLow = a.currentStock <= a.lowStockThreshold;
    final bIsLow = b.currentStock <= b.lowStockThreshold;

    // 1. Low stock parts first
    if (aIsLow && !bIsLow) return -1;
    if (!aIsLow && bIsLow) return 1;

    // 2. Among low stock parts, lowest stock first
    if (aIsLow && bIsLow) {
      final stockCompare = a.currentStock.compareTo(b.currentStock);
      if (stockCompare != 0) return stockCompare;
      final nameCompare =
          a.partName.toLowerCase().compareTo(b.partName.toLowerCase());
      if (nameCompare != 0) return nameCompare;
      return a.partNumber.toLowerCase().compareTo(b.partNumber.toLowerCase());
    }

    // 3. Normal in-stock parts sorted alphabetically by partName
    final nameCompare =
        a.partName.toLowerCase().compareTo(b.partName.toLowerCase());
    if (nameCompare != 0) return nameCompare;
    return a.partNumber.toLowerCase().compareTo(b.partNumber.toLowerCase());
  }

  Future<List<Part>> getAllParts() async {
    final parts = await repository.getAll();
    return sortPartsByInventoryPriority(parts);
  }

  Future<List<Part>> getLowStockParts() async {
    final parts = await repository.getLowStock();
    return sortPartsByInventoryPriority(parts);
  }

  Future<List<StockMovement>> getStockMovements(String partId) async {
    if (stockMovementRepository == null) return [];
    return stockMovementRepository!.getByPartId(partId);
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
        partName: part.partName.trim().toUpperCase(),
        category: _normalizeCategory(part.category),
      ),
    );
  }

  Future<void> adjustStock(
    String partId,
    int delta, {
    String movementType = 'adjustment',
    String? referenceId,
    String? notes,
  }) async {
    final part = await repository.getById(partId);

    if (part == null) {
      throw NotFoundException('Part', partId);
    }

    final newStock = part.currentStock + delta;

    if (newStock < 0) {
      throw InsufficientStockException(part.partName);
    }

    await repository.adjustStock(partId, delta);

    if (stockMovementRepository != null) {
      await stockMovementRepository!.create(
        StockMovement(
          id: IdGenerator.generate(),
          partId: partId,
          quantityChange: delta,
          balanceAfter: newStock,
          movementType: movementType,
          referenceId: referenceId,
          notes: notes,
          createdDate: AppDateUtils.nowIso(),
        ),
      );
    }
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