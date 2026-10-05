import '../../models/service_part.dart';

abstract class ServicePartRepository {
  Future<ServicePart> create(ServicePart servicePart);

  Future<List<ServicePart>> getByServiceId(String serviceId);
}