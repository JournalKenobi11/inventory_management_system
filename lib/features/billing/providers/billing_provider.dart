import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../customers/providers/customer_provider.dart';
import '../../parts/providers/part_provider.dart';
import '../models/invoice.dart';
import '../models/invoice_details.dart';
import '../models/service_part.dart';
import '../repositories/interfaces/invoice_repository.dart';
import '../repositories/interfaces/service_part_repository.dart';
import '../repositories/interfaces/service_repository.dart';
import '../repositories/sqlite/sqlite_invoice_repository.dart';
import '../repositories/sqlite/sqlite_service_part_repository.dart';
import '../repositories/sqlite/sqlite_service_repository.dart';
import '../services/billing_service.dart';

final serviceRepositoryProvider =
    Provider<ServiceRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return SqliteServiceRepository(database);
});

final servicePartRepositoryProvider =
    Provider<ServicePartRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return SqliteServicePartRepository(database);
});

final invoiceRepositoryProvider =
    Provider<InvoiceRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return SqliteInvoiceRepository(database);
});

final billingServiceProvider =
    Provider<BillingService>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return BillingService(
    ref.watch(serviceRepositoryProvider),
    ref.watch(servicePartRepositoryProvider),
    ref.watch(invoiceRepositoryProvider),
    ref.watch(customerServiceProvider),
    ref.watch(partServiceProvider),
    database,
  );
});

final billingControllerProvider =
    AsyncNotifierProvider<BillingController, Invoice?>(
  BillingController.new,
);

class BillingController
    extends AsyncNotifier<Invoice?> {
  @override
  Future<Invoice?> build() async {
    return null;
  }

  Future<Invoice> billService({
    required String customerId,
    required String problemDesc,
    required double labourCharge,
    required List<ServicePartInput> partsUsed,
  }) async {
    state = const AsyncLoading<Invoice?>();

    try {
      final invoice = await ref
          .read(billingServiceProvider)
          .billService(
            customerId: customerId,
            problemDesc: problemDesc,
            labourCharge: labourCharge,
            partsUsed: partsUsed,
          );

      state = AsyncData<Invoice?>(invoice);

      return invoice;
    } catch (error, stackTrace) {
      state = AsyncError<Invoice?>(
        error,
        stackTrace,
      );

      rethrow;
    }
  }
}

final invoicesListProvider =
    FutureProvider.autoDispose<List<Invoice>>((ref) async {
  final billingService = ref.watch(billingServiceProvider);
  return billingService.getAllInvoices();
});

final invoiceDetailsProvider =
    FutureProvider.autoDispose.family<InvoiceDetails, String>((ref, invoiceId) async {
  final billingService = ref.watch(billingServiceProvider);
  return billingService.getInvoiceDetails(invoiceId);
});
