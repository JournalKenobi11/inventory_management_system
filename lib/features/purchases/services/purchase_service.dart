import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/id_generator.dart';
import '../../../database/app_database.dart' hide Purchase;
import '../../parts/services/part_service.dart';
import '../models/purchase.dart';
import '../repositories/interfaces/purchase_repository.dart';

class PurchaseService {
  final PurchaseRepository purchaseRepository;
  final PartService partService;
  final AppDatabase database;

  PurchaseService(
    this.purchaseRepository,
    this.partService,
    this.database,
  );

  Future<Purchase> recordPurchase({
    required String partId,
    required int quantity,
    required double price,
  }) async {
    if (partId.trim().isEmpty) {
      throw ValidationException('Part ID cannot be empty.');
    }

    if (quantity <= 0) {
      throw ValidationException(
        'Purchase quantity must be greater than zero.',
      );
    }

    if (price < 0) {
      throw ValidationException(
        'Purchase price cannot be negative.',
      );
    }

    final part = await partService.getPartById(partId);

    if (part == null) {
      throw NotFoundException('Part', partId);
    }

    final purchase = Purchase(
      id: IdGenerator.generate(),
      partId: partId,
      quantity: quantity,
      purchasePrice: price,
      purchaseDate: DateTime.now().toIso8601String(),
    );

    return database.transaction(() async {
      final createdPurchase =
          await purchaseRepository.create(purchase);

      await partService.adjustStock(
        partId,
        quantity,
      );

      return createdPurchase;
    });
  }

  Future<List<Purchase>> getPurchasesByPartId(
    String partId,
  ) {
    return purchaseRepository.getByPartId(partId);
  }

  Future<List<Purchase>> getAllPurchases() {
    return purchaseRepository.getAll();
  }
}