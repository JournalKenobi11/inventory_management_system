import '../../models/part.dart';

abstract class PartRepository {
  Future<Part> create(Part part);

  Future<Part?> getById(String id);

  Future<Part?> getByPartNumber(String partNumber);

  Future<List<Part>> getAll();

  Future<List<Part>> getLowStock();

  Future<void> update(Part part);

  Future<void> adjustStock(String partId, int delta);
}