import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../../../database/app_database.dart' as db;
import '../../customers/models/customer.dart';
import '../../customers/services/customer_service.dart';
import '../../parts/models/part.dart';
import '../../parts/services/part_service.dart';
import '../models/invoice.dart';
import '../models/invoice_details.dart';
import '../models/service.dart';
import '../models/service_part.dart';
import '../repositories/interfaces/invoice_repository.dart';
import '../repositories/interfaces/service_part_repository.dart';
import '../repositories/interfaces/service_repository.dart';

class BillingService {
  final ServiceRepository serviceRepository;
  final ServicePartRepository servicePartRepository;
  final InvoiceRepository invoiceRepository;
  final CustomerService customerService;
  final PartService partService;
  final db.AppDatabase database;

  BillingService(
    this.serviceRepository,
    this.servicePartRepository,
    this.invoiceRepository,
    this.customerService,
    this.partService,
    this.database,
  );

  Future<Invoice> billService({
    required String customerId,
    required String problemDesc,
    required double labourCharge,
    required List<ServicePartInput> partsUsed,
  }) async {
    final cleanCustomerId = customerId.trim();
    final cleanProblemDesc = problemDesc.trim();

    if (cleanCustomerId.isEmpty) {
      throw ValidationException(
        'Customer ID cannot be empty.',
      );
    }

    if (labourCharge < 0) {
      throw ValidationException(
        'Labour charge cannot be negative.',
      );
    }

    final normalizedParts = _normalizeParts(partsUsed);

    return database.transaction(() async {
      // ------------------------------------------------------------
      // 1. Verify customer
      // ------------------------------------------------------------

      final Customer? customer =
          await customerService.getCustomer(
        cleanCustomerId,
      );

      if (customer == null) {
        throw NotFoundException(
          'Customer',
          cleanCustomerId,
        );
      }

      // ------------------------------------------------------------
      // 2. Validate ALL requested stock BEFORE writing anything
      // ------------------------------------------------------------

      final resolvedParts = <_ResolvedPart>[];

      for (final input in normalizedParts) {
        final Part? part =
            await partService.getPartById(
          input.partId,
        );

        if (part == null) {
          throw NotFoundException(
            'Part',
            input.partId,
          );
        }

        if (part.currentStock < input.quantity) {
          throw InsufficientStockException(
            part.partName,
          );
        }

        resolvedParts.add(
          _ResolvedPart(
            input: input,
            part: part,
          ),
        );
      }

      // ------------------------------------------------------------
      // 3. Create service
      // ------------------------------------------------------------

      final serviceId = IdGenerator.generate();

      final service = Service(
        id: serviceId,
        customerId: customer.id,
        problemDesc: cleanProblemDesc.isEmpty
            ? null
            : cleanProblemDesc,
        labourCharge: labourCharge,
        serviceDate: AppDateUtils.nowIso(),
      );

      await serviceRepository.create(service);

      // ------------------------------------------------------------
      // 4. Create service-part rows
      //
      // priceEach is deliberately copied from the current selling
      // price. This is the historical price snapshot.
      // ------------------------------------------------------------

      double partsTotal = 0;

      for (final resolved in resolvedParts) {
        final servicePart = ServicePart(
          id: IdGenerator.generate(),
          serviceId: serviceId,
          partId: resolved.part.id,
          quantity: resolved.input.quantity,
          priceEach: resolved.part.sellingPrice,
        );

        await servicePartRepository.create(
          servicePart,
        );

        partsTotal +=
            resolved.input.quantity *
                resolved.part.sellingPrice;
      }

      // ------------------------------------------------------------
      // 5. Deduct stock
      // ------------------------------------------------------------

      for (final resolved in resolvedParts) {
        await partService.adjustStock(
          resolved.part.id,
          -resolved.input.quantity,
        );
      }

      // ------------------------------------------------------------
      // 6. Calculate invoice total
      // ------------------------------------------------------------

      final totalAmount =
          partsTotal + labourCharge;

      // ------------------------------------------------------------
      // 7. Generate sequential invoice number
      // ------------------------------------------------------------

      final invoiceNumber =
          await invoiceRepository.nextInvoiceNumber();

      final invoice = Invoice(
        id: IdGenerator.generate(),
        invoiceNumber: invoiceNumber,
        serviceId: serviceId,
        totalAmount: totalAmount,
        createdDate: AppDateUtils.nowIso(),
      );

      final createdInvoice =
          await invoiceRepository.create(invoice);

      // ------------------------------------------------------------
      // 8. Link invoice back to service
      // ------------------------------------------------------------

      await serviceRepository.linkInvoice(
        serviceId,
        createdInvoice.id,
      );

      return createdInvoice;
    });
  }

