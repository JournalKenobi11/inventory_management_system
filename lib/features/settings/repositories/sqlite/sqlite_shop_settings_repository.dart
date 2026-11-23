import 'package:drift/drift.dart';
import '../../../../database/app_database.dart';
import '../../models/shop_settings.dart';
import '../interfaces/shop_settings_repository.dart';

class SqliteShopSettingsRepository implements ShopSettingsRepository {
  final AppDatabase db;
  static const String _primaryKey = 'primary_shop';

  SqliteShopSettingsRepository(this.db);

  @override
  Future<ShopSettings> getSettings() async {
    final query = db.select(db.shopSettingsTable)
      ..where((tbl) => tbl.id.equals(_primaryKey));
    final row = await query.getSingleOrNull();

    if (row == null) {
      return ShopSettings.defaults;
    }

    return ShopSettings(
      businessName: row.businessName,
      ownerName: row.ownerName ?? '',
      phone: row.phone,
      address: row.address,
      services: row.services,
      upiId: row.upiId ?? '',
    );
  }

  @override
  Future<void> saveSettings(ShopSettings settings) async {
    await db.into(db.shopSettingsTable).insertOnConflictUpdate(
          ShopSettingsTableCompanion.insert(
            id: _primaryKey,
            businessName: settings.businessName,
            ownerName: Value(settings.ownerName),
            phone: settings.phone,
            address: settings.address,
            services: settings.services,
            upiId: Value(settings.upiId),
          ),
        );
  }
}
