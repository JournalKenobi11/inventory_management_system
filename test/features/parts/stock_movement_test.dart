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
import 'package:inventory_management_system/features/parts/repositories/sqlite/sqlite_stock_movement_repository.dart';
import 'package:inventory_management_system/features/purchases/purchases.dart';
import 'package:inventory_management_system/features/purchases/repositories/sqlite/sqlite_purchase_repository.dart';

void main() {
  late db.AppDatabase database;
  late PartService partService;
  late SqliteStockMovementRepository stockMovementRepository;
  late PurchaseService purchaseService;
  late BillingService billingService;
  late CustomerService customerService;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    final partRepo = SqlitePartRepository(database);
    stockMovementRepository = SqliteStockMovementRepository(database);
    partService = PartService(partRepo, stockMovementRepository);

    final purchaseRepo = SqlitePurchaseRepository(database);
    purchaseService = PurchaseService(
      purchaseRepo,
      partService,
      database,
    );

    final customerRepo = SqliteCustomerRepository(database);
    customerService = CustomerService(customerRepo);

    final serviceRepo = SqliteServiceRepository(database);
    final servicePartRepo = SqliteServicePartRepository(database);
    final invoiceRepo = SqliteInvoiceRepository(database);

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

  group('StockMovement Ledger and Auditability', () {
    test('records initial stock movement when part is created with stock',
        () async {
      final part = await partService.createPart(
        partNumber: 'OIL-001',
        partName: 'Engine Oil 1L',
        purchasePrice: 250.0,
        sellingPrice: 400.0,
        currentStock: 15,
      );

      final movements = await partService.getStockMovements(part.id);
      expect(movements.length, equals(1));
      expect(movements.first.quantityChange, equals(15));
      expect(movements.first.balanceAfter, equals(15));
      expect(movements.first.movementType, equals('initial'));
    });

    test('records stock movement on manual stock adjustment', () async {
      final part = await partService.createPart(
        partNumber: 'PLG-001',
        partName: 'Spark Plug',
        purchasePrice: 100.0,
        sellingPrice: 150.0,
        currentStock: 10,
      );

      await partService.adjustStock(
        part.id,
        5,
        movementType: 'adjustment',
        notes: 'Physical count found 5 extra',
      );

      final movements = await partService.getStockMovements(part.id);
      expect(movements.length, equals(2));

      final latest = movements.first; // ordered desc
      expect(latest.quantityChange, equals(5));
      expect(latest.balanceAfter, equals(15));
      expect(latest.movementType, equals('adjustment'));
      expect(latest.notes, equals('Physical count found 5 extra'));
    });

    test('records purchase stock movement via PurchaseService', () async {
      final part = await partService.createPart(
        partNumber: 'FLT-001',
        partName: 'Air Filter',
        purchasePrice: 180.0,
        sellingPrice: 280.0,
        currentStock: 5,
      );

      final purchase = await purchaseService.recordPurchase(
        partId: part.id,
        quantity: 10,
        price: 175.0,
      );

      final movements = await partService.getStockMovements(part.id);
      expect(movements.length, equals(2));

      final purchaseMovement = movements.first;
      expect(purchaseMovement.quantityChange, equals(10));
      expect(purchaseMovement.balanceAfter, equals(15));
      expect(purchaseMovement.movementType, equals('purchase'));
      expect(purchaseMovement.referenceId, equals(purchase.id));
      expect(purchaseMovement.notes, contains('175.00'));
    });

    test(
        'records bill stock deduction and restores stock properly on bill edit',
        () async {
      final customer = await customerService.createCustomer(
        name: 'Rahul Sharma',
        mobile: '9876543210',
      );

      final part = await partService.createPart(
        partNumber: 'PAD-001',
        partName: 'Front Brake Pads',
        purchasePrice: 300.0,
        sellingPrice: 500.0,
        currentStock: 20,
      );

      // 1. Bill service
      final invoice = await billingService.billService(
        customerId: customer.id,
        problemDesc: 'Brake replacement',
        partsUsed: [
          ServicePartInput(partId: part.id, quantity: 4),
        ],
      );

      var movements = await partService.getStockMovements(part.id);
      expect(movements.length, equals(2)); // initial + bill

      final billMovement = movements.first;
      expect(billMovement.quantityChange, equals(-4));
      expect(billMovement.balanceAfter, equals(16));
      expect(billMovement.movementType, equals('bill'));
      expect(billMovement.referenceId, equals(invoice.id));

      // 2. Edit bill to use 6 pads instead of 4
      await billingService.editBill(
        invoiceId: invoice.id,
        customerId: customer.id,
        problemDesc: 'Brake replacement & drum tuning',
        partsUsed: [
          ServicePartInput(partId: part.id, quantity: 6),
        ],
      );

      movements = await partService.getStockMovements(part.id);
      // Movements should now be:
      // 1) bill deduction: -6 (balance 14)
      // 2) bill_edit_restore: +4 (balance 20)
      // 3) bill deduction: -4 (balance 16)
      // 4) initial: +20 (balance 20)
      expect(movements.length, equals(4));

      final newestDeduction = movements[0];
      final restoration = movements[1];

      expect(restoration.movementType, equals('bill_edit_restore'));
      expect(restoration.quantityChange, equals(4));
      expect(restoration.balanceAfter, equals(20));

      expect(newestDeduction.movementType, equals('bill'));
      expect(newestDeduction.quantityChange, equals(-6));
      expect(newestDeduction.balanceAfter, equals(14));

      final updatedPart = await partService.getPartById(part.id);
      expect(updatedPart!.currentStock, equals(14));
    });
  });
}
