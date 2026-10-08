import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/employee.dart';
import '../models/salary_payment.dart';
import '../repositories/interfaces/attendance_repository.dart';
import '../repositories/interfaces/employee_repository.dart';
import '../repositories/interfaces/salary_payment_repository.dart';

class SalaryService {
  final EmployeeRepository employeeRepository;
  final SalaryPaymentRepository salaryPaymentRepository;
  final AttendanceRepository? attendanceRepository;

  SalaryService(
    this.employeeRepository,
    this.salaryPaymentRepository, [
    this.attendanceRepository,
  ]);

  Future<Employee> createEmployee({
    required String name,
    required double monthlySalary,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ValidationException(
        'Employee name cannot be empty.',
      );
    }

    if (monthlySalary <= 0) {
      throw ValidationException(
        'Monthly salary must be greater than zero.',
      );
    }

    final employee = Employee(
      id: IdGenerator.generate(),
      name: cleanName,
      monthlySalary: monthlySalary,
    );

    return employeeRepository.create(employee);
  }

  Future<Employee?> getEmployee(String id) {
    return employeeRepository.getById(id);
  }

  Future<List<Employee>> getEmployees() {
    return employeeRepository.getAll();
  }

  Future<void> updateEmployee(Employee employee) async {
    final cleanName = employee.name.trim();

    if (cleanName.isEmpty) {
      throw ValidationException(
        'Employee name cannot be empty.',
      );
    }

    if (employee.monthlySalary <= 0) {
      throw ValidationException(
        'Monthly salary must be greater than zero.',
      );
    }

    final existing = await employeeRepository.getById(
      employee.id,
    );

    if (existing == null) {
      throw NotFoundException(
        'Employee',
        employee.id,
      );
    }

    await employeeRepository.update(
      employee.copyWith(
        name: cleanName,
      ),
    );
  }

  Future<void> deleteEmployee(String id) async {
    final employee = await employeeRepository.getById(id);

    if (employee == null) {
      throw NotFoundException('Employee', id);
    }

    final payments =
        await salaryPaymentRepository.getByEmployeeId(id);

    if (payments.isNotEmpty) {
      throw ValidationException(
        'Employee cannot be deleted because salary payments exist.',
      );
    }

    if (attendanceRepository != null) {
      final attendances =
          await attendanceRepository!.getByEmployeeId(id);

      if (attendances.isNotEmpty) {
        throw ValidationException(
          'Employee cannot be deleted because attendance records exist.',
        );
      }
    }

    await employeeRepository.delete(id);
  }

  Future<SalaryPayment> recordPayment({
    required String employeeId,
    required double amount,
    String status = 'paid',
  }) async {
    if (employeeId.trim().isEmpty) {
      throw ValidationException(
        'Employee ID cannot be empty.',
      );
    }

    if (amount <= 0) {
      throw ValidationException(
        'Salary payment amount must be greater than zero.',
      );
    }

    _validateStatus(status);

    final employee =
        await employeeRepository.getById(employeeId);

    if (employee == null) {
      throw NotFoundException(
        'Employee',
        employeeId,
      );
    }

    final payment = SalaryPayment(
      id: IdGenerator.generate(),
      employeeId: employeeId,
      amount: amount,
      paymentDate: AppDateUtils.nowIso(),
      status: status,
    );

    return salaryPaymentRepository.create(payment);
  }

  Future<List<SalaryPayment>> getSalaryPayments() {
    return salaryPaymentRepository.getAll();
  }

  Future<List<SalaryPayment>> getPaymentsForEmployee(
    String employeeId,
  ) async {
    if (employeeId.trim().isEmpty) {
      throw ValidationException(
        'Employee ID cannot be empty.',
      );
    }

    final employee =
        await employeeRepository.getById(employeeId);

    if (employee == null) {
      throw NotFoundException(
        'Employee',
        employeeId,
      );
    }

    return salaryPaymentRepository.getByEmployeeId(
      employeeId,
    );
  }

  Future<List<SalaryPayment>> getPaymentsByDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    if (start.isAfter(end)) {
      throw ValidationException(
        'Start date cannot be after end date.',
      );
    }

    return salaryPaymentRepository.getByDateRange(
      start: start,
      end: end,
    );
  }

  Future<void> markPaymentStatus({
    required String paymentId,
    required String status,
  }) async {
    _validateStatus(status);

    final payment =
        await salaryPaymentRepository.getById(paymentId);

    if (payment == null) {
      throw NotFoundException(
        'Salary payment',
        paymentId,
      );
    }

    await salaryPaymentRepository.updateStatus(
      paymentId: paymentId,
      status: status,
    );
  }

  Future<double> getTotalOwedThisMonth(
    String employeeId,
  ) async {
    if (employeeId.trim().isEmpty) {
      throw ValidationException(
        'Employee ID cannot be empty.',
      );
    }

    final employee =
        await employeeRepository.getById(employeeId);

    if (employee == null) {
      throw NotFoundException(
        'Employee',
        employeeId,
      );
    }

    final now = DateTime.now();

    final monthStart = DateTime(
      now.year,
      now.month,
      1,
    );

    final nextMonthStart = DateTime(
      now.year,
      now.month + 1,
      1,
    );

    final payments =
        await salaryPaymentRepository.getByDateRange(
      start: monthStart,
      end: nextMonthStart.subtract(
        const Duration(microseconds: 1),
      ),
    );

    var paidThisMonth = 0.0;

    for (final payment in payments) {
      if (payment.employeeId == employeeId &&
          payment.status == 'paid') {
        paidThisMonth += payment.amount;
      }
    }

    final owed = employee.monthlySalary - paidThisMonth;

    return owed < 0 ? 0 : owed;
  }

  void _validateStatus(String status) {
    if (status != 'paid' && status != 'pending') {
      throw ValidationException(
        'Salary payment status must be either paid or pending.',
      );
    }
  }
}