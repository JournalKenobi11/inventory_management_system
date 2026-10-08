import '../../customers/customers.dart';
import 'invoice.dart';
import 'service.dart';

class InvoiceLineItem {
  final String partId;
  final String partName;
  final String? partNumber;
  final int quantity;
  final double priceEach;
  final double lineTotal;

  const InvoiceLineItem({
    required this.partId,
    required this.partName,
    this.partNumber,
    required this.quantity,
    required this.priceEach,
    required this.lineTotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'partId': partId,
      'partName': partName,
      'partNumber': partNumber,
      'quantity': quantity,
      'priceEach': priceEach,
      'lineTotal': lineTotal,
    };
  }

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      partId: json['partId'] as String,
      partName: json['partName'] as String,
      partNumber: json['partNumber'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      priceEach: (json['priceEach'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }
}

class InvoiceDetails {
  final Invoice invoice;
  final Service service;
  final Customer customer;
  final List<InvoiceLineItem> items;
  final double labourCharge;
  final double totalAmount;

  const InvoiceDetails({
    required this.invoice,
    required this.service,
    required this.customer,
    required this.items,
    required this.labourCharge,
    required this.totalAmount,
  });

  double get partsSubtotal =>
      items.fold<double>(0.0, (sum, item) => sum + item.lineTotal);

  double get grandTotal => totalAmount;

  String get formattedDate {
    if (invoice.createdDate.length >= 10) {
      final isoPart = invoice.createdDate.substring(0, 10);
      final parts = isoPart.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return isoPart;
    }
    return invoice.createdDate;
  }
}
