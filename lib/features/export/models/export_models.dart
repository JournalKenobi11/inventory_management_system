import '../../../core/config/establishment_config.dart';
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

  // Garage / Establishment Profile & GST Settings
  final String garageName;
  final String? garageServices;
  final String? garagePhone;
  final String? garageAddress;
  final String? gstNumber;
  final bool isGstRegistered;
  final double gstRatePercentage;
  final String? upiId;

  const InvoicePdfData({
    required this.invoice,
    required this.service,
    required this.customer,
    required this.parts,
    required this.labourCharge,
    required this.totalAmount,
    this.garageName = EstablishmentConfig.name,
    this.garageServices = EstablishmentConfig.services,
    this.garagePhone = EstablishmentConfig.phone,
    this.garageAddress = EstablishmentConfig.address,
    this.gstNumber,
    this.isGstRegistered = false,
    this.gstRatePercentage = 18.0,
    this.upiId,
  });

  factory InvoicePdfData.fromDetails(
    InvoiceDetails details, {
    String garageName = EstablishmentConfig.name,
    String? garageServices = EstablishmentConfig.services,
    String? garagePhone = EstablishmentConfig.phone,
    String? garageAddress = EstablishmentConfig.address,
    String? gstNumber,
    bool isGstRegistered = false,
    double gstRatePercentage = 18.0,
    String? upiId,
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
      garageServices: garageServices,
      garagePhone: garagePhone,
      garageAddress: garageAddress,
      gstNumber: gstNumber,
      isGstRegistered: isGstRegistered,
      gstRatePercentage: gstRatePercentage,
      upiId: upiId,
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

  /// Effective payable amount: if there is an advance, use balance due (or 0 if fully paid);
  /// otherwise grandTotal.
  double get payableAmount {
    if (invoice.advanceAmount > 0) {
      return invoice.balanceDue > 0 ? invoice.balanceDue : 0.0;
    }
    return grandTotal;
  }

  /// Builds standard NPCI UPI URI if [upiId] is configured.
  String? get upiUri {
    final cleanUpi = upiId?.trim() ?? '';
    if (cleanUpi.isEmpty) return null;

    final encodedName = Uri.encodeComponent(garageName.trim());
    final amountFormatted = (payableAmount < 0 ? 0.0 : payableAmount).toStringAsFixed(2);
    final note = 'Bill #${invoice.invoiceNumber}';
    final encodedNote = Uri.encodeComponent(note);

    return 'upi://pay?pa=$cleanUpi&pn=$encodedName&am=$amountFormatted&cu=INR&tn=$encodedNote';
  }
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
