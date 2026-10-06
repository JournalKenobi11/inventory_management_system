import '../../models/employee.dart';

abstract class EmployeeRepository {
  Future<Employee> create(Employee employee);

  Future<Employee?> getById(String id);

  Future<List<Employee>> getAll();

  Future<void> update(Employee employee);

  Future<void> delete(String id);
}