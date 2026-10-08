import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/phone_number_utils.dart';
import '../../export/export.dart';
import '../models/invoice_details.dart';
import '../providers/billing_provider.dart';

class InvoiceOverviewScreen extends ConsumerStatefulWidget {
  final InvoiceDetails? invoiceDetails;
  final String? invoiceId;

  const InvoiceOverviewScreen({
    super.key,
    this.invoiceDetails,
    this.invoiceId,
  }) : assert(invoiceDetails != null || invoiceId != null,
            'Either invoiceDetails or invoiceId must be provided.');

  @override
  ConsumerState<InvoiceOverviewScreen> createState() =>
      _InvoiceOverviewScreenState();
}

class _InvoiceOverviewScreenState extends ConsumerState<InvoiceOverviewScreen> {
  bool _isSharingWhatsAppPdf = false;
  bool _isDownloadingPdf = false;

  Future<void> _sharePdfOnWhatsApp(InvoiceDetails details) async {
    setState(() => _isSharingWhatsAppPdf = true);

    try {
      final pdfService = ref.read(pdfServiceProvider);
      final shareService = ref.read(shareServiceProvider);

      final pdfData = InvoicePdfData.fromDetails(details);
      final pdfFile = await pdfService.saveInvoicePdfToFile(pdfData);

      if (!mounted) return;

      await shareService.shareInvoicePdf(
        pdfFile,
        invoiceNumber: details.invoice.invoiceNumber,
        customerName: details.customer.name,
        customerMobile: details.customer.mobile,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingWhatsAppPdf = false);
      }
    }
  }

  Future<void> _downloadPdf(InvoiceDetails details) async {
    setState(() => _isDownloadingPdf = true);

    try {
      final pdfService = ref.read(pdfServiceProvider);
      final pdfData = InvoicePdfData.fromDetails(details);
      final file = await pdfService.downloadInvoicePdf(pdfData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bill PDF downloaded: ${file.path}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: const Color(0xFF1B5E20),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () => _sharePdfOnWhatsApp(details),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download PDF: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.invoiceDetails != null) {
      return _buildOverviewContent(widget.invoiceDetails!);
    }

    final detailsAsync =
        ref.watch(invoiceDetailsProvider(widget.invoiceId!));

    return detailsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Invoice Overview')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Invoice Overview')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load invoice: $err'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (details) => _buildOverviewContent(details),
    );
  }

  Widget _buildOverviewContent(InvoiceDetails details) {
    final theme = Theme.of(context);
    final isMobileValid =
        PhoneNumberUtils.isValid(details.customer.mobile);

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${details.invoice.invoiceNumber}'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Done',
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Success & Status Banner
                _buildHeaderCard(details, theme),
                const SizedBox(height: 12),

                // 2. Customer & Vehicle Information
                _buildCustomerCard(details, theme, isMobileValid),
                const SizedBox(height: 12),

                // 3. Service / Problem Description
                if (details.service.problemDesc != null &&
                    details.service.problemDesc!.trim().isNotEmpty) ...[
                  _buildServiceCard(details, theme),
                  const SizedBox(height: 12),
                ],

                // 4. Parts Used List / Table
                _buildPartsCard(details, theme),
                const SizedBox(height: 12),

                // 5. Cost Breakdown & Totals
                _buildSummaryCard(details, theme),
                const SizedBox(height: 20),

                // 6. Action Buttons
                _buildActionButtons(details),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(InvoiceDetails details, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withAlpha(120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withAlpha(60),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice #${details.invoice.invoiceNumber}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generated on ${details.formattedDate}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(
    InvoiceDetails details,
    ThemeData theme,
    bool isMobileValid,
  ) {
    final customer = details.customer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_pin,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Customer Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildDetailRow('Customer Name', customer.name),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mobile Number',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      customer.mobile,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isMobileValid) ...[
                      const SizedBox(width: 6),
                      const Tooltip(
                        message: 'Phone number format may not be WhatsApp compatible',
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (customer.vehicleName != null &&
                customer.vehicleName!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Vehicle', customer.vehicleName!.trim()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(InvoiceDetails details, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build_circle_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Service / Job Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              details.service.problemDesc!.trim(),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartsCard(InvoiceDetails details, ThemeData theme) {
    final items = details.items;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Parts Used (${items.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Subtotal: ₹${details.partsSubtotal.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No parts were charged for this service.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.partName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (item.partNumber != null &&
                                item.partNumber!.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Part No: ${item.partNumber!.trim()}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              '₹${item.priceEach.toStringAsFixed(2)} × ${item.quantity}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${item.lineTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(InvoiceDetails details, ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCostRow(
              'Parts Total',
              details.partsSubtotal,
              theme,
            ),
            const SizedBox(height: 8),
            _buildCostRow(
              'Labour / Service Charge',
              details.labourCharge,
              theme,
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grand Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${details.totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(InvoiceDetails details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Share PDF on WhatsApp (Primary action with WhatsApp brand green styling)
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isSharingWhatsAppPdf
              ? null
              : () => _sharePdfOnWhatsApp(details),
          icon: _isSharingWhatsAppPdf
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.chat_bubble_rounded),
          label: Text(
            _isSharingWhatsAppPdf
                ? 'Preparing PDF...'
                : 'Share PDF on WhatsApp',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 2. Download Bill (PDF) button
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isDownloadingPdf ? null : () => _downloadPdf(details),
          icon: _isDownloadingPdf
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_download_rounded),
          label: Text(
            _isDownloadingPdf
                ? 'Downloading Bill...'
                : 'Download Bill (PDF)',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 3. Done button
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Done',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, double amount, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
