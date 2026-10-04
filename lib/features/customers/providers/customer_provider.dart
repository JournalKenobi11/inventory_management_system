import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../models/customer.dart';
import '../repositories/interfaces/customer_repository.dart';
import '../repositories/sqlite/sqlite_customer_repository.dart';
import '../services/customer_service.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return SqliteCustomerRepository(
    ref.read(appDatabaseProvider),
  );
});

final customerServiceProvider = Provider<CustomerService>((ref) {
  return CustomerService(
    ref.read(customerRepositoryProvider),
  );
});

final customersProvider =
    AsyncNotifierProvider<CustomerNotifier, List<Customer>>(
  CustomerNotifier.new,
);

class CustomerNotifier extends AsyncNotifier<List<Customer>> {
  CustomerService get service =>
      ref.read(customerServiceProvider);

  @override
  Future<List<Customer>> build() async {
    return service.getCustomers();
  }

  Future<void> loadCustomers() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => service.getCustomers(),
    );
  }

  Future<void> searchCustomers(String query) async {
    state = await AsyncValue.guard(
      () => service.searchCustomers(query),
    );
  }

  Future<void> deleteCustomer(String id) async {
    await service.deleteCustomer(id);
    await loadCustomers();
  }
}