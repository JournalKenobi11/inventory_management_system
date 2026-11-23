import '../../../core/config/establishment_config.dart';

/// Immutable model representing shop/business profile settings.
class ShopSettings {
  final String businessName;
  final String ownerName;
  final String phone;
  final String address;
  final String services;
  final String upiId;

  const ShopSettings({
    this.businessName = EstablishmentConfig.name,
    this.ownerName = '',
    this.phone = EstablishmentConfig.phone,
    this.address = EstablishmentConfig.address,
    this.services = EstablishmentConfig.services,
    this.upiId = '',
  });

  /// Default fallback configuration matching [EstablishmentConfig].
  static const ShopSettings defaults = ShopSettings();

  ShopSettings copyWith({
    String? businessName,
    String? ownerName,
    String? phone,
    String? address,
    String? services,
    String? upiId,
  }) {
    return ShopSettings(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      services: services ?? this.services,
      upiId: upiId ?? this.upiId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'services': services,
      'upiId': upiId,
    };
  }

  factory ShopSettings.fromJson(Map<String, dynamic> json) {
    return ShopSettings(
      businessName: json['businessName'] as String? ?? EstablishmentConfig.name,
      ownerName: json['ownerName'] as String? ?? '',
      phone: json['phone'] as String? ?? EstablishmentConfig.phone,
      address: json['address'] as String? ?? EstablishmentConfig.address,
      services: json['services'] as String? ?? EstablishmentConfig.services,
      upiId: json['upiId'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopSettings &&
          runtimeType == other.runtimeType &&
          businessName == other.businessName &&
          ownerName == other.ownerName &&
          phone == other.phone &&
          address == other.address &&
          services == other.services &&
          upiId == other.upiId;

  @override
  int get hashCode =>
      businessName.hashCode ^
      ownerName.hashCode ^
      phone.hashCode ^
      address.hashCode ^
      services.hashCode ^
      upiId.hashCode;

  @override
  String toString() {
    return 'ShopSettings(businessName: $businessName, ownerName: $ownerName, phone: $phone, address: $address, services: $services, upiId: $upiId)';
  }
}
