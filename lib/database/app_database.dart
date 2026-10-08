import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

// ---------- Tables ----------

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get mobile => text()();
  TextColumn get vehicleName => text().nullable()();
  TextColumn get createdDate => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Parts extends Table {
  TextColumn get id => text()();
  TextColumn get partNumber => text().unique()();
  TextColumn get partName => text()();
  TextColumn get category => text().nullable()();
  RealColumn get purchasePrice => real()();
  RealColumn get sellingPrice => real()();
  IntColumn get currentStock => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(5))();

  @override
  Set<Column> get primaryKey => {id};
}

class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get partId => text().references(Parts, #id)();
  IntColumn get quantity => integer()();
  RealColumn get purchasePrice => real()();
  TextColumn get purchaseDate => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class ServiceJobs extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
  TextColumn get problemDesc => text().nullable()();
  RealColumn get labourCharge => real().withDefault(const Constant(0))();
  TextColumn get serviceDate => text()();
  TextColumn get invoiceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ServiceParts extends Table {
  TextColumn get id => text()();
  TextColumn get serviceId => text().references(ServiceJobs, #id)();
  TextColumn get partId => text().references(Parts, #id)();
  IntColumn get quantity => integer()();
  RealColumn get priceEach => real()(); // snapshot at billing time

  @override
  Set<Column> get primaryKey => {id};
}

class Invoices extends Table {
  TextColumn get id => text()();
  IntColumn get invoiceNumber => integer().unique()();
  TextColumn get serviceId => text().references(ServiceJobs, #id)();
  RealColumn get totalAmount => real()();
  TextColumn get createdDate => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  BoolColumn get isPersonal => boolean().withDefault(const Constant(false))();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  TextColumn get entryDate => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Employees extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get monthlySalary => real()();

  @override
  Set<Column> get primaryKey => {id};
}

class SalaryPayments extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text().references(Employees, #id)();
  RealColumn get amount => real()();
  TextColumn get paymentDate => text()();
  TextColumn get status => text()(); // 'paid' | 'pending'

  @override
  Set<Column> get primaryKey => {id};
}

// Attendance tracking table
class Attendances extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text().references(Employees, #id)();
  TextColumn get date => text()(); // YYYY-MM-DD
  TextColumn get status => text()(); // 'present' | 'absent'
  TextColumn get reportingTime => text().nullable()(); // 'HH:mm'

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {employeeId, date},
  ];
}

// Invoice numbering counter — avoids collisions, server-migration-friendly
class Counters extends Table {
  TextColumn get name => text()();
  IntColumn get value => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {name};
}

// Personal finance accounts table
class PersonalFinanceAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  TextColumn get createdDate => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// Personal finance transactions table
class PersonalFinanceTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(PersonalFinanceAccounts, #id)();
  TextColumn get type => text()(); // 'credit' | 'debit'
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get payee => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get transactionDate => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- Database ----------

@DriftDatabase(
  tables: [
    Customers,
    Parts,
    Purchases,
    ServiceJobs,
    ServiceParts,
    Invoices,
    Expenses,
    Employees,
    SalaryPayments,
    Attendances,
    Counters,
    PersonalFinanceAccounts,
    PersonalFinanceTransactions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e) : super();

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // seed the invoice number counter
      await into(counters).insert(
        CountersCompanion.insert(name: 'invoice_number', value: const Value(0)),
      );
      // seed default owner account
      await into(personalFinanceAccounts).insert(
        PersonalFinanceAccountsCompanion.insert(
          id: 'default-owner-account',
          name: "Owner's Account",
          openingBalance: const Value(0.0),
          createdDate: DateTime.now().toIso8601String(),
        ),
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(attendances);
      }
      if (from < 3) {
        await m.createTable(personalFinanceAccounts);
        await m.createTable(personalFinanceTransactions);
        await into(personalFinanceAccounts).insert(
          PersonalFinanceAccountsCompanion.insert(
            id: 'default-owner-account',
            name: "Owner's Account",
            openingBalance: const Value(0.0),
            createdDate: DateTime.now().toIso8601String(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'inventory_management.sqlite'));
    return NativeDatabase(file);
  });
}
