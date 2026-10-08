import 'dart:io';

import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/phone_number_utils.dart';
import '../../billing/billing.dart';
import '../../customers/customers.dart';

class WhatsAppShareResult {
  final bool success;
  final String? errorMessage;
  final bool isInvalidRecipient;
  final bool isWhatsAppUnavailable;

  const WhatsAppShareResult({
    required this.success,
    this.errorMessage,
    this.isInvalidRecipient = false,
    this.isWhatsAppUnavailable = false,
  });

  factory WhatsAppShareResult.successful() =>
      const WhatsAppShareResult(success: true);

  factory WhatsAppShareResult.invalidRecipient([String? message]) =>
      WhatsAppShareResult(
        success: false,
        isInvalidRecipient: true,
        errorMessage:
            message ?? 'Customer mobile number is missing or invalid.',
      );

  factory WhatsAppShareResult.unavailable([String? message]) =>
      WhatsAppShareResult(
        success: false,
        isWhatsAppUnavailable: true,
        errorMessage:
            message ??
            'WhatsApp is not installed or could not be opened on this device.',
      );

  factory WhatsAppShareResult.failure(String message) =>
      WhatsAppShareResult(success: false, errorMessage: message);
}

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

  /// Formats a complete, readable text invoice for WhatsApp messaging.
  String formatInvoiceWhatsAppMessage({
    required InvoiceDetails details,
    String garageName = 'Auto Care Garage & Service Center',
    String? garagePhone,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('*$garageName*');
    if (garagePhone != null && garagePhone.trim().isNotEmpty) {
      buffer.writeln('Contact: ${garagePhone.trim()}');
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('*INVOICE #${details.invoice.invoiceNumber}*');

    final dateStr = details.formattedDate;
    buffer.writeln('Date: $dateStr');
    buffer.writeln('Customer: ${details.customer.name}');
    buffer.writeln('Mobile: ${details.customer.mobile}');
    if (details.customer.vehicleName != null &&
        details.customer.vehicleName!.trim().isNotEmpty) {
      buffer.writeln('Vehicle: ${details.customer.vehicleName!.trim()}');
    }

    if (details.service.problemDesc != null &&
        details.service.problemDesc!.trim().isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('*Service:*');
      buffer.writeln(details.service.problemDesc!.trim());
    }

    if (details.items.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('*Parts:*');
      for (final item in details.items) {
        final partNo =
            (item.partNumber != null && item.partNumber!.trim().isNotEmpty)
            ? ' (${item.partNumber!.trim()})'
            : '';
        buffer.writeln(
          '${item.partName}$partNo × ${item.quantity} = ₹${item.lineTotal.toStringAsFixed(2)}',
        );
      }
    }

    buffer.writeln('');
    if (details.items.isNotEmpty) {
      buffer.writeln('Parts: ₹${details.partsSubtotal.toStringAsFixed(2)}');
    }
    if (details.labourCharge > 0) {
      buffer.writeln('Labour: ₹${details.labourCharge.toStringAsFixed(2)}');
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('*Total: ₹${details.totalAmount.toStringAsFixed(2)}*');
    buffer.writeln('------------------------------------');
    buffer.writeln('Thank you for your business!');

    return buffer.toString();
  }

  /// Directly opens the WhatsApp conversation for the given [customerPhone]
  /// with a pre-filled [message].
  ///
  /// This targets the specific normalized phone number instead of opening
  /// a generic share dialog.
  Future<WhatsAppShareResult> shareInvoiceToWhatsApp({
    required String customerPhone,
    required String message,
  }) async {
    final normalized = PhoneNumberUtils.normalizeForWhatsApp(customerPhone);
    if (normalized == null) {
      return WhatsAppShareResult.invalidRecipient(
        'Could not format mobile number "$customerPhone" for WhatsApp. Please verify the customer mobile number.',
      );
    }

    final encoded = Uri.encodeComponent(message);
    final whatsappSchemeUri = Uri.parse(
      'whatsapp://send?phone=$normalized&text=$encoded',
    );
    final waMeUri = Uri.parse('https://wa.me/$normalized?text=$encoded');

    try {
      // 1. Try launching via native whatsapp:// scheme
      bool launched = false;
      try {
        if (await canLaunchUrl(whatsappSchemeUri)) {
          launched = await launchUrl(
            whatsappSchemeUri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (_) {
        launched = false;
      }

      if (launched) {
        return WhatsAppShareResult.successful();
      }

      // 2. Try launching via universal wa.me link
      try {
        if (await canLaunchUrl(waMeUri)) {
          launched = await launchUrl(
            waMeUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          // Attempt direct launch anyway if canLaunchUrl check was restricted by OS
          launched = await launchUrl(
            waMeUri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (_) {
        launched = false;
      }

      if (launched) {
        return WhatsAppShareResult.successful();
      }

      return WhatsAppShareResult.unavailable(
        'WhatsApp is not installed or unavailable on this device.',
      );
    } catch (e) {
      return WhatsAppShareResult.failure('Failed to launch WhatsApp: $e');
    }
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
      final fallbackId = sp.partId.length > 6
          ? sp.partId.substring(0, 6)
          : sp.partId;
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
      '*TOTAL AMOUNT: Rs.${invoice.totalAmount.toStringAsFixed(2)}*',
    );
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
