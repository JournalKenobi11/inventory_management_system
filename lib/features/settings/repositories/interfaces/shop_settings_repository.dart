import '../../models/shop_settings.dart';

/// Repository interface for persisting and retrieving shop settings.
abstract class ShopSettingsRepository {
  /// Retrieves the current shop settings, falling back to default values if not yet stored.
  Future<ShopSettings> getSettings();

  /// Persists the updated shop settings.
  Future<void> saveSettings(ShopSettings settings);
}
