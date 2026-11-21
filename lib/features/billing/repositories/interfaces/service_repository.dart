import '../../models/service.dart';

abstract class ServiceRepository {
  Future<Service> create(Service service);

  Future<Service> update(Service service);

  Future<Service?> getById(String id);

  Future<List<Service>> getAll();

  Future<List<Service>> getByCustomerId(String customerId);

  Future<List<Service>> getPendingServices();

  Future<List<Service>> getPendingServicesByCustomerId(String customerId);

  Future<void> updateStatus(
    String serviceId,
    String status,
  );

  Future<void> linkInvoice(
    String serviceId,
    String invoiceId,
  );
}