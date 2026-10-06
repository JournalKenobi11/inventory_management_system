import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../../billing/billing.dart';
import '../../customers/customers.dart';

class ShareService {
  Future<ShareResult> sharePdfFile(
    File pdfFile, {
    String? subject,
    String? message,
  }) async {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(pdfFile.path, mimeType: 'application/pdf')],
        subject: subject,
        text: message,
      ),
    );
  }

  Future<ShareResult> shareInvoicePdf(
    File pdfFile, {
    required int invoiceNumber,
    String? customerName,
    String? customerMobile,
    String garageName = 'Auto Care Garage',
  }) async {
    final customerInfo = customerName != null ? ' for $customerName' : '';
    final message =
        'Here is your invoice #$invoiceNumber$customerInfo from $garageName. Thank you for your business!';

    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(pdfFile.path, mimeType: 'application/pdf')],
        subject: 'Invoice #$invoiceNumber - $garageName',
        text: message,
      ),
    );
  }

  Future<ShareResult> shareInvoiceAsWhatsAppText({
    required Invoice invoice,
    required Customer customer,
    required List<ServicePart> serviceParts,
    required double labourCharge,
    Map<String, String>? partNamesById,
    String garageName = 'Auto Care Garage & Service Center',
    String? garagePhone,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('*$garageName*');
    if (garagePhone != null && garagePhone.isNotEmpty) {
      buffer.writeln('Contact: $garagePhone');
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('*INVOICE #${invoice.invoiceNumber}*');
    final dateStr = invoice.createdDate.length >= 10
        ? invoice.createdDate.substring(0, 10)
        : invoice.createdDate;
    buffer.writeln('Date: $dateStr');
    buffer.writeln('Customer: ${customer.name} (${customer.mobile})');
    if (customer.vehicleName != null && customer.vehicleName!.isNotEmpty) {
      buffer.writeln('Vehicle: ${customer.vehicleName!}');
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('*Services & Parts:*');

    var count = 1;
    for (final sp in serviceParts) {
      final fallbackId = sp.partId.length > 6 ? sp.partId.substring(0, 6) : sp.partId;
      final name = partNamesById?[sp.partId] ?? 'Part $fallbackId';
      buffer.writeln(
        '${count++}. $name x${sp.quantity} @ Rs.${sp.priceEach.toStringAsFixed(2)} = Rs.${sp.lineTotal.toStringAsFixed(2)}',
      );
    }

    if (labourCharge > 0) {
      buffer.writeln(
        '${count++}. Labour / Service Charge = Rs.${labourCharge.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('------------------------------------');
    buffer.writeln(
        '*TOTAL AMOUNT: Rs.${invoice.totalAmount.toStringAsFixed(2)}*');
    buffer.writeln('------------------------------------');
    buffer.writeln('Thank you for choosing us!');

    return SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: 'Invoice #${invoice.invoiceNumber} - $garageName',
      ),
    );
  }

  Future<ShareResult> shareBackupFile(
    File backupFile, {
    String? subject,
  }) async {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(backupFile.path)],
        subject: subject ?? 'Inventory Management System Backup',
        text: 'Database backup generated from Inventory Management System.',
      ),
    );
  }
}
