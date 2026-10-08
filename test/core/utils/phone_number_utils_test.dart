import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/core/utils/phone_number_utils.dart';

void main() {
  group('PhoneNumberUtils.normalizeForWhatsApp', () {
    test('normalizes standard 10-digit Indian numbers with 91 prefix', () {
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('9876543210'),
        equals('919876543210'),
      );
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('9845012345'),
        equals('919845012345'),
      );
    });

    test('normalizes 10-digit Indian numbers with spaces and formatting', () {
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('98765 43210'),
        equals('919876543210'),
      );
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('9876-543-210'),
        equals('919876543210'),
      );
    });

    test('normalizes Indian numbers with +91 prefix correctly', () {
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('+91 9876543210'),
        equals('919876543210'),
      );
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('+919876543210'),
        equals('919876543210'),
      );
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('+91 98450 12345'),
        equals('919845012345'),
      );
    });

    test('normalizes Indian numbers with 91 prefix without plus', () {
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('919876543210'),
        equals('919876543210'),
      );
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('91 9876543210'),
        equals('919876543210'),
      );
    });

    test('normalizes Indian numbers with leading 0 trunk prefix', () {
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('09876543210'),
        equals('919876543210'),
      );
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('0 98765 43210'),
        equals('919876543210'),
      );
    });

    test('does NOT blindly prepend 91 to international numbers with +', () {
      // US number
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('+1 (555) 123-4567'),
        equals('15551234567'),
      );
      // UK number
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('+44 7911 123456'),
        equals('447911123456'),
      );
      // UAE number
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('+971 50 123 4567'),
        equals('971501234567'),
      );
      // Singapore number
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('+65 9123 4567'),
        equals('6591234567'),
      );
    });

    test('handles international numbers starting with 00 exit prefix', () {
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('0015551234567'),
        equals('15551234567'),
      );
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('00919876543210'),
        equals('919876543210'),
      );
    });

    test('returns null for invalid or unparseable inputs', () {
      expect(PhoneNumberUtils.normalizeForWhatsApp(null), isNull);
      expect(PhoneNumberUtils.normalizeForWhatsApp(''), isNull);
      expect(PhoneNumberUtils.normalizeForWhatsApp('   '), isNull);
      expect(PhoneNumberUtils.normalizeForWhatsApp('abc'), isNull);
      expect(PhoneNumberUtils.normalizeForWhatsApp('12345'), isNull); // Too short (< 7)
      expect(
        PhoneNumberUtils.normalizeForWhatsApp('+1234567890123456'),
        isNull,
      ); // Too long (> 15)
    });
  });

  group('PhoneNumberUtils.isValid & formatDisplay', () {
    test('isValid returns true for valid numbers and false for invalid', () {
      expect(PhoneNumberUtils.isValid('9876543210'), isTrue);
      expect(PhoneNumberUtils.isValid('+91 9876543210'), isTrue);
      expect(PhoneNumberUtils.isValid('+1 555 123 4567'), isTrue);
      expect(PhoneNumberUtils.isValid('1234'), isFalse);
      expect(PhoneNumberUtils.isValid(''), isFalse);
      expect(PhoneNumberUtils.isValid(null), isFalse);
    });

    test('formatDisplay formats Indian and international numbers cleanly', () {
      expect(
        PhoneNumberUtils.formatDisplay('9876543210'),
        equals('+91 98765 43210'),
      );
      expect(
        PhoneNumberUtils.formatDisplay('+15551234567'),
        equals('+15551234567'),
      );
    });
  });
}