  Future<Service?> getServiceById(
    String id,
  ) {
    return serviceRepository.getById(id);
  }

  Future<List<Service>> getAllServices() {
    return serviceRepository.getAll();
  }

  Future<List<Service>> getServicesByCustomerId(
    String customerId,
  ) {
    return serviceRepository.getByCustomerId(
      customerId,
    );
  }

  Future<List<ServicePart>> getServiceParts(
    String serviceId,
  ) {
    return servicePartRepository.getByServiceId(
      serviceId,
    );
  }

  Future<Invoice?> getInvoiceById(
    String id,
  ) {
    return invoiceRepository.getById(id);
  }

  Future<Invoice?> getInvoiceByNumber(
    int invoiceNumber,
  ) {
    return invoiceRepository.getByInvoiceNumber(
      invoiceNumber,
    );
  }

  Future<List<Invoice>> getAllInvoices() {
    return invoiceRepository.getAll();
  }

  Future<InvoiceDetails> getInvoiceDetails(String invoiceId) async {
    final invoice = await invoiceRepository.getById(invoiceId);
    if (invoice == null) {
      throw NotFoundException('Invoice', invoiceId);
    }
    return getInvoiceDetailsByInvoice(invoice);
  }

  Future<InvoiceDetails> getInvoiceDetailsByInvoice(Invoice invoice) async {
    final service = await serviceRepository.getById(invoice.serviceId);
    if (service == null) {
      throw NotFoundException('Service', invoice.serviceId);
    }

    final customer = await customerService.getCustomer(service.customerId);
    if (customer == null) {
      throw NotFoundException('Customer', service.customerId);
    }

    final serviceParts =
        await servicePartRepository.getByServiceId(service.id);
    final items = <InvoiceLineItem>[];

    for (final sp in serviceParts) {
      final part = await partService.getPartById(sp.partId);
      final fallbackName =
          sp.partId.length > 6 ? sp.partId.substring(0, 6) : sp.partId;
      items.add(
        InvoiceLineItem(
          partId: sp.partId,
          partName: part?.partName ?? 'Part $fallbackName',
          partNumber: part?.partNumber,
          quantity: sp.quantity,
          priceEach: sp.priceEach,
          lineTotal: sp.lineTotal,
        ),
      );
    }

    return InvoiceDetails(
      invoice: invoice,
      service: service,
      customer: customer,
      items: items,
      labourCharge: service.labourCharge,
      totalAmount: invoice.totalAmount,
    );
  }

  List<ServicePartInput> _normalizeParts(
    List<ServicePartInput> partsUsed,
  ) {
    final quantities = <String, int>{};

    for (final input in partsUsed) {
      final partId = input.partId.trim();

      if (partId.isEmpty) {
        throw ValidationException(
          'Part ID cannot be empty.',
        );
      }

      if (input.quantity <= 0) {
        throw ValidationException(
          'Part quantity must be greater than zero.',
        );
      }

      quantities[partId] =
          (quantities[partId] ?? 0) +
              input.quantity;
    }

    return quantities.entries
        .map(
          (entry) => ServicePartInput(
            partId: entry.key,
            quantity: entry.value,
          ),
        )
        .toList();
  }
}

class _ResolvedPart {
  final ServicePartInput input;
  final Part part;

  const _ResolvedPart({
    required this.input,
    required this.part,
  });
}