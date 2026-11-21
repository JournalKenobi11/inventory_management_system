import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/database/app_database.dart' as db;
import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_service_part_repository.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_service_repository.dart';
import 'package:inventory_management_system/features/customers/customers.dart';
import 'package:inventory_management_system/features/customers/repositories/sqlite/sqlite_customer_repository.dart';
import 'package:inventory_management_system/features/parts/parts.dart';
import 'package:inventory_management_system/features/parts/repositories/sqlite/sqlite_part_repository.dart';

void main() {
  late db.AppDatabase database;
  late PartService partService;
  late CustomerService customerService;
  late BillingService billingService;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    final customerRepo = SqliteCustomerRepository(database);
    final partRepo = SqlitePartRepository(database);
    final serviceRepo = SqliteServiceRepository(database);
    final servicePartRepo = SqliteServicePartRepository(database);
    final invoiceRepo = SqliteInvoiceRepository(database);

    customerService = CustomerService(customerRepo);
    partService = PartService(partRepo);
    billingService = BillingService(
      serviceRepo,
      servicePartRepo,
      invoiceRepo,
      customerService,
      partService,
      database,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Completed Services & Sales in Date Range', () {
    test('getInvoicesInDateRange returns invoices and details within range',
        () async {
      final customer = await customerService.createCustomer(
        name: 'Ramesh Kale',
        mobile: '9876543210',
        vehicleName: 'Honda Activa 6G',
      );

      final part = await partService.createPart(
        partNumber: 'OIL-4T',
        partName: 'Engine Oil 4T',
        purchasePrice: 200.0,
        sellingPrice: 350.0,
        currentStock: 10,
      );

      // Bill service today
      final invoice = await billingService.billService(
        customerId: customer.id,
        problemDesc: 'Periodic general service and oil replacement',
        labourCharge: 250.0,
        partsUsed: [
          ServicePartInput(partId: part.id, quantity: 1),
        ],
      );

      final today = DateTime.now();
      final results = await billingService.getInvoicesInDateRange(
        DateTime(today.year, today.month, today.day),
        DateTime(today.year, today.month, today.day, 23, 59, 59),
      );

      expect(results.length, equals(1));
      final details = results.first;
      expect(details.invoice.id, equals(invoice.id));
      expect(details.customer.name, equals('Ramesh Kale'));
      expect(details.customer.vehicleName, equals('Honda Activa 6G'));
      expect(details.totalAmount, equals(600.0)); // 350 + 250
      expect(details.items.length, equals(1));
      expect(details.items.first.partName, equals('ENGINE OIL 4T'));

      // Test date range outside today
      final pastResults = await billingService.getInvoicesInDateRange(
        today.subtract(const Duration(days: 10)),
        today.subtract(const Duration(days: 5)),
      );
      expect(pastResults, isEmpty);
    });
  });
}
