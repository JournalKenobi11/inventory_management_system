import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/features/billing/billing.dart';
import 'package:inventory_management_system/features/customers/customers.dart';
import 'package:inventory_management_system/features/export/export.dart';

void main() {
  late ShareService shareService;

  setUp(() {
    shareService = ShareService();
  });

  final sampleCustomer = Customer(
    id: 'cust-101',
    name: 'Rahul Sharma',
    mobile: '9876543210',
    vehicleName: 'Honda City',
    createdDate: '2026-10-08T10:00:00.000Z',
  );

  final sampleService = Service(
    id: 'srv-101',
    customerId: 'cust-101',
    problemDesc: 'Brake pad replacement and wheel alignment',
    labourCharge: 500.0,
    serviceDate: '2026-10-08T10:00:00.000Z',
  );

  final sampleInvoice = Invoice(
    id: 'inv-101',
    invoiceNumber: 123,
    serviceId: 'srv-101',
    totalAmount: 2650.0,
    createdDate: '2026-10-08T10:00:00.000Z',
  );

  final sampleItems = [
    const InvoiceLineItem(
      partId: 'part-1',
      partName: 'Brake Pad',
      partNumber: 'BP-01',
      quantity: 2,
      priceEach: 850.0,
      lineTotal: 1700.0,
    ),
    const InvoiceLineItem(
      partId: 'part-2',
      partName: 'Oil Filter',
      partNumber: 'OF-09',
      quantity: 1,
      priceEach: 450.0,
      lineTotal: 450.0,
    ),
  ];

  final sampleDetails = InvoiceDetails(
    invoice: sampleInvoice,
    service: sampleService,
    customer: sampleCustomer,
    items: sampleItems,
    labourCharge: 500.0,
    totalAmount: 2650.0,
  );

  group('ShareService WhatsApp message formatting', () {
    test('formats complete invoice message with all details', () {
      final message = shareService.formatInvoiceWhatsAppMessage(
        details: sampleDetails,
        garageName: 'Auto Care Garage',
      );

      // Verify invoice number
      expect(message, contains('INVOICE #123'));
      // Verify customer details
      expect(message, contains('Rahul Sharma'));
      expect(message, contains('9876543210'));
      expect(message, contains('Honda City'));
      // Verify service description
      expect(message, contains('Brake pad replacement and wheel alignment'));
      // Verify line items
      expect(message, contains('Brake Pad (BP-01) × 2 = ₹1700.00'));
      expect(message, contains('Oil Filter (OF-09) × 1 = ₹450.00'));
      // Verify subtotals and grand total
      expect(message, contains('Parts: ₹2150.00'));
      expect(message, contains('Labour: ₹500.00'));
      expect(message, contains('Total: ₹2650.00'));
      expect(message, contains('Thank you for your business!'));
    });

    test('handles service without parts gracefully', () {
      final labourOnlyDetails = InvoiceDetails(
        invoice: sampleInvoice.copyWith(totalAmount: 500.0),
        service: sampleService,
        customer: sampleCustomer,
        items: const [],
        labourCharge: 500.0,
        totalAmount: 500.0,
      );

      final message = shareService.formatInvoiceWhatsAppMessage(
        details: labourOnlyDetails,
      );

      expect(message, contains('Labour: ₹500.00'));
      expect(message, contains('Total: ₹500.00'));
      expect(message, isNot(contains('Parts:')));
    });

    test('returns invalidRecipient error when customer phone cannot be normalized', () async {
      final result = await shareService.shareInvoiceToWhatsApp(
        customerPhone: 'invalid-number',
        message: 'Hello',
      );

      expect(result.success, isFalse);
      expect(result.isInvalidRecipient, isTrue);
      expect(result.errorMessage, contains('Could not format mobile number'));
    });
  });

  group('InvoicePdfData.fromDetails conversion', () {
    test('accurately maps InvoiceDetails to InvoicePdfData', () {
      final pdfData = InvoicePdfData.fromDetails(
        sampleDetails,
        garageName: 'Auto Care Hub',
      );

      expect(pdfData.invoice.invoiceNumber, equals(123));
      expect(pdfData.customer.name, equals('Rahul Sharma'));
      expect(pdfData.parts.length, equals(2));
      expect(pdfData.parts[0].partName, equals('Brake Pad'));
      expect(pdfData.parts[0].partNumber, equals('BP-01'));
      expect(pdfData.parts[0].quantity, equals(2));
      expect(pdfData.parts[0].lineTotal, equals(1700.0));
      expect(pdfData.partsTotal, equals(2150.0));
      expect(pdfData.labourCharge, equals(500.0));
      expect(pdfData.grandTotal, equals(2650.0));
    });
  });
}
