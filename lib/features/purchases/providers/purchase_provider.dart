import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../parts/providers/part_provider.dart';
import '../models/purchase.dart';
import '../repositories/interfaces/purchase_repository.dart';
import '../repositories/sqlite/sqlite_purchase_repository.dart';
import '../services/purchase_service.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return SqlitePurchaseRepository(database);
});

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final purchaseRepository = ref.watch(purchaseRepositoryProvider);
  final partService = ref.watch(partServiceProvider);

  return PurchaseService(
    purchaseRepository,
    partService,
    database,
  );
});

final purchasesProvider =
    AsyncNotifierProvider<PurchasesNotifier, List<Purchase>>(
  PurchasesNotifier.new,
);

class PurchasesNotifier extends AsyncNotifier<List<Purchase>> {
  @override
  Future<List<Purchase>> build() async {
    final service = ref.watch(purchaseServiceProvider);
    return service.getAllPurchases();
  }

  Future<void> recordPurchase({
    required String partId,
    required int quantity,
    required double price,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final service = ref.read(purchaseServiceProvider);

      await service.recordPurchase(
        partId: partId,
        quantity: quantity,
        price: price,
      );

      ref.invalidate(partsProvider);

      return service.getAllPurchases();
    });
  }

  Future<List<Purchase>> getPurchasesByPartId(
    String partId,
  ) {
    final service = ref.read(purchaseServiceProvider);

    return service.getPurchasesByPartId(partId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final service = ref.read(purchaseServiceProvider);

      return service.getAllPurchases();
    });
  }
}