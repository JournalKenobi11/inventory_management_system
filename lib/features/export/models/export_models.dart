import '../../billing/billing.dart';
import '../../customers/customers.dart';

class InvoicePartLineItem {
  final String partId;
  final String partName;
  final String partNumber;
  final int quantity;
  final double priceEach;
  final double lineTotal;

  const InvoicePartLineItem({
    required this.partId,
    required this.partName,
    required this.partNumber,
    required this.quantity,
    required this.priceEach,
    required this.lineTotal,
  });
}

class InvoicePdfData {
  final Invoice invoice;
  final Service service;
  final Customer customer;
  final List<InvoicePartLineItem> parts;
  final double labourCharge;
  final double totalAmount;

  // Garage Profile & GST Settings
  final String garageName;
  final String? garagePhone;
  final String? garageAddress;
  final String? gstNumber;
  final bool isGstRegistered;
  final double gstRatePercentage;

  const InvoicePdfData({
    required this.invoice,
    required this.service,
    required this.customer,
    required this.parts,
    required this.labourCharge,
    required this.totalAmount,
    this.garageName = 'Auto Care Garage & Service Center',
    this.garagePhone,
    this.garageAddress,
    this.gstNumber,
    this.isGstRegistered = false,
    this.gstRatePercentage = 18.0,
  });

  factory InvoicePdfData.fromDetails(
    InvoiceDetails details, {
    String garageName = 'Auto Care Garage & Service Center',
    String? garagePhone,
    String? garageAddress,
    String? gstNumber,
    bool isGstRegistered = false,
    double gstRatePercentage = 18.0,
  }) {
    return InvoicePdfData(
      invoice: details.invoice,
      service: details.service,
      customer: details.customer,
      parts: details.items
          .map(
            (item) => InvoicePartLineItem(
              partId: item.partId,
              partName: item.partName,
              partNumber: item.partNumber ?? '',
              quantity: item.quantity,
              priceEach: item.priceEach,
              lineTotal: item.lineTotal,
            ),
          )
          .toList(),
      labourCharge: details.labourCharge,
      totalAmount: details.totalAmount,
      garageName: garageName,
      garagePhone: garagePhone,
      garageAddress: garageAddress,
      gstNumber: gstNumber,
      isGstRegistered: isGstRegistered,
      gstRatePercentage: gstRatePercentage,
    );
  }

  double get partsTotal =>
      parts.fold<double>(0.0, (sum, p) => sum + p.lineTotal);

  double get subtotal => partsTotal + labourCharge;

  double get cgstAmount =>
      isGstRegistered ? (subtotal * (gstRatePercentage / 2)) / 100 : 0.0;

  double get sgstAmount =>
      isGstRegistered ? (subtotal * (gstRatePercentage / 2)) / 100 : 0.0;

  double get totalGstAmount => cgstAmount + sgstAmount;

  double get grandTotal =>
      isGstRegistered ? (subtotal + totalGstAmount) : totalAmount;
}

class BackupSummary {
  final String exportDate;
  final int version;
  final int totalRecords;
  final Map<String, int> tableCounts;
  final String? filePath;
  final int? fileSizeBytes;

  const BackupSummary({
    required this.exportDate,
    required this.version,
    required this.totalRecords,
    required this.tableCounts,
    this.filePath,
    this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() => {
    'exportDate': exportDate,
    'version': version,
    'totalRecords': totalRecords,
    'tableCounts': tableCounts,
    'filePath': filePath,
    'fileSizeBytes': fileSizeBytes,
  };
}

class RestoreResult {
  final bool success;
  final Map<String, int> restoredCounts;
  final String message;

  const RestoreResult({
    required this.success,
    required this.restoredCounts,
    required this.message,
  });
}
