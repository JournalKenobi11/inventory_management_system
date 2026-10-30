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
    expect(sparkPlugItem.partName, equals('SPARK PLUG'));
    expect(sparkPlugItem.partNumber, equals('SP-101'));
    expect(sparkPlugItem.quantity, equals(4));
    expect(sparkPlugItem.priceEach, equals(350.0));
    expect(sparkPlugItem.lineTotal, equals(1400.0));

    final airFilterItem = details.items.firstWhere((i) => i.partId == part2.id);
    expect(airFilterItem.partName, equals('AIR FILTER'));
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

  test('billService persists serviceReport and multiple custom LabourEntries', () async {
    final customer = await customerService.createCustomer(
      name: 'Amit Verma',
      mobile: '9876543222',
      vehicleName: 'Honda Activa',
    );

    final part = await partService.createPart(
      partName: 'Engine Oil 10W30',
      partNumber: 'OIL-103',
      category: 'Oil',
      purchasePrice: 250.0,
      sellingPrice: 380.0,
      currentStock: 10,
    );

    final labourEntries = [
      const LabourEntry(description: 'Engine Oil Drain & Fill', charge: 100.0),
      const LabourEntry(description: 'Brake Cable Greasing & Adjustment', charge: 150.0),
      const LabourEntry(description: 'Full Washing & Polishing', charge: 200.0),
    ];

    final invoice = await billingService.billService(
      customerId: customer.id,
      problemDesc: 'Periodic general servicing',
      serviceReport: 'Full engine check done, brakes tightened, clutch wire lubricated',
      labourEntries: labourEntries,
      partsUsed: [
        ServicePartInput(partId: part.id, quantity: 1),
      ],
    );

    // Total: 380 (part) + (100 + 150 + 200 = 450 labour) = 830
    expect(invoice.totalAmount, equals(830.0));

    final details = await billingService.getInvoiceDetails(invoice.id);
    expect(details.labourCharge, equals(450.0));
    expect(details.service.serviceReport,
        equals('Full engine check done, brakes tightened, clutch wire lubricated'));
    expect(details.service.labourEntries.length, equals(3));
    expect(details.service.labourEntries[0].description,
        equals('Engine Oil Drain & Fill'));
    expect(details.service.labourEntries[0].charge, equals(100.0));
    expect(details.service.labourEntries[1].description,
        equals('Brake Cable Greasing & Adjustment'));
    expect(details.service.labourEntries[1].charge, equals(150.0));
    expect(details.service.labourEntries[2].description,
        equals('Full Washing & Polishing'));
    expect(details.service.labourEntries[2].charge, equals(200.0));
  });

  test('CustomerServiceReminder detects 6-month due status and overdue days', () async {
    final customer1 = await customerService.createCustomer(
      name: 'Rohan Gupta',
      mobile: '9876543201',
      vehicleName: 'Hero Splendor',
    );
    final customer2 = await customerService.createCustomer(
      name: 'Deepak Joshi',
      mobile: '9876543202',
      vehicleName: 'Bajaj Pulsar',
    );

    // Bill customer 1 today (not due for 6 months)
    await billingService.billService(
      customerId: customer1.id,
      problemDesc: 'Oil change',
      labourCharge: 200.0,
      partsUsed: [],
    );

    // Reference date 7 months later:
    // Customer 1 should now be OVERDUE
    final sevenMonthsLater =
        DateTime.now().add(const Duration(days: 215)); // ~7 months
    final reminders = await billingService.getCustomerServiceReminders(
      referenceDate: sevenMonthsLater,
    );

    expect(reminders.isNotEmpty, isTrue);
    final reminder1 =
        reminders.firstWhere((r) => r.customer.id == customer1.id);
    expect(reminder1.isDue, isTrue);
    expect(reminder1.daysOverdue, greaterThan(0));

    // For reference date tomorrow: customer 1 should NOT be due yet
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final reminderTomorrow = await billingService.getCustomerReminder(
      customer1.id,
      referenceDate: tomorrow,
    );
    expect(reminderTomorrow, isNotNull);
    expect(reminderTomorrow!.isDue, isFalse);
    expect(reminderTomorrow.daysRemaining, greaterThan(150));

    // Customer 2 has never had a service -> should be null
    final reminderCustomer2 =
        await billingService.getCustomerReminder(customer2.id);
    expect(reminderCustomer2, isNull);
  });

  test('calculateSixMonthsLater correctly adds 6 calendar months and clamps day', () {
    // Regular date
    final d1 = DateTime(2026, 4, 15);
    final r1 = CustomerServiceReminder.calculateSixMonthsLater(d1);
    expect(r1.year, equals(2026));
    expect(r1.month, equals(10));
    expect(r1.day, equals(15));

    // Month end clamp: March 31 + 6 months -> September 30 (September has 30 days)
    final d2 = DateTime(2026, 3, 31);
    final r2 = CustomerServiceReminder.calculateSixMonthsLater(d2);
    expect(r2.year, equals(2026));
    expect(r2.month, equals(9));
    expect(r2.day, equals(30));

    // Year wrapping: October 10 + 6 months -> April 10 next year
    final d3 = DateTime(2026, 10, 10);
    final r3 = CustomerServiceReminder.calculateSixMonthsLater(d3);
    expect(r3.year, equals(2027));
    expect(r3.month, equals(4));
    expect(r3.day, equals(10));
  });
}

