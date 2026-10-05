import '../../models/invoice.dart';

abstract class InvoiceRepository {
  Future<Invoice> create(Invoice invoice);

  Future<Invoice?> getById(String id);

  Future<Invoice?> getByInvoiceNumber(int invoiceNumber);

  Future<List<Invoice>> getAll();

  Future<int> nextInvoiceNumber();
}