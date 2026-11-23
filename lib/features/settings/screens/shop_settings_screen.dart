import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exceptions.dart';
import '../models/shop_settings.dart';
import '../providers/shop_settings_provider.dart';

class ShopSettingsScreen extends ConsumerStatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  ConsumerState<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends ConsumerState<ShopSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _businessNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _servicesController;
  late final TextEditingController _upiIdController;

  bool _initialized = false;
  bool _saving = false;

  static final RegExp _upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _ownerNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _servicesController = TextEditingController();
    _upiIdController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _servicesController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _populateControllers(ShopSettings settings) {
    if (!_initialized) {
      _businessNameController.text = settings.businessName;
      _ownerNameController.text = settings.ownerName;
      _phoneController.text = settings.phone;
      _addressController.text = settings.address;
      _servicesController.text = settings.services;
      _upiIdController.text = settings.upiId;
      _initialized = true;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final updated = ShopSettings(
      businessName: _businessNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      services: _servicesController.text.trim(),
      upiId: _upiIdController.text.trim(),
    );

    try {
      await ref.read(shopSettingsProvider.notifier).updateSettings(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Shop settings updated successfully!'),
              ],
            ),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is AppException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    final settingsAsync = ref.watch(shopSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Settings'),
        elevation: 0,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load settings: $err'),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => ref.read(shopSettingsProvider.notifier).reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (settings) {
          _populateControllers(settings);

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header info card
                        Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withAlpha(60),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Establishment Branding',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Update business details, invoice headings, and UPI QR code.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey.shade700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Business Name
                        TextFormField(
                          controller: _businessNameController,
                          decoration: InputDecoration(
                            labelText: 'Business Name *',
                            prefixIcon: const Icon(Icons.business_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            helperText: 'Shown on drawer, invoices, and share messages',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Business name is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // Owner Name
                        TextFormField(
                          controller: _ownerNameController,
                          decoration: InputDecoration(
                            labelText: 'Owner / Proprietor Name',
                            prefixIcon: const Icon(Icons.person_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            helperText: 'Optional. Used in greetings and drawer subtitle',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),

                        const SizedBox(height: 18),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Contact Phone Number *',
                            prefixIcon: const Icon(Icons.phone_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            helperText: '10-digit mobile number for invoices and support',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            final clean = val.trim().replaceAll(RegExp(r'[\s\-]'), '');
                            final digits = clean.startsWith('+91')
                                ? clean.substring(3)
                                : (clean.startsWith('0') ? clean.substring(1) : clean);
                            if (!RegExp(r'^[0-9]{10}$').hasMatch(digits)) {
                              return 'Enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // Services / Tagline
                        TextFormField(
                          controller: _servicesController,
                          decoration: InputDecoration(
                            labelText: 'Services / Tagline *',
                            prefixIcon: const Icon(Icons.miscellaneous_services_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            helperText: 'E.g. E-BIKE sales and services',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Services description is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Shop Address *',
                            prefixIcon: const Icon(Icons.location_on_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            helperText: 'Complete physical address displayed on generated bills',
                            alignLabelWithHint: true,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Address is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // Shop UPI ID
                        TextFormField(
                          controller: _upiIdController,
                          decoration: InputDecoration(
                            labelText: 'Shop UPI ID (VPA)',
                            prefixIcon: const Icon(Icons.qr_code_2_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            helperText: 'E.g. mestrymotors@okhdfcbank (enables bill QR payment)',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return null; // UPI ID is optional
                            }
                            if (!_upiRegex.hasMatch(val.trim())) {
                              return 'Invalid UPI ID format (e.g. shopname@bank)';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        FilledButton.icon(
                          onPressed: _saving ? null : _saveChanges,
                          icon: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _saving ? 'Saving...' : 'Save Changes',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
