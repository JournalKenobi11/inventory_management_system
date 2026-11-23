import '../../../core/errors/app_exceptions.dart';
import '../models/shop_settings.dart';
import '../repositories/interfaces/shop_settings_repository.dart';

class ShopSettingsService {
  final ShopSettingsRepository repository;

  static final RegExp _upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');

  ShopSettingsService(this.repository);

  Future<ShopSettings> getSettings() async {
    return await repository.getSettings();
  }

  Future<void> saveSettings(ShopSettings settings) async {
    validateSettings(settings);
    await repository.saveSettings(settings);
  }

  /// Validates shop settings fields according to business rules.
  void validateSettings(ShopSettings settings) {
    if (settings.businessName.trim().isEmpty) {
      throw ValidationException('Business name cannot be empty');
    }

    final trimmedPhone = settings.phone.trim().replaceAll(RegExp(r'[\s\-]'), '');
    final digitsOnly = trimmedPhone.startsWith('+91')
        ? trimmedPhone.substring(3)
        : (trimmedPhone.startsWith('0') ? trimmedPhone.substring(1) : trimmedPhone);

    if (!RegExp(r'^[0-9]{10}$').hasMatch(digitsOnly)) {
      throw ValidationException('Phone number must be a valid 10-digit mobile number');
    }

    final upi = settings.upiId.trim();
    if (upi.isNotEmpty && !_upiRegex.hasMatch(upi)) {
      throw ValidationException('Invalid UPI ID format. Example: name@bank or mestrymotors@okhdfcbank');
    }
  }

  /// Builds a standard NPCI UPI payment deep link URI.
  ///
  /// Format: upi://pay?pa=<UPI_ID>&pn=<ENCODED_BUSINESS_NAME>&am=<AMOUNT>&cu=INR&tn=<ENCODED_NOTE>
  /// Amount is formatted to 2 decimals.
  static String buildUpiUri({
    required String upiId,
    required String businessName,
    required double amount,
    String? note,
  }) {
    final cleanUpi = upiId.trim();
    if (cleanUpi.isEmpty) return '';

    final encodedPn = Uri.encodeComponent(businessName.trim());
    final amountFormatted = (amount < 0 ? 0.0 : amount).toStringAsFixed(2);
    final encodedNote = Uri.encodeComponent((note ?? 'Payment to $businessName').trim());

    return 'upi://pay?pa=$cleanUpi&pn=$encodedPn&am=$amountFormatted&cu=INR&tn=$encodedNote';
  }
}
