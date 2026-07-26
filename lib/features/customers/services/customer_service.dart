import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/customer.dart';
import '../repositories/interfaces/customer_repository.dart';

class CustomerService {
  final CustomerRepository repository;

  CustomerService(this.repository);

  Future<Customer> createCustomer({
    required String name,
    required String mobile,
    String? vehicleName,
  }) async {
    final cleanName = name.trim();
    final cleanMobile = mobile.trim();
    final cleanVehicle = vehicleName?.trim();

    if (cleanName.isEmpty) {
      throw ValidationException('Customer name cannot be empty');
    }

    if (cleanMobile.isEmpty) {
      throw ValidationException('Customer mobile cannot be empty');
    }

    final customer = Customer(
      id: IdGenerator.generate(),
      name: cleanName,
      mobile: cleanMobile,
      vehicleName: cleanVehicle == null || cleanVehicle.isEmpty
          ? null
          : cleanVehicle,
      createdDate: AppDateUtils.nowIso(),
    );

    return repository.create(customer);
  }

  Future<Customer?> getCustomer(String id) {
    return repository.getById(id);
  }

  Future<List<Customer>> getCustomers() {
    return repository.getAll();
  }

  Future<List<Customer>> searchCustomers(String query) {
    return repository.search(query);
  }

  Future<void> updateCustomer(Customer customer) async {
    final cleanName = customer.name.trim();
    final cleanMobile = customer.mobile.trim();

    if (cleanName.isEmpty) {
      throw ValidationException('Customer name cannot be empty');
    }

    if (cleanMobile.isEmpty) {
      throw ValidationException('Customer mobile cannot be empty');
    }

    await repository.update(
      customer.copyWith(
        name: cleanName,
        mobile: cleanMobile,
        vehicleName: customer.vehicleName?.trim(),
      ),
    );
  }

  Future<void> deleteCustomer(String id) {
    return repository.delete(id);
  }
}