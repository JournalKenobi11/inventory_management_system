// lib/features/customers/screens/customer_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_drawer_button.dart';

import '../../billing/billing.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';
import '../providers/customer_provider.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _filterOnlyServiceDue = false;

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

  Future<void> _deleteCustomer(BuildContext context, String id) async {
    try {
      await ref.read(customersProvider.notifier).deleteCustomer(id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final remindersAsync = ref.watch(customerServiceRemindersProvider);

    final dueReminderByCustomerId = <String, CustomerServiceReminder>{};
    if (remindersAsync.asData != null) {
      for (final r in remindersAsync.asData!.value) {
        if (r.isDue) {
          dueReminderByCustomerId[r.customer.id] = r;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: appDrawerLeading(context),
        title: const Text('Customers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: const InputDecoration(
                labelText: 'Search customers',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Customers'),
                  selected: !_filterOnlyServiceDue,
                  onSelected: (_) {
                    setState(() => _filterOnlyServiceDue = false);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.alarm, size: 16),
                  label: Text('Service Due (${dueReminderByCustomerId.length})'),
                  selected: _filterOnlyServiceDue,
                  selectedColor: Theme.of(context).colorScheme.errorContainer,
                  onSelected: (_) {
                    setState(() => _filterOnlyServiceDue = true);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: customers.when(
              data: (allItems) {
                final items = _filterOnlyServiceDue
                    ? allItems
                        .where(
                          (c) => dueReminderByCustomerId.containsKey(c.id),
                        )
                        .toList()
                    : allItems;

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      _filterOnlyServiceDue
                          ? 'No customers due for service.'
                          : 'No customers found.',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final customer = items[index];
                    final dueReminder =
                        dueReminderByCustomerId[customer.id];

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (dueReminder != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.red.shade400,
                                  ),
                                ),
                                child: Text(
                                  'Due (${dueReminder.daysOverdue}d)',
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          [
                            customer.mobile,
                            if (customer.vehicleName != null)
                              customer.vehicleName!,
                          ].join(' • '),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerDetailScreen(customer: customer),
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
                                      CustomerFormScreen(customer: customer),
                                ),
                              );

                              ref
                                  .read(customersProvider.notifier)
                                  .loadCustomers();
                            }

                            if (value == 'delete') {
                              await _deleteCustomer(context, customer.id);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
          );

          ref.read(customersProvider.notifier).loadCustomers();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
