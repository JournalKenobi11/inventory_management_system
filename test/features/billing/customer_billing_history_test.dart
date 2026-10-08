import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/core/errors/app_exceptions.dart';
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
  late SqliteCustomerRepository customerRepo;
  late SqlitePartRepository partRepo;
  late SqliteServiceRepository serviceRepo;
  late SqliteServicePartRepository servicePartRepo;
  late SqliteInvoiceRepository invoiceRepo;
  late CustomerService customerService;
  late PartService partService;
  late BillingService billingService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    customerRepo = SqliteCustomerRepository(database);
    partRepo = SqlitePartRepository(database);
    serviceRepo = SqliteServiceRepository(database);
    servicePartRepo = SqliteServicePartRepository(database);
    invoiceRepo = SqliteInvoiceRepository(database);

    customerService = CustomerService(
      customerRepo,
      hasBillingHistory: (customerId) async {
        final services = await serviceRepo.getByCustomerId(customerId);
        return services.isNotEmpty;
      },
    );
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

  group('Customer Service & Billing History', () {
    test('1. Customer with no history returns empty list without error', () async {
      final customer = await customerService.createCustomer(
        name: 'Rahul Sharma',
        mobile: '9876543210',
        vehicleName: 'Honda City',
      );

      final history =
          await billingService.getCustomerBillingHistory(customer.id);
      expect(history, isEmpty);
    });

    test('2. Customer with one service/invoice returns correct details', () async {
      final customer = await customerService.createCustomer(
        name: 'Rahul Sharma',
        mobile: '9876543210',
        vehicleName: 'Honda City',
      );

      final part = await partService.createPart(
        partName: 'Brake Pad',
        partNumber: 'BP-101',
        purchasePrice: 400.0,
        sellingPrice: 850.0,
        currentStock: 10,
      );

      final invoice = await billingService.billService(
        customerId: customer.id,
        problemDesc: 'Brake inspection and pad replacement',
        labourCharge: 500.0,
        partsUsed: [
          ServicePartInput(partId: part.id, quantity: 2),
        ],
      );

      final history =
          await billingService.getCustomerBillingHistory(customer.id);
      expect(history.length, 1);

      final item = history.first;
      expect(item.invoice.id, invoice.id);
      expect(item.invoice.invoiceNumber, invoice.invoiceNumber);
      expect(item.customer.name, 'Rahul Sharma');
      expect(item.service.problemDesc, 'Brake inspection and pad replacement');
      expect(item.labourCharge, 500.0);
      expect(item.items.length, 1);
      expect(item.items.first.partName, 'Brake Pad');
      expect(item.items.first.quantity, 2);
      expect(item.items.first.priceEach, 850.0);
      expect(item.items.first.lineTotal, 1700.0);
      expect(item.totalAmount, 2200.0); // 1700 + 500
    });

    test('3 & 4. Customer with multiple services returns all records sorted newest first', () async {
      final customer = await customerService.createCustomer(
        name: 'Rahul Sharma',
        mobile: '9876543210',
      );

      final part = await partService.createPart(
        partName: 'Oil Filter',
        partNumber: 'OF-01',
        purchasePrice: 150.0,
        sellingPrice: 300.0,
        currentStock: 20,
      );

      // First bill (earlier)
      final invoice1 = await billingService.billService(
        customerId: customer.id,
        problemDesc: 'First regular service',
        labourCharge: 300.0,
        partsUsed: [
          ServicePartInput(partId: part.id, quantity: 1),
        ],
      );

      // Update service 1 date to earlier date
      final service1 = await serviceRepo.getById(invoice1.serviceId);
      await (database.update(database.serviceJobs)
            ..where((tbl) => tbl.id.equals(service1!.id)))
          .write(
        ServiceJobsCompanion.insert(
          id: service1!.id,
          customerId: customer.id,
          serviceDate: '2026-09-21T10:00:00.000',
        ),
      );

      // Second bill (later)
      final invoice2 = await billingService.billService(
        customerId: customer.id,
        problemDesc: 'Second service brake check',
        labourCharge: 500.0,
        partsUsed: [
          ServicePartInput(partId: part.id, quantity: 2),
        ],
      );

      final service2 = await serviceRepo.getById(invoice2.serviceId);
      await (database.update(database.serviceJobs)
            ..where((tbl) => tbl.id.equals(service2!.id)))
          .write(
        ServiceJobsCompanion.insert(
          id: service2!.id,
          customerId: customer.id,
          serviceDate: '2026-10-08T10:00:00.000',
        ),
      );

      final history =
          await billingService.getCustomerBillingHistory(customer.id);
      expect(history.length, 2);

      // Newest first
      expect(history[0].invoice.id, invoice2.id);
      expect(history[0].service.problemDesc, 'Second service brake check');
      expect(history[1].invoice.id, invoice1.id);
      expect(history[1].service.problemDesc, 'First regular service');
    });

    test('5 & 10. Correct customer filtering: another customer history does not appear', () async {
      final customerA = await customerService.createCustomer(
        name: 'Rahul Sharma',
        mobile: '9876543210',
      );
      final customerB = await customerService.createCustomer(
        name: 'Amit Verma',
        mobile: '9123456789',
      );

      final part = await partService.createPart(
        partName: 'Spark Plug',
        partNumber: 'SP-1',
        purchasePrice: 100.0,
        sellingPrice: 200.0,
        currentStock: 10,
      );

      await billingService.billService(
        customerId: customerA.id,
        problemDesc: 'Service for Rahul',
        labourCharge: 200.0,
        partsUsed: [ServicePartInput(partId: part.id, quantity: 1)],
      );

      await billingService.billService(
        customerId: customerB.id,
        problemDesc: 'Service for Amit',
        labourCharge: 400.0,
        partsUsed: [ServicePartInput(partId: part.id, quantity: 2)],
      );

      final historyA =
          await billingService.getCustomerBillingHistory(customerA.id);
      expect(historyA.length, 1);
      expect(historyA.first.customer.id, customerA.id);
      expect(historyA.first.service.problemDesc, 'Service for Rahul');

      final historyB =
          await billingService.getCustomerBillingHistory(customerB.id);
      expect(historyB.length, 1);
      expect(historyB.first.customer.id, customerB.id);
      expect(historyB.first.service.problemDesc, 'Service for Amit');
    });

    test('6 & 7. Historical ServicePart price snapshot preserved even when current part price changes', () async {
      final customer = await customerService.createCustomer(
        name: 'Rahul Sharma',
        mobile: '9876543210',
      );

      final part = await partService.createPart(
        partName: 'Brake Pad',
        partNumber: 'BP-01',
        purchasePrice: 500.0,
        sellingPrice: 800.0, // Initial price: ₹800
        currentStock: 10,
      );

      await billingService.billService(
        customerId: customer.id,
        problemDesc: 'Brake pad replacement',
        labourCharge: 500.0,
        partsUsed: [
          ServicePartInput(partId: part.id, quantity: 2), // 2 × 800 = 1600
        ],
      );

      // Part selling price later increases to ₹1,000
      await partService.updatePart(
        part.copyWith(sellingPrice: 1000.0),
      );

      final updatedPart = await partService.getPartById(part.id);
      expect(updatedPart!.sellingPrice, 1000.0);

      // Historical billing history must CONTINUE showing ₹800, NOT ₹1,000!
      final history =
          await billingService.getCustomerBillingHistory(customer.id);
      expect(history.length, 1);

      final item = history.first;
      expect(item.items.first.priceEach, 800.0);
      expect(item.items.first.lineTotal, 1600.0);
      expect(item.partsSubtotal, 1600.0);
      expect(item.totalAmount, 2100.0); // 1600 + 500
    });

    test('8 & 9. Labour charge and total amount are calculated and displayed correctly', () async {
      final customer = await customerService.createCustomer(
        name: 'Priya',
        mobile: '9876543211',
      );

      final part1 = await partService.createPart(
        partName: 'Brake Pad',
        partNumber: 'BP-2',
        purchasePrice: 500.0,
        sellingPrice: 850.0,
        currentStock: 10,
      );

      final part2 = await partService.createPart(
        partName: 'Oil Filter',
        partNumber: 'OF-2',
        purchasePrice: 200.0,
        sellingPrice: 450.0,
        currentStock: 10,
      );

      await billingService.billService(
        customerId: customer.id,
        problemDesc: 'Full service',
        labourCharge: 500.0,
        partsUsed: [
          ServicePartInput(partId: part1.id, quantity: 2), // 1700
          ServicePartInput(partId: part2.id, quantity: 1), // 450
        ],
      );

      final history =
          await billingService.getCustomerBillingHistory(customer.id);
      expect(history.length, 1);

      final details = history.first;
      expect(details.labourCharge, 500.0);
      expect(details.partsSubtotal, 2150.0);
      expect(details.totalAmount, 2650.0);
      expect(details.displayDate, isNotEmpty);
    });
  });

  group('Customer Deletion Protection', () {
    test('Customer with billing history cannot be deleted', () async {
      final customer = await customerService.createCustomer(
        name: 'Rahul Sharma',
        mobile: '9876543210',
      );

      final part = await partService.createPart(
        partName: 'Spark Plug',
        partNumber: 'SP-10',
        purchasePrice: 100.0,
        sellingPrice: 200.0,
        currentStock: 5,
      );

      await billingService.billService(
        customerId: customer.id,
        problemDesc: 'Quick check',
        labourCharge: 100.0,
        partsUsed: [ServicePartInput(partId: part.id, quantity: 1)],
      );

      expect(
        () => customerService.deleteCustomer(customer.id),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('billing history exists'),
          ),
        ),
      );

      // Customer should still exist in database
      final remaining = await customerService.getCustomer(customer.id);
      expect(remaining, isNotNull);
    });

    test('Customer without billing history can be deleted', () async {
      final customer = await customerService.createCustomer(
        name: 'New Customer',
        mobile: '9876500000',
      );

      await customerService.deleteCustomer(customer.id);
      final remaining = await customerService.getCustomer(customer.id);
      expect(remaining, isNull);
    });
  });
}
