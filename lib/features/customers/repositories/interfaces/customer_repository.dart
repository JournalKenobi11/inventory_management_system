// lib/features/customers/repositories/interfaces/customer_repository.dart

import '../../models/customer.dart';

abstract class CustomerRepository {
  Future<Customer> create(Customer customer);

  Future<Customer?> getById(String id);

  Future<List<Customer>> getAll();

  Future<List<Customer>> search(String query);

  Future<void> update(Customer customer);

  Future<void> delete(String id);
}