import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_service_part_repository.dart';
import 'package:inventory_management_system/features/billing/repositories/sqlite/sqlite_service_repository.dart';
import 'package:inventory_management_system/features/customers/customers.dart';
import 'package:inventory_management_system/features/customers/repositories/sqlite/sqlite_customer_repository.dart';
import 'package:inventory_management_system/features/parts/parts.dart';
import 'package:inventory_management_system/features/parts/repositories/sqlite/sqlite_part_repository.dart';

void main() {
  late AppDatabase database;
  late CustomerService customerService;
  late PartService partService;
  late BillingService billingService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());

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

  test('billService creates invoice and getInvoiceDetails retrieves complete data', () async {
    // 1. Create customer
    final customer = await customerService.createCustomer(
      name: 'Priya Patel',
      mobile: '9876543210',
      vehicleName: 'Hyundai i20',
    );

    // 2. Create parts with stock
    final part1 = await partService.createPart(
      partName: 'Spark Plug',
      partNumber: 'SP-101',
      category: 'Ignition',
      purchasePrice: 200.0,
      sellingPrice: 350.0,
      currentStock: 10,
      lowStockThreshold: 2,
    );

    final part2 = await partService.createPart(
      partName: 'Air Filter',
      partNumber: 'AF-202',
      category: 'Filter',
      purchasePrice: 250.0,
      sellingPrice: 400.0,
      currentStock: 5,
      lowStockThreshold: 1,
    );

    // 3. Bill the service
    final invoice = await billingService.billService(
      customerId: customer.id,
      problemDesc: 'Scheduled General Maintenance',
      labourCharge: 450.0,
      partsUsed: [
        ServicePartInput(partId: part1.id, quantity: 4),
        ServicePartInput(partId: part2.id, quantity: 1),
      ],
    );

    // Total: (4 * 350) + (1 * 400) + 450 = 1400 + 400 + 450 = 2250
    expect(invoice.totalAmount, equals(2250.0));
    expect(invoice.invoiceNumber, isPositive);

    // 4. Retrieve complete InvoiceDetails
    final details = await billingService.getInvoiceDetails(invoice.id);

    expect(details.invoice.id, equals(invoice.id));
    expect(details.invoice.invoiceNumber, equals(invoice.invoiceNumber));
    expect(details.customer.name, equals('Priya Patel'));
    expect(details.customer.mobile, equals('9876543210'));
    expect(details.customer.vehicleName, equals('Hyundai i20'));
    expect(details.service.problemDesc, equals('Scheduled General Maintenance'));
    expect(details.labourCharge, equals(450.0));
    expect(details.partsSubtotal, equals(1800.0));
    expect(details.totalAmount, equals(2250.0));
    expect(details.grandTotal, equals(2250.0));

    expect(details.items.length, equals(2));
    final sparkPlugItem = details.items.firstWhere((i) => i.partId == part1.id);
    expect(sparkPlugItem.partName, equals('Spark Plug'));
    expect(sparkPlugItem.partNumber, equals('SP-101'));
    expect(sparkPlugItem.quantity, equals(4));
    expect(sparkPlugItem.priceEach, equals(350.0));
    expect(sparkPlugItem.lineTotal, equals(1400.0));

    final airFilterItem = details.items.firstWhere((i) => i.partId == part2.id);
    expect(airFilterItem.partName, equals('Air Filter'));
    expect(airFilterItem.partNumber, equals('AF-202'));
    expect(airFilterItem.quantity, equals(1));
    expect(airFilterItem.priceEach, equals(400.0));
    expect(airFilterItem.lineTotal, equals(400.0));

    // Stock should have decreased
    final updatedPart1 = await partService.getPartById(part1.id);
    expect(updatedPart1!.currentStock, equals(6));
    final updatedPart2 = await partService.getPartById(part2.id);
    expect(updatedPart2!.currentStock, equals(4));
  });
}
