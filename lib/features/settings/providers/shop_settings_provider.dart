import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../models/shop_settings.dart';
import '../repositories/interfaces/shop_settings_repository.dart';
import '../repositories/sqlite/sqlite_shop_settings_repository.dart';
import '../services/shop_settings_service.dart';

final shopSettingsRepositoryProvider = Provider<ShopSettingsRepository>((ref) {
  return SqliteShopSettingsRepository(
    ref.read(appDatabaseProvider),
  );
});

final shopSettingsServiceProvider = Provider<ShopSettingsService>((ref) {
  return ShopSettingsService(
    ref.read(shopSettingsRepositoryProvider),
  );
});

final shopSettingsProvider =
    AsyncNotifierProvider<ShopSettingsNotifier, ShopSettings>(
  ShopSettingsNotifier.new,
);

class ShopSettingsNotifier extends AsyncNotifier<ShopSettings> {
  ShopSettingsService get service => ref.read(shopSettingsServiceProvider);

  @override
  Future<ShopSettings> build() async {
    return service.getSettings();
  }

  Future<void> updateSettings(ShopSettings newSettings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await service.saveSettings(newSettings);
      return newSettings;
    });
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => service.getSettings());
  }
}
