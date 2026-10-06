import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../models/employee.dart';
import '../models/salary_payment.dart';
import '../repositories/interfaces/employee_repository.dart';
import '../repositories/interfaces/salary_payment_repository.dart';
import '../repositories/sqlite/sqlite_employee_repository.dart';
import '../repositories/sqlite/sqlite_salary_payment_repository.dart';
import '../services/salary_service.dart';

final employeeRepositoryProvider =
    Provider<EmployeeRepository>((ref) {
  return SqliteEmployeeRepository(
    ref.read(appDatabaseProvider),
  );
});

final salaryPaymentRepositoryProvider =
    Provider<SalaryPaymentRepository>((ref) {
  return SqliteSalaryPaymentRepository(
    ref.read(appDatabaseProvider),
  );
});

final salaryServiceProvider = Provider<SalaryService>((ref) {
  return SalaryService(
    ref.read(employeeRepositoryProvider),
    ref.read(salaryPaymentRepositoryProvider),
  );
});

final employeesProvider =
    AsyncNotifierProvider<EmployeesNotifier, List<Employee>>(
  EmployeesNotifier.new,
);

class EmployeesNotifier
    extends AsyncNotifier<List<Employee>> {
  SalaryService get service => ref.read(salaryServiceProvider);

  @override
  Future<List<Employee>> build() {
    return service.getEmployees();
  }

  Future<void> loadEmployees() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => service.getEmployees(),
    );
  }

  Future<void> addEmployee({
    required String name,
    required double monthlySalary,
  }) async {
    state = await AsyncValue.guard(() async {
      await service.createEmployee(
        name: name,
        monthlySalary: monthlySalary,
      );

      return service.getEmployees();
    });
  }

  Future<void> updateEmployee(Employee employee) async {
    state = await AsyncValue.guard(() async {
      await service.updateEmployee(employee);

      return service.getEmployees();
    });
  }

  Future<void> deleteEmployee(String id) async {
    state = await AsyncValue.guard(() async {
      await service.deleteEmployee(id);

      return service.getEmployees();
    });
  }
}

final salaryPaymentsProvider =
    AsyncNotifierProvider<
        SalaryPaymentsNotifier,
        List<SalaryPayment>>(
  SalaryPaymentsNotifier.new,
);

class SalaryPaymentsNotifier
    extends AsyncNotifier<List<SalaryPayment>> {
  SalaryService get service => ref.read(salaryServiceProvider);

  @override
  Future<List<SalaryPayment>> build() {
    return service.getSalaryPayments();
  }

  Future<void> loadPayments() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => service.getSalaryPayments(),
    );
  }

  Future<void> recordPayment({
    required String employeeId,
    required double amount,
    String status = 'paid',
  }) async {
    state = await AsyncValue.guard(() async {
      await service.recordPayment(
        employeeId: employeeId,
        amount: amount,
        status: status,
      );

      return service.getSalaryPayments();
    });
  }

  Future<void> markStatus({
    required String paymentId,
    required String status,
  }) async {
    state = await AsyncValue.guard(() async {
      await service.markPaymentStatus(
        paymentId: paymentId,
        status: status,
      );

      return service.getSalaryPayments();
    });
  }

  Future<void> loadForEmployee(String employeeId) async {
    state = await AsyncValue.guard(
      () => service.getPaymentsForEmployee(employeeId),
    );
  }

  Future<void> loadByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    state = await AsyncValue.guard(
      () => service.getPaymentsByDateRange(
        start: start,
        end: end,
      ),
    );
  }
}