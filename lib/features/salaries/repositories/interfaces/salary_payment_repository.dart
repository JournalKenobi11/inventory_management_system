import '../../models/salary_payment.dart';

abstract class SalaryPaymentRepository {
  Future<SalaryPayment> create(SalaryPayment payment);

  Future<SalaryPayment?> getById(String id);

  Future<List<SalaryPayment>> getAll();

  Future<List<SalaryPayment>> getByEmployeeId(String employeeId);

  Future<List<SalaryPayment>> getByDateRange({
    required DateTime start,
    required DateTime end,
  });

  Future<void> updateStatus({
    required String paymentId,
    required String status,
  });
}