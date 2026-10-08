// lib/features/customers/screens/customer_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';
import '../providers/customer_provider.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

class _CustomerListScreenState
    extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    final notifier = ref.read(customersProvider.notifier);

    if (value.trim().isEmpty) {
      notifier.loadCustomers();
    } else {
      notifier.searchCustomers(value.trim());
    }
  }

  Future<void> _deleteCustomer(
    BuildContext context,
    String id,
  ) async {
    try {
      await ref
          .read(customersProvider.notifier)
          .deleteCustomer(id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: const InputDecoration(
                labelText: 'Search customers',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: customers.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No customers found'),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final customer = items[index];

                    return Card(
                      child: ListTile(
                        title: Text(customer.name),
                        subtitle: Text(
                          [
                            customer.mobile,
                            if (customer.vehicleName != null)
                              customer.vehicleName!,
                          ].join('\n'),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerDetailScreen(
                                customer: customer,
                              ),
                            ),
                          );
                        },
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomerFormScreen(
                                    customer: customer,
                                  ),
                                ),
                              );

                              ref
                                  .read(
                                    customersProvider
                                        .notifier,
                                  )
                                  .loadCustomers();
                            }

                            if (value == 'delete') {
                              await _deleteCustomer(
                                context,
                                customer.id,
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text(error.toString()),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const CustomerFormScreen(),
            ),
          );

          ref
              .read(customersProvider.notifier)
              .loadCustomers();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
