import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('can insert and read a customer', () async {
    await db.into(db.customers).insert(
          CustomersCompanion.insert(
            id: 'test-id-1',
            name: 'Test Customer',
            mobile: '9999999999',
            createdDate: '2026-07-26T00:00:00.000',
          ),
        );

    final result = await db.select(db.customers).get();
    expect(result.length, 1);
    expect(result.first.name, 'Test Customer');
  });
}
