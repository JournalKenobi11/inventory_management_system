// lib/features/customers/screens/customer_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({
    super.key,
    this.customer,
  });

  @override
  ConsumerState<CustomerFormScreen> createState() =>
      _CustomerFormScreenState();
}

class _CustomerFormScreenState
    extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _vehicleController;

  bool _saving = false;

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.customer?.name ?? '',
    );

    _mobileController = TextEditingController(
      text: widget.customer?.mobile ?? '',
    );

    _vehicleController = TextEditingController(
      text: widget.customer?.vehicleName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final service = ref.read(customerServiceProvider);

      if (isEditing) {
        await service.updateCustomer(
          widget.customer!.copyWith(
            name: _nameController.text,
            mobile: _mobileController.text,
            vehicleName: _vehicleController.text,
          ),
        );
      } else {
        await service.createCustomer(
          name: _nameController.text,
          mobile: _mobileController.text,
          vehicleName: _vehicleController.text,
        );
      }

      ref.invalidate(customersProvider);

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Customer' : 'Add Customer',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile',
                ),
                keyboardType:
                    TextInputType.phone,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Mobile is required';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _vehicleController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Name',
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
