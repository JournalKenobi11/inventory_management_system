import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/part.dart';
import '../providers/part_provider.dart';

class PartFormScreen extends ConsumerStatefulWidget {
  final Part? part;

  const PartFormScreen({
    super.key,
    this.part,
  });

  bool get isEditing => part != null;

  @override
  ConsumerState<PartFormScreen> createState() => _PartFormScreenState();
}

class _PartFormScreenState extends ConsumerState<PartFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _partNumberController;
  late final TextEditingController _partNameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _lowStockThresholdController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final part = widget.part;

    _partNumberController = TextEditingController(
      text: part?.partNumber ?? '',
    );
    _partNameController = TextEditingController(
      text: part?.partName ?? '',
    );
    _categoryController = TextEditingController(
      text: part?.category ?? '',
    );
    _purchasePriceController = TextEditingController(
      text: part?.purchasePrice.toString() ?? '',
    );
    _sellingPriceController = TextEditingController(
      text: part?.sellingPrice.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: part?.currentStock.toString() ?? '0',
    );
    _lowStockThresholdController = TextEditingController(
      text: part?.lowStockThreshold.toString() ?? '5',
    );
  }

  @override
  void dispose() {
    _partNumberController.dispose();
    _partNameController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _lowStockThresholdController.dispose();
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
      final service = ref.read(partServiceProvider);

      final purchasePrice =
          double.parse(_purchasePriceController.text.trim());

      final sellingPrice =
          double.parse(_sellingPriceController.text.trim());

      final currentStock =
          int.parse(_stockController.text.trim());

      final lowStockThreshold =
          int.parse(_lowStockThresholdController.text.trim());

      if (widget.isEditing) {
        final updatedPart = widget.part!.copyWith(
          partNumber: _partNumberController.text.trim(),
          partName: _partNameController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          currentStock: currentStock,
          lowStockThreshold: lowStockThreshold,
        );

        await service.updatePart(updatedPart);
      } else {
        await service.createPart(
          partNumber: _partNumberController.text.trim(),
          partName: _partNameController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          currentStock: currentStock,
          lowStockThreshold: lowStockThreshold,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
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
          widget.isEditing ? 'Edit Part' : 'Add Part',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _partNumberController,
              decoration: const InputDecoration(
                labelText: 'Part Number',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter part number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _partNameController,
              decoration: const InputDecoration(
                labelText: 'Part Name',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter part name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _purchasePriceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              validator: _validateNumber,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sellingPriceController,
              decoration: const InputDecoration(
                labelText: 'Selling Price',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              validator: _validateNumber,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Current Stock',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: _validateInteger,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lowStockThresholdController,
              decoration: const InputDecoration(
                labelText: 'Low Stock Threshold',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: _validateInteger,
              onFieldSubmitted: (_) {
                _save();
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(),
                      )
                    : Text(
                        widget.isEditing
                            ? 'Update Part'
                            : 'Save Part',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a value';
    }

    final number = double.tryParse(value.trim());

    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < 0) {
      return 'Value cannot be negative';
    }

    return null;
  }

  String? _validateInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a value';
    }

    final number = int.tryParse(value.trim());

    if (number == null) {
      return 'Enter a valid whole number';
    }

    if (number < 0) {
      return 'Value cannot be negative';
    }

    return null;
  }
}