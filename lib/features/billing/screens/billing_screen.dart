import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../customers/customers.dart';
import '../../export/export.dart';
import '../../parts/parts.dart';
import '../models/invoice.dart';
import '../models/service_part.dart';
import '../providers/billing_provider.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices & Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(invoicesListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Invoice # (e.g. 1001)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          Expanded(
            child: invoicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading invoices: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(invoicesListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (invoices) {
                final filtered = _searchQuery.isEmpty
                    ? invoices
                    : invoices.where((inv) {
                        return inv.invoiceNumber.toString().contains(_searchQuery);
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No invoices recorded yet.\nTap "New Bill" below to generate an invoice.'
                              : 'No invoices matching "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Show newest invoices first
                final sorted = [...filtered]..sort((a, b) => b.createdDate.compareTo(a.createdDate));

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final inv = sorted[index];
                    final dateStr = inv.createdDate.length >= 10
                        ? inv.createdDate.substring(0, 10)
                        : inv.createdDate;

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.receipt,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          'Invoice #${inv.invoiceNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Date: $dateStr'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rs. ${inv.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        onTap: () => _showInvoiceDetails(context, inv),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<Invoice?>(
            context,
            MaterialPageRoute(builder: (_) => const NewServiceScreen()),
          );
          if (created != null && mounted) {
            ref.invalidate(invoicesListProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Bill'),
      ),
    );
  }

  void _showInvoiceDetails(BuildContext context, Invoice invoice) async {
    final billingService = ref.read(billingServiceProvider);
    final service = await billingService.getServiceById(invoice.serviceId);
    final serviceParts = await billingService.getServiceParts(invoice.serviceId);
    Customer? customer;
    if (service != null) {
      customer = await ref.read(customerServiceProvider).getCustomer(service.customerId);
    }

    if (!context.mounted) return;

    final dateStr = invoice.createdDate.length >= 10
        ? invoice.createdDate.substring(0, 10)
        : invoice.createdDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoice #${invoice.invoiceNumber}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(
                          'Rs. ${invoice.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.green.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Date: $dateStr', style: TextStyle(color: Colors.grey.shade600)),
                  const Divider(height: 24),
                  if (customer != null) ...[
                    const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Name: ${customer.name}'),
                    Text('Mobile: ${customer.mobile}'),
                    if (customer.vehicleName != null && customer.vehicleName!.isNotEmpty)
                      Text('Vehicle: ${customer.vehicleName}'),
                    const Divider(height: 24),
                  ],
                  if (service != null && service.problemDesc != null && service.problemDesc!.isNotEmpty) ...[
                    const Text('Service Work / Problem', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(service.problemDesc!),
                    const Divider(height: 24),
                  ],
                  const Text('Parts & Labour Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (serviceParts.isEmpty)
                    const Text('No parts recorded.')
                  else
                    ...serviceParts.map((sp) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Part Qty: ${sp.quantity} @ Rs.${sp.priceEach.toStringAsFixed(2)}'),
                            Text(
                              'Rs. ${sp.lineTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (service != null && service.labourCharge > 0) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Labour Charge:'),
                          Text(
                            'Rs. ${service.labourCharge.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rs. ${invoice.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share Receipt / Invoice'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (customer != null && service != null) {
                        ref.read(shareServiceProvider).shareInvoiceText(
                              invoice: invoice,
                              customer: customer,
                              serviceParts: serviceParts,
                              labourCharge: service.labourCharge,
                            );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Customer or service details not available.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class NewServiceScreen extends ConsumerStatefulWidget {
  const NewServiceScreen({super.key});

  @override
  ConsumerState<NewServiceScreen> createState() => _NewServiceScreenState();
}

class _NewServiceScreenState extends ConsumerState<NewServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _problemDescController = TextEditingController();
  final _labourChargeController = TextEditingController(text: '0');

  Customer? _selectedCustomer;
  final List<_PartLineItemEntry> _selectedParts = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _problemDescController.dispose();
    _labourChargeController.dispose();
    super.dispose();
  }

  double get _partsTotal =>
      _selectedParts.fold(0.0, (acc, item) => acc + (item.part.sellingPrice * item.quantity));

  double get _labourCharge => double.tryParse(_labourChargeController.text.trim()) ?? 0.0;

  double get _grandTotal => _partsTotal + _labourCharge;

  void _addPart(Part part, int quantity) {
    setState(() {
      final existingIndex = _selectedParts.indexWhere((item) => item.part.id == part.id);
      if (existingIndex >= 0) {
        final newQty = _selectedParts[existingIndex].quantity + quantity;
        if (newQty <= part.currentStock) {
          _selectedParts[existingIndex] = _PartLineItemEntry(part: part, quantity: newQty);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot add more than available stock (${part.currentStock})'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        _selectedParts.add(_PartLineItemEntry(part: part, quantity: quantity));
      }
    });
  }

  void _removePart(int index) {
    setState(() {
      _selectedParts.removeAt(index);
    });
  }

  Future<void> _submitBill() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final partsInput = _selectedParts
          .map((item) => ServicePartInput(partId: item.part.id, quantity: item.quantity))
          .toList();

      final invoice = await ref.read(billingServiceProvider).billService(
            customerId: _selectedCustomer!.id,
            problemDesc: _problemDescController.text.trim(),
            labourCharge: _labourCharge,
            partsUsed: partsInput,
          );

      // Refresh parts list since stock decreased
      ref.invalidate(partsProvider);

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 54),
          title: const Text('Invoice Generated!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Invoice #${invoice.invoiceNumber}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: Rs. ${invoice.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Customer: ${_selectedCustomer!.name}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(invoice);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is AppException ? e.message : 'Billing failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final partsAsync = ref.watch(partsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Service & Invoice'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer selection card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    customersAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading customers: $err', style: const TextStyle(color: Colors.red)),
                      data: (customers) {
                        if (customers.isEmpty) {
                          return Row(
                            children: [
                              const Expanded(child: Text('No customers found. Add a customer first.')),
                              TextButton.icon(
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add'),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
                                ),
                              ),
                            ],
                          );
                        }
                        return DropdownButtonFormField<Customer>(
                          value: _selectedCustomer,
                          decoration: const InputDecoration(
                            labelText: 'Select Customer *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: customers.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text('${c.name} (${c.mobile})'),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCustomer = val),
                        );
                      },
                    ),
                    if (_selectedCustomer?.vehicleName != null && _selectedCustomer!.vehicleName!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Vehicle: ${_selectedCustomer!.vehicleName}',
                        style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Service problem description
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2. Problem / Service Work', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _problemDescController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Problem Description (optional)',
                        hintText: 'e.g. Engine tune-up, front brake pads replacement',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.build),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Parts Consumed Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('3. Parts Consumed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add Part'),
                          onPressed: () => _openPartPicker(context, partsAsync),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedParts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'No parts added yet.\n(Tap "Add Part" to consume from inventory)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedParts.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (ctx, i) {
                          final item = _selectedParts[i];
                          final lineTotal = item.part.sellingPrice * item.quantity;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.part.partName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${item.part.partNumber} | Qty: ${item.quantity} x Rs.${item.part.sellingPrice.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Rs. ${lineTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removePart(i),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Labour charge card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('4. Labour / Service Charge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _labourChargeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Labour Charge (Rs.)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.handyman),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Summary Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Parts Subtotal:'),
                        Text('Rs. ${_partsTotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Labour Charge:'),
                        Text('Rs. ${_labourCharge.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(
                          'Rs. ${_grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitBill,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm & Generate Invoice', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openPartPicker(BuildContext context, AsyncValue<List<Part>> partsAsync) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return partsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (parts) {
                if (parts.isEmpty) {
                  return const Center(child: Text('No parts in inventory.'));
                }
                return ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: parts.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (c, idx) {
                    final part = parts[idx];
                    final isOutOfStock = part.currentStock <= 0;

                    return ListTile(
                      title: Text(part.partName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '#${part.partNumber} | In Stock: ${part.currentStock} | Price: Rs.${part.sellingPrice.toStringAsFixed(2)}',
                      ),
                      trailing: isOutOfStock
                          ? const Chip(label: Text('Out of Stock'), backgroundColor: Colors.redAccent)
                          : ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showQuantityDialog(context, part);
                              },
                              child: const Text('Select'),
                            ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showQuantityDialog(BuildContext context, Part part) {
    int qty = 1;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text('Quantity for ${part.partName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Available Stock: ${part.currentStock}'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: qty > 1 ? () => setDialogState(() => qty--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$qty',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: qty < part.currentStock ? () => setDialogState(() => qty++) : null,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    _addPart(part, qty);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PartLineItemEntry {
  final Part part;
  final int quantity;

  const _PartLineItemEntry({
    required this.part,
    required this.quantity,
  });
}
