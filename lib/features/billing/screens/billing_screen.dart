import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_drawer_button.dart';

import '../../customers/models/customer.dart';
import '../../customers/providers/customer_provider.dart';
import '../../parts/models/part.dart';
import '../../parts/providers/part_provider.dart';
import '../models/service_part.dart';
import '../providers/billing_provider.dart';
import 'invoice_overview_screen.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  Customer? _selectedCustomer;

  final _problemController = TextEditingController();
  final _labourController = TextEditingController();

  final List<_SelectedPart> _selectedParts = [];

  @override
  void dispose() {
    _problemController.dispose();
    _labourController.dispose();
    super.dispose();
  }

  double get _labourCharge {
    return double.tryParse(_labourController.text.trim()) ?? 0;
  }

  double get _partsTotal {
    double total = 0;

    for (final item in _selectedParts) {
      total += item.part.sellingPrice * item.quantity;
    }

    return total;
  }

  double get _grandTotal {
    return _partsTotal + _labourCharge;
  }

  Future<void> _createCustomer() async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final vehicleController = TextEditingController();

    final result = await showDialog<Customer>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vehicleController,
                  decoration: const InputDecoration(labelText: 'Vehicle'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final mobile = mobileController.text.trim();

                if (name.isEmpty || mobile.isEmpty) {
                  return;
                }

                final customer = await ref
                    .read(customerServiceProvider)
                    .createCustomer(
                      name: name,
                      mobile: mobile,
                      vehicleName: vehicleController.text.trim().isEmpty
                          ? null
                          : vehicleController.text.trim(),
                    );

                if (!context.mounted) {
                  return;
                }

                Navigator.pop(context, customer);

                ref.invalidate(customersProvider);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    mobileController.dispose();
    vehicleController.dispose();

    if (result != null) {
      setState(() {
        _selectedCustomer = result;
      });
    }
  }

  Future<void> _selectCustomer() async {
    final customers = await ref.read(customerServiceProvider).getCustomers();

    if (!mounted) {
      return;
    }

    final selected = await showDialog<Customer>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Customer'),
          content: SizedBox(
            width: 500,
            height: 450,
            child: customers.isEmpty
                ? const Center(child: Text('No customers found.'))
                : ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];

                      return ListTile(
                        title: Text(customer.name),
                        subtitle: Text(
                          '${customer.mobile}'
                          '${customer.vehicleName == null ? '' : ' • ${customer.vehicleName}'}',
                        ),
                        onTap: () {
                          Navigator.pop(context, customer);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedCustomer = selected;
      });
    }
  }

  Future<void> _addPart() async {
    final parts = await ref.read(partServiceProvider).getAllParts();

    if (!mounted) {
      return;
    }

    final selected = await showDialog<Part>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Part'),
          content: SizedBox(
            width: 550,
            height: 500,
            child: parts.isEmpty
                ? const Center(child: Text('No parts available.'))
                : ListView.builder(
                    itemCount: parts.length,
                    itemBuilder: (context, index) {
                      final part = parts[index];

                      return ListTile(
                        title: Text(part.partName),
                        subtitle: Text(
                          '${part.partNumber} • '
                          '₹${part.sellingPrice.toStringAsFixed(2)}',
                        ),
                        trailing: Text('Stock: ${part.currentStock}'),
                        enabled: part.currentStock > 0,
                        onTap: part.currentStock <= 0
                            ? null
                            : () {
                                Navigator.pop(context, part);
                              },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selected == null) {
      return;
    }

    if (_selectedParts.any((item) => item.part.id == selected.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This part is already added.')),
      );
      return;
    }

    setState(() {
      _selectedParts.add(_SelectedPart(part: selected, quantity: 1));
    });
  }

  void _removePart(int index) {
    setState(() {
      _selectedParts.removeAt(index);
    });
  }

  void _changeQuantity(int index, int quantity) {
    final item = _selectedParts[index];

    if (quantity < 1) {
      return;
    }

    if (quantity > item.part.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only ${item.part.currentStock} '
            'units available.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedParts[index] = _SelectedPart(
        part: item.part,
        quantity: quantity,
      );
    });
  }

  Future<void> _generateInvoice() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select or create a customer first.')),
      );
      return;
    }

    if (_selectedParts.isEmpty && _labourCharge <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one part or labour charge.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Generate Invoice?'),
          content: Text(
            'Customer: ${_selectedCustomer!.name}\n'
            'Parts: ₹${_partsTotal.toStringAsFixed(2)}\n'
            'Labour: ₹${_labourCharge.toStringAsFixed(2)}\n'
            'Total: ₹${_grandTotal.toStringAsFixed(2)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final invoice = await ref
          .read(billingControllerProvider.notifier)
          .billService(
            customerId: _selectedCustomer!.id,
            problemDesc: _problemController.text.trim(),
            labourCharge: _labourCharge,
            partsUsed: _selectedParts
                .map(
                  (item) => ServicePartInput(
                    partId: item.part.id,
                    quantity: item.quantity,
                  ),
                )
                .toList(),
          );

      if (!mounted) {
        return;
      }

      final details = await ref
          .read(billingServiceProvider)
          .getInvoiceDetails(invoice.id);

      if (!mounted) {
        return;
      }

      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceOverviewScreen(invoiceDetails: details),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedCustomer = null;
        _selectedParts.clear();
        _problemController.clear();
        _labourController.clear();
      });

      ref.invalidate(customersProvider);
      ref.invalidate(partsProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invoice failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingControllerProvider);

    final isLoading = billingState.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: appDrawerLeading(context),
        title: const Text('Billing'),
      ),
      body: AbsorbPointer(
        absorbing: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomerCard(),
              const SizedBox(height: 16),
              _buildJobDetailsCard(),
              const SizedBox(height: 16),
              _buildPartsCard(),
              const SizedBox(height: 16),
              _buildTotalCard(),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _generateInvoice,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long),
                label: Text(isLoading ? 'Generating...' : 'Generate Invoice'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_selectedCustomer == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectCustomer,
                      icon: const Icon(Icons.person_search),
                      label: const Text('Select Customer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _createCustomer,
                      icon: const Icon(Icons.person_add),
                      label: const Text('New Customer'),
                    ),
                  ),
                ],
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(_selectedCustomer!.name),
                subtitle: Text(
                  '${_selectedCustomer!.mobile}'
                  '${_selectedCustomer!.vehicleName == null ? '' : ' • ${_selectedCustomer!.vehicleName}'}',
                ),
                trailing: TextButton(
                  onPressed: _selectCustomer,
                  child: const Text('Change'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _problemController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Problem / Service Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labourController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Labour Charge',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Parts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _addPart,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Part'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedParts.isEmpty)
              const Text('No parts added.')
            else
              ..._selectedParts.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.part.partName),
                    subtitle: Text(
                      '₹${item.part.sellingPrice.toStringAsFixed(2)} × ${item.quantity} = '
                      '₹${(item.part.sellingPrice * item.quantity).toStringAsFixed(2)}',
                    ),
                    leading: IconButton(
                      onPressed: () => _removePart(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: item.quantity <= 1
                              ? null
                              : () {
                                  _changeQuantity(index, item.quantity - 1);
                                },
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          item.quantity.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: item.quantity >= item.part.currentStock
                              ? null
                              : () {
                                  _changeQuantity(index, item.quantity + 1);
                                },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _totalRow('Parts', _partsTotal),
            const SizedBox(height: 8),
            _totalRow('Labour', _labourCharge),
            const Divider(height: 24),
            _totalRow('Total', _grandTotal, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 20 : 16,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('₹${amount.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}

class _SelectedPart {
  final Part part;
  final int quantity;

  const _SelectedPart({required this.part, required this.quantity});
}
