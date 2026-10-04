import '../../models/purchase.dart';

abstract class PurchaseRepository {
  Future<Purchase> create(Purchase purchase);

  Future<List<Purchase>> getByPartId(String partId);

  Future<List<Purchase>> getAll();
}