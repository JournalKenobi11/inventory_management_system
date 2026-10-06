import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../models/salary_payment.dart';
import '../providers/salary_provider.dart';

class PendingPaymentsScreen extends ConsumerStatefulWidget {
  const PendingPaymentsScreen({super.key});

  @override
  ConsumerState<PendingPaymentsScreen> createState() =>
      _PendingPaymentsScreenState();
}

class _PendingPaymentsScreenState
    extends ConsumerState<PendingPaymentsScreen> {
  @override
  Widget build(BuildContext context) {
    final employeesState = ref.watch(employeesProvider);
    final paymentsState = ref.watch(salaryPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Salaries'),
      ),
      body: employeesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text(error.toString()),
        ),
        data: (employees) {
          return paymentsState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Center(
              child: Text(error.toString()),
            ),
            data: (payments) {
              final pending = payments
                  .where(
                    (payment) =>
                        payment.status == 'pending',
                  )
                  .toList();

              if (pending.isEmpty) {
                return const Center(
                  child: Text(
                    'No pending salary payments.',
                  ),
                );
              }

              final employeeMap = <String, Employee>{
                for (final employee in employees)
                  employee.id: employee,
              };

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: pending.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final payment = pending[index];
                  final employee =
                      employeeMap[payment.employeeId];

                  return _PendingPaymentCard(
                    payment: payment,
                    employeeName:
                        employee?.name ?? 'Unknown employee',
                    onMarkPaid: () async {
                      try {
                        await ref
                            .read(
                              salaryPaymentsProvider
                                  .notifier,
                            )
                            .markStatus(
                              paymentId: payment.id,
                              status: 'paid',
                            );
                      } catch (error) {
                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content:
                                Text(error.toString()),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PendingPaymentCard extends StatelessWidget {
  final SalaryPayment payment;
  final String employeeName;
  final VoidCallback onMarkPaid;

  const _PendingPaymentCard({
    required this.payment,
    required this.employeeName,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final paymentDate =
        DateTime.tryParse(payment.paymentDate);

    return Card(
      child: ListTile(
        title: Text(employeeName),
        subtitle: Text(
          paymentDate == null
              ? payment.paymentDate
              : '${paymentDate.day.toString().padLeft(2, '0')}/'
                  '${paymentDate.month.toString().padLeft(2, '0')}/'
                  '${paymentDate.year}',
        ),
        leading: const Icon(
          Icons.pending_actions,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onMarkPaid,
              child: const Text('Mark paid'),
            ),
          ],
        ),
      ),
    );
  }
}