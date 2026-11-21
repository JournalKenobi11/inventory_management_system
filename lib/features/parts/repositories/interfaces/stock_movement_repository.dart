import '../../models/stock_movement.dart';

abstract class StockMovementRepository {
  Future<StockMovement> create(StockMovement movement);
  Future<List<StockMovement>> getByPartId(String partId);
  Future<List<StockMovement>> getAll();
}
