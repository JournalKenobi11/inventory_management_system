import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/database/app_database.dart' hide Customer;
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

    // For reference date tomorrow: customer 1 should NOT be due yet (90-day cycle)
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final reminderTomorrow = await billingService.getCustomerReminder(
      customer1.id,
      referenceDate: tomorrow,
    );
    expect(reminderTomorrow, isNotNull);
    expect(reminderTomorrow!.isDue, isFalse);
    expect(reminderTomorrow.daysRemaining, greaterThan(80));

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

  test('CustomerServiceReminder defaults to 90 days interval', () {
    final baseDate = DateTime(2026, 1, 1);
    final dueDate = CustomerServiceReminder.calculateReminderDueDate(baseDate);
    expect(dueDate.difference(baseDate).inDays, equals(90));

    final customer = Customer(
      id: 'cust-90',
      name: 'Amit Kumar',
      mobile: '9876543210',
      createdDate: '2026-01-01T00:00:00.000Z',
    );

    // On day 89: not due yet
    final rBefore = CustomerServiceReminder.fromLastService(
      customer: customer,
      lastServiceDate: baseDate,
      referenceDate: baseDate.add(const Duration(days: 89)),
    );
    expect(rBefore.isDue, isFalse);
    expect(rBefore.daysRemaining, equals(1));
    expect(rBefore.daysOverdue, equals(0));

    // On day 90: due
    final rDue = CustomerServiceReminder.fromLastService(
      customer: customer,
      lastServiceDate: baseDate,
      referenceDate: baseDate.add(const Duration(days: 90)),
    );
    expect(rDue.isDue, isTrue);
    expect(rDue.daysRemaining, equals(0));
    expect(rDue.daysOverdue, equals(0));

    // On day 95: overdue by 5 days
    final rOverdue = CustomerServiceReminder.fromLastService(
      customer: customer,
      lastServiceDate: baseDate,
      referenceDate: baseDate.add(const Duration(days: 95)),
    );
    expect(rOverdue.isDue, isTrue);
    expect(rOverdue.daysRemaining, equals(0));
    expect(rOverdue.daysOverdue, equals(5));
  });

  test('editBill updates customer, labour, parts, and manages stock restoration atomically', () async {
    final cust1 = await customerService.createCustomer(
      name: 'Sunil Rao',
      mobile: '9888877771',
      vehicleName: 'Honda City',
    );
    final cust2 = await customerService.createCustomer(
      name: 'Rohan Sharma',
      mobile: '9888877772',
      vehicleName: 'Maruti Swift',
    );

    final part1 = await partService.createPart(
      partName: 'Brake Disc',
      partNumber: 'BD-01',
      purchasePrice: 500.0,
      sellingPrice: 800.0,
      currentStock: 10,
      lowStockThreshold: 2,
    );
    final part2 = await partService.createPart(
      partName: 'Brake Fluid',
      partNumber: 'BF-02',
      purchasePrice: 150.0,
      sellingPrice: 300.0,
      currentStock: 10,
      lowStockThreshold: 2,
    );

    // Initial bill: 4x Brake Disc (leaves 6) + 2x Brake Fluid (leaves 8) + 200 labour
    final invoice = await billingService.billService(
      customerId: cust1.id,
      problemDesc: 'Brake inspection',
      labourCharge: 200.0,
      partsUsed: [
        ServicePartInput(partId: part1.id, quantity: 4),
        ServicePartInput(partId: part2.id, quantity: 2),
      ],
    );

    var p1 = await partService.getPartById(part1.id);
    var p2 = await partService.getPartById(part2.id);
    expect(p1!.currentStock, equals(6));
    expect(p2!.currentStock, equals(8));
    expect(invoice.totalAmount, equals(4 * 800.0 + 2 * 300.0 + 200.0)); // 3200 + 600 + 200 = 4000

    // Edit bill: change to cust2, part1 qty 2 (should restore 4, deduct 2 -> 8 in stock),
    // part2 qty 5 (should restore 2, deduct 5 -> 5 in stock), labour 350
    final updatedInvoice = await billingService.editBill(
      invoiceId: invoice.id,
      customerId: cust2.id,
      problemDesc: 'Full brake overhaul',
      labourCharge: 350.0,
      partsUsed: [
        ServicePartInput(partId: part1.id, quantity: 2),
        ServicePartInput(partId: part2.id, quantity: 5),
      ],
      serviceReport: 'Replaced discs and fluid flush',
    );

    // Expected total: 2 * 800 + 5 * 300 + 350 = 1600 + 1500 + 350 = 3450
    expect(updatedInvoice.totalAmount, equals(3450.0));

    p1 = await partService.getPartById(part1.id);
    p2 = await partService.getPartById(part2.id);
    expect(p1!.currentStock, equals(8));
    expect(p2!.currentStock, equals(5));

    final details = await billingService.getInvoiceDetails(invoice.id);
    expect(details.customer.id, equals(cust2.id));
    expect(details.service.problemDesc, equals('Full brake overhaul'));
    expect(details.service.serviceReport, equals('Replaced discs and fluid flush'));
    expect(details.labourCharge, equals(350.0));
    expect(details.totalAmount, equals(3450.0));
    expect(details.items.length, equals(2));
  });
}

