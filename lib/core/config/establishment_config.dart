/// Single source of truth for establishment / business profile.
///
/// Holds the establishment identity, services offered, owner phone number,
/// and physical address. All billing PDFs, reports, and messages pull
/// directly from this configuration.
class EstablishmentConfig {
  const EstablishmentConfig._();

  /// Legal / Trade name of the establishment
  static const String name = 'Mestry Motors';

  /// Type and category of services provided
  static const String services = 'E-BIKE sales and services';

  /// Owner / Establishment contact phone number
  static const String phone = '9359664276';

  /// Physical street address of the establishment
  static const String address =
      'Gala No. 1, Siddhi Sagar Apartments, Entry Gate Road, Dahanu East, Dist- Palghar';
}
