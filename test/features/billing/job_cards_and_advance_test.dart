import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/database/app_database.dart'
    hide Customer;
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

  group('Job Cards and Advance Tracking', () {
    test('createJobCard records advance without billing or stock deduction',
        () async {
      // 1. Create customer and a battery part
      final customer = await customerService.createCustomer(
        name: 'Rahul Sharma',
        mobile: '9876543210',
        vehicleName: 'Hyundai Creta',
      );

      final battery = await partService.createPart(
        partName: 'Amaron 65Ah Battery',
        partNumber: 'AMR-65AH',
        category: 'Battery',
        purchasePrice: 15000.0,
        sellingPrice: 22000.0,
        currentStock: 3,
        lowStockThreshold: 1,
      );

      // 2. Customer pays 20,000 advance to order/reserve the battery
      final jobCard = await billingService.createJobCard(
        customerId: customer.id,
        problemDesc: 'Replace Car Battery (Special Order)',
        advanceAmount: 20000.0,
        advancePaymentMode: 'UPI',
        advanceNotes: 'Customer paid 20k advance via GPay for 65Ah Battery order',
      );

      expect(jobCard.id, isNotEmpty);
      expect(jobCard.customerId, equals(customer.id));
      expect(jobCard.status, equals('pending'));
      expect(jobCard.isPending, isTrue);
      expect(jobCard.advanceAmount, equals(20000.0));
      expect(jobCard.advancePaymentMode, equals('UPI'));
      expect(jobCard.invoiceId, isNull);

      // 3. Stock must NOT be deducted at this stage
      final batteryAfterJobCard = await partService.getPartById(battery.id);
      expect(batteryAfterJobCard!.currentStock, equals(3));

      // 4. Pending list queries
      final allPending = await billingService.getPendingJobCards();
      expect(allPending.length, equals(1));
      expect(allPending.first.id, equals(jobCard.id));

      final customerPending =
          await billingService.getPendingJobCardsByCustomer(customer.id);
      expect(customerPending.length, equals(1));
      expect(customerPending.first.advanceAmount, equals(20000.0));
    });

    test('cancelJobCard changes status to cancelled', () async {
      final customer = await customerService.createCustomer(
        name: 'Amit Verma',
        mobile: '9812345678',
      );

      final jobCard = await billingService.createJobCard(
        customerId: customer.id,
        problemDesc: 'AC Compressor Check',
        advanceAmount: 5000.0,
        advancePaymentMode: 'Cash',
      );

      expect((await billingService.getPendingJobCards()).length, equals(1));

      await billingService.cancelJobCard(jobCard.id);

      final pendingAfterCancel = await billingService.getPendingJobCards();
      expect(pendingAfterCancel, isEmpty);
    });

    test(
        'billService with existingServiceId completes job card, links invoice, and applies advance',
        () async {
      // 1. Create customer & stock
      final customer = await customerService.createCustomer(
        name: 'Sunil Kumar',
        mobile: '9123456780',
        vehicleName: 'Honda City',
      );

      final battery = await partService.createPart(
        partName: 'Amaron 65Ah Battery',
        partNumber: 'AMR-65AH',
        category: 'Battery',
        purchasePrice: 16000.0,
        sellingPrice: 22000.0,
        currentStock: 5,
        lowStockThreshold: 1,
      );

      // 2. Create Job Card with 20,000 advance
      final jobCard = await billingService.createJobCard(
        customerId: customer.id,
        problemDesc: 'Battery replacement with 20k advance',
        advanceAmount: 20000.0,
        advancePaymentMode: 'UPI',
        advanceNotes: 'Advance received via UPI',
      );

      // 3. Service completed: bill with the battery (22,000) + 500 labour = 22,500 total
      final invoice = await billingService.billService(
        customerId: customer.id,
        existingServiceId: jobCard.id,
        problemDesc: 'Battery replacement completed',
        labourCharge: 500.0,
        advanceAmount: 20000.0,
        partsUsed: [
          ServicePartInput(partId: battery.id, quantity: 1),
        ],
      );

      // 4. Validate Invoice figures
      expect(invoice.totalAmount, equals(22500.0));
      expect(invoice.advanceAmount, equals(20000.0));
      expect(invoice.balanceDue, equals(2500.0)); // 22,500 - 20,000 = 2,500

      // 5. Stock should now be deducted (5 - 1 = 4)
      final batteryAfterBilling = await partService.getPartById(battery.id);
      expect(batteryAfterBilling!.currentStock, equals(4));

      // 6. Job card is no longer pending
      final pendingJobs = await billingService.getPendingJobCards();
      expect(pendingJobs, isEmpty);

      // 7. Invoice details verify linkage
      final details = await billingService.getInvoiceDetails(invoice.id);
      expect(details.service.id, equals(jobCard.id));
      expect(details.service.status, equals('completed'));
      expect(details.service.invoiceId, equals(invoice.id));
      expect(details.invoice.advanceAmount, equals(20000.0));
      expect(details.invoice.balanceDue, equals(2500.0));
    });

    test('balanceDue clamps to 0 when advance exceeds total bill', () async {
      final customer = await customerService.createCustomer(
        name: 'Vikas Gupta',
        mobile: '9988776655',
      );

      final jobCard = await billingService.createJobCard(
        customerId: customer.id,
        problemDesc: 'Minor wiring inspection',
        advanceAmount: 1000.0,
      );

      // Total bill: only 400 labour
      final invoice = await billingService.billService(
        customerId: customer.id,
        existingServiceId: jobCard.id,
        problemDesc: 'Minor wiring inspection completed',
        labourCharge: 400.0,
        advanceAmount: 1000.0,
        partsUsed: const [],
      );

      expect(invoice.totalAmount, equals(400.0));
      expect(invoice.advanceAmount, equals(1000.0));
      expect(invoice.balanceDue, equals(0.0));
    });

    test('updateJobCard modifies advance amount, payment mode, and problem desc',
        () async {
      final customer = await customerService.createCustomer(
        name: 'Deepak Rao',
        mobile: '9765432109',
      );

      final jobCard = await billingService.createJobCard(
        customerId: customer.id,
        problemDesc: 'Brake pads replacement',
        advanceAmount: 2000.0,
        advancePaymentMode: 'Cash',
      );

      // Customer comes back and pays additional 3,000 via UPI (total 5,000)
      final updated = await billingService.updateJobCard(
        serviceId: jobCard.id,
        problemDesc: 'Brake pads and rotor replacement',
        advanceAmount: 5000.0,
        advancePaymentMode: 'UPI',
        advanceNotes: 'Additional 3k paid via UPI',
      );

      expect(updated.advanceAmount, equals(5000.0));
      expect(updated.advancePaymentMode, equals('UPI'));
      expect(updated.problemDesc, equals('Brake pads and rotor replacement'));
      expect(updated.advanceNotes, equals('Additional 3k paid via UPI'));

      // Check repository fetch
      final pending =
          await billingService.getPendingJobCardsByCustomer(customer.id);
      expect(pending.length, equals(1));
      expect(pending.first.advanceAmount, equals(5000.0));
      expect(pending.first.advancePaymentMode, equals('UPI'));
    });
  });
}
