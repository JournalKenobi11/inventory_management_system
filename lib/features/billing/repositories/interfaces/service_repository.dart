import '../../models/service.dart';

abstract class ServiceRepository {
  Future<Service> create(Service service);

  Future<Service?> getById(String id);

  Future<List<Service>> getAll();

  Future<List<Service>> getByCustomerId(String customerId);

  Future<void> linkInvoice(
    String serviceId,
    String invoiceId,
  );
}