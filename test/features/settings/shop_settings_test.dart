import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/core/errors/app_exceptions.dart';
import 'package:inventory_management_system/database/app_database.dart';
import 'package:inventory_management_system/features/settings/settings.dart';
import 'package:inventory_management_system/features/settings/repositories/sqlite/sqlite_shop_settings_repository.dart';

void main() {
  group('ShopSettings Model', () {
    test('defaults match EstablishmentConfig', () {
      const settings = ShopSettings.defaults;
      expect(settings.businessName, equals('Mestry Motors'));
      expect(settings.ownerName, equals(''));
      expect(settings.phone, equals('9359664276'));
      expect(settings.services, equals('E-BIKE sales and services'));
      expect(settings.upiId, equals(''));
    });

    test('copyWith updates specified fields only', () {
      const original = ShopSettings.defaults;
      final updated = original.copyWith(
        businessName: 'Super Motors',
        upiId: 'super@okaxis',
      );

      expect(updated.businessName, equals('Super Motors'));
      expect(updated.upiId, equals('super@okaxis'));
      expect(updated.phone, equals(original.phone));
      expect(updated.address, equals(original.address));
    });

    test('toJson and fromJson work correctly', () {
      const settings = ShopSettings(
        businessName: 'Custom Garage',
        ownerName: 'Kenobi',
        phone: '9876543210',
        address: '123 Street',
        services: 'EV Service',
        upiId: 'kenobi@upi',
      );

      final json = settings.toJson();
      final restored = ShopSettings.fromJson(json);

      expect(restored, equals(settings));
    });
  });

  group('ShopSettingsService & Validations', () {
    late AppDatabase db;
    late SqliteShopSettingsRepository repository;
    late ShopSettingsService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = SqliteShopSettingsRepository(db);
      service = ShopSettingsService(repository);
    });

    tearDown(() async {
      await db.close();
    });

    test('getSettings returns seeded defaults from fresh database', () async {
      final settings = await service.getSettings();
      expect(settings.businessName, equals('Mestry Motors'));
      expect(settings.phone, equals('9359664276'));
    });

    test('saveSettings persists and retrieves updated settings', () async {
      const updated = ShopSettings(
        businessName: 'Kenobi E-Bikes',
        ownerName: 'General Kenobi',
        phone: '9123456789',
        address: 'Sector 4, Spaceport',
        services: 'Speeders & E-Bikes',
        upiId: 'kenobi@okhdfcbank',
      );

      await service.saveSettings(updated);
      final fetched = await service.getSettings();

      expect(fetched.businessName, equals('Kenobi E-Bikes'));
      expect(fetched.ownerName, equals('General Kenobi'));
      expect(fetched.phone, equals('9123456789'));
      expect(fetched.upiId, equals('kenobi@okhdfcbank'));
    });

    test('validates business name cannot be empty', () async {
      const invalid = ShopSettings(
        businessName: '   ',
        phone: '9876543210',
      );

      expect(
        () => service.validateSettings(invalid),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Business name cannot be empty'),
        )),
      );
    });

    test('validates phone number must be 10 digits', () {
      const shortPhone = ShopSettings(
        businessName: 'Test Garage',
        phone: '12345',
      );
      expect(
        () => service.validateSettings(shortPhone),
        throwsA(isA<ValidationException>()),
      );

      const invalidChars = ShopSettings(
        businessName: 'Test Garage',
        phone: '98765abcde',
      );
      expect(
        () => service.validateSettings(invalidChars),
        throwsA(isA<ValidationException>()),
      );

      // Valid phone with leading +91 or spaces
      const formattedPhone = ShopSettings(
        businessName: 'Test Garage',
        phone: '+91 9359664276',
      );
      expect(() => service.validateSettings(formattedPhone), returnsNormally);
    });

    test('validates UPI ID regex when non-empty', () {
      const invalidUpi = ShopSettings(
        businessName: 'Test Garage',
        phone: '9876543210',
        upiId: 'invalid-upi-without-at',
      );
      expect(
        () => service.validateSettings(invalidUpi),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Invalid UPI ID format'),
        )),
      );

      const validUpi1 = ShopSettings(
        businessName: 'Test Garage',
        phone: '9876543210',
        upiId: 'mestrymotors@okhdfcbank',
      );
      expect(() => service.validateSettings(validUpi1), returnsNormally);

      const validUpi2 = ShopSettings(
        businessName: 'Test Garage',
        phone: '9876543210',
        upiId: '9359664276@ybl',
      );
      expect(() => service.validateSettings(validUpi2), returnsNormally);

      // Empty UPI ID is allowed
      const emptyUpi = ShopSettings(
        businessName: 'Test Garage',
        phone: '9876543210',
        upiId: '',
      );
      expect(() => service.validateSettings(emptyUpi), returnsNormally);
    });

    test('buildUpiUri generates standard NPCI deep link format', () {
      final uri = ShopSettingsService.buildUpiUri(
        upiId: 'mestrymotors@okhdfcbank',
        businessName: 'Mestry Motors',
        amount: 2500.50,
        note: 'Bill #INV-001',
      );

      expect(uri, contains('upi://pay?'));
      expect(uri, contains('pa=mestrymotors@okhdfcbank'));
      expect(uri, contains('pn=Mestry%20Motors'));
      expect(uri, contains('am=2500.50'));
      expect(uri, contains('cu=INR'));
      expect(uri, contains('tn=Bill%20%23INV-001'));
    });

    test('buildUpiUri returns empty string if upiId is empty', () {
      final uri = ShopSettingsService.buildUpiUri(
        upiId: '   ',
        businessName: 'Mestry Motors',
        amount: 1000.0,
      );
      expect(uri, isEmpty);
    });
  });
}
