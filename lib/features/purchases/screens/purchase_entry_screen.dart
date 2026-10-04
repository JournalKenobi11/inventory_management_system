import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../parts/models/part.dart';
import '../../parts/providers/part_provider.dart';
import '../providers/purchase_provider.dart';

class PurchaseEntryScreen extends ConsumerStatefulWidget {
  const PurchaseEntryScreen({
    super.key,
  });

  @override
  ConsumerState<PurchaseEntryScreen> createState() =>
      _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState
    extends ConsumerState<PurchaseEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _quantityController = TextEditingController();
  final _purchasePriceController = TextEditingController();

  Part? _selectedPart;
  bool _saving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final part = _selectedPart;

    if (part == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a part.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final quantity = int.parse(
        _quantityController.text.trim(),
      );

      final purchasePrice = double.parse(
        _purchasePriceController.text.trim(),
      );

      await ref.read(purchasesProvider.notifier).recordPurchase(
            partId: part.id,
            quantity: quantity,
            price: purchasePrice,
          );

      final purchaseState = ref.read(purchasesProvider);

      if (purchaseState.hasError) {
        throw purchaseState.error!;
      }

      ref.invalidate(partsProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase recorded successfully.'),
        ),
      );

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
    final partsAsync = ref.watch(partsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Stock'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            partsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                error.toString(),
              ),
              data: (parts) {
                if (parts.isEmpty) {
                  return const Text(
                    'No parts available. Add a part first.',
                  );
                }

                return DropdownButtonFormField<Part>(
                  initialValue: _selectedPart,
                  decoration: const InputDecoration(
                    labelText: 'Part',
                    border: OutlineInputBorder(),
                  ),
                  items: parts.map((part) {
                    return DropdownMenuItem<Part>(
                      value: part,
                      child: Text(
                        '${part.partNumber} - ${part.partName}',
                      ),
                    );
                  }).toList(),
                  onChanged: _saving
                      ? null
                      : (part) {
                          setState(() {
                            _selectedPart = part;

                            if (part != null) {
                              _purchasePriceController.text =
                                  part.purchasePrice.toString();
                            }
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Select a part';
                    }

                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: _validateQuantity,
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
              textInputAction: TextInputAction.done,
              validator: _validatePrice,
              onFieldSubmitted: (_) {
                if (!_saving) {
                  _save();
                }
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
                    : const Text('Record Purchase'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter quantity';
    }

    final quantity = int.tryParse(value.trim());

    if (quantity == null) {
      return 'Enter a valid whole number';
    }

    if (quantity <= 0) {
      return 'Quantity must be greater than zero';
    }

    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter purchase price';
    }

    final price = double.tryParse(value.trim());

    if (price == null) {
      return 'Enter a valid price';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    return null;
  }
}