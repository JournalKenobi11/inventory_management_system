import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customers/customers.dart';
import '../providers/billing_provider.dart';

class CreateJobCardSheet extends ConsumerStatefulWidget {
  final Customer? preselectedCustomer;

  const CreateJobCardSheet({
    super.key,
    this.preselectedCustomer,
  });

  static Future<void> show(
    BuildContext context, {
    Customer? preselectedCustomer,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateJobCardSheet(
        preselectedCustomer: preselectedCustomer,
      ),
    );
  }

  @override
  ConsumerState<CreateJobCardSheet> createState() => _CreateJobCardSheetState();
}

class _CreateJobCardSheetState extends ConsumerState<CreateJobCardSheet> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer;
  final _problemController = TextEditingController();
  final _advanceController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMode = 'Cash';
  bool _isSaving = false;

  final List<String> _paymentModes = const [
    'Cash',
    'UPI',
    'Card',
    'Bank Transfer',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
  }

  @override
  void dispose() {
    _problemController.dispose();
    _advanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomer(List<Customer> allCustomers) async {
    final selected = await showDialog<Customer>(
      context: context,
      builder: (_) => _CustomerSearchDialog(customers: allCustomers),
    );
    if (selected != null) {
      setState(() => _selectedCustomer = selected);
    }
  }

  Future<void> _saveJobCard() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double advanceAmount =
        double.tryParse(_advanceController.text.trim()) ?? 0.0;

    setState(() => _isSaving = true);

    try {
      final billingService = ref.read(billingServiceProvider);
      await billingService.createJobCard(
        customerId: _selectedCustomer!.id,
        problemDesc: _problemController.text.trim(),
        advanceAmount: advanceAmount,
        advancePaymentMode: advanceAmount > 0 ? _paymentMode : null,
        advanceNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      ref.invalidate(pendingJobCardsProvider);
      ref.invalidate(
        customerPendingJobCardsProvider(_selectedCustomer!.id),
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            advanceAmount > 0
                ? 'Job card booked with ₹${advanceAmount.toStringAsFixed(0)} advance recorded.'
                : 'Job card booked successfully.',
          ),
          backgroundColor: Colors.green.shade800,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create job card: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersAsync = ref.watch(customersProvider);
    final allCustomers = customersAsync.asData?.value ?? [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.engineering_rounded,
                        color: Colors.amber.shade900,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Job Card & Advance',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Track pending work & upfront customer payments',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Customer Selection
                if (_selectedCustomer == null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _selectCustomer(allCustomers),
                    icon: const Icon(Icons.person_search_rounded),
                    label: const Text('Select Customer'),
                  )
                else
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          _selectedCustomer!.name.isNotEmpty
                              ? _selectedCustomer!.name[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        _selectedCustomer!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${_selectedCustomer!.mobile}'
                        '${_selectedCustomer!.vehicleName == null ? '' : ' • ${_selectedCustomer!.vehicleName}'}',
                      ),
                      trailing: widget.preselectedCustomer == null
                          ? TextButton(
                              onPressed: () => _selectCustomer(allCustomers),
                              child: const Text('Change'),
                            )
                          : null,
                    ),
                  ),

                const SizedBox(height: 16),

                // Problem / Work description
                TextFormField(
                  controller: _problemController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Work / Problem Description *',
                    hintText: 'e.g. Battery replacement - Amaron 65Ah',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe the service / work required.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Advance Amount & Mode
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _advanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Advance Collected',
                          hintText: '0',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final n = double.tryParse(value.trim());
                            if (n == null || n < 0) {
                              return 'Enter valid amount';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentMode,
                        decoration: InputDecoration(
                          labelText: 'Mode',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _paymentModes
                            .map(
                              (mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(mode),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _paymentMode = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Notes / Estimated schedule
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes / Target Date (Optional)',
                    hintText: 'e.g. Part ordered, expected by tomorrow afternoon',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Save button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveJobCard,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Create Job Card',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerSearchDialog extends StatefulWidget {
  final List<Customer> customers;

  const _CustomerSearchDialog({required this.customers});

  @override
  State<_CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends State<_CustomerSearchDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.customers.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final nameMatches = c.name.toLowerCase().contains(q);
      final phoneMatches = c.mobile.contains(q);
      final vehicleMatches = c.vehicleName?.toLowerCase().contains(q) ?? false;
      return nameMatches || phoneMatches || vehicleMatches;
    }).toList();

    return AlertDialog(
      title: const Text('Select Customer'),
      content: SizedBox(
        width: 320,
        height: 380,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name, phone...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (val) => setState(() => _query = val.trim()),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No customers found.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final customer = filtered[index];
                        return ListTile(
                          title: Text(customer.name),
                          subtitle: Text(
                            '${customer.mobile}'
                            '${customer.vehicleName == null ? '' : ' • ${customer.vehicleName}'}',
                          ),
                          onTap: () => Navigator.pop(context, customer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
