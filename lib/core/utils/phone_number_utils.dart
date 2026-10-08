class PhoneNumberUtils {
  /// Normalizes a phone number for WhatsApp wa.me links.
  ///
  /// For Indian phone numbers:
  /// - 10-digit mobile (e.g. "9876543210") -> "919876543210"
  /// - "+91 9876543210" / "+919876543210" -> "919876543210"
  /// - "91 9876543210" / "919876543210" -> "919876543210"
  /// - "09876543210" / "0 9876543210" -> "919876543210"
  ///
  /// For international numbers with explicit prefix:
  /// - "+1 555 123 4567" -> "15551234567" (country code preserved without prepending 91)
  /// - "+44 7911 123456" -> "447911123456"
  /// - "0015551234567" -> "15551234567"
  ///
  /// Returns `null` if the number is empty, invalid, or cannot be safely normalized.
  static String? normalizeForWhatsApp(String? rawPhone) {
    if (rawPhone == null) return null;
    final trimmed = rawPhone.trim();
    if (trimmed.isEmpty) return null;

    final hasPlus = trimmed.startsWith('+');
    // Extract only digits
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    // 1. Explicit international format with '+'
    if (hasPlus) {
      if (digits.length >= 7 && digits.length <= 15) {
        return digits;
      }
      return null;
    }

    // 2. International format starting with exit code '00'
    if (digits.startsWith('00') && digits.length >= 9) {
      final without00 = digits.substring(2);
      if (without00.length >= 7 && without00.length <= 15) {
        return without00;
      }
      return null;
    }

    // 3. Indian standard 10-digit mobile number
    if (digits.length == 10) {
      return '91$digits';
    }

    // 4. Indian number with leading '0' trunk/STD code (11 digits)
    if (digits.length == 11 && digits.startsWith('0')) {
      final tenDigits = digits.substring(1);
      return '91$tenDigits';
    }

    // 5. Indian number already having '91' country code without '+' (12 digits)
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits;
    }

    // 6. Generic valid E.164 digit length (7 to 15 digits)
    if (digits.length >= 7 && digits.length <= 15) {
      return digits;
    }

    return null;
  }

  /// Checks if a raw phone number can be normalized into a valid recipient.
  static bool isValid(String? rawPhone) {
    return normalizeForWhatsApp(rawPhone) != null;
  }

  /// Formats a phone number for display in the UI.
  static String formatDisplay(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return '';
    final normalized = normalizeForWhatsApp(rawPhone);
    if (normalized == null) return rawPhone.trim();

    if (normalized.startsWith('91') && normalized.length == 12) {
      final tenDigits = normalized.substring(2);
      return '+91 ${tenDigits.substring(0, 5)} ${tenDigits.substring(5)}';
    }

    return '+$normalized';
  }
}
