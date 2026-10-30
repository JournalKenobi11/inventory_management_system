import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../billing/billing.dart';
import '../models/customer.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final Customer customer;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync =
        ref.watch(customerBillingHistoryProvider(customer.id));
    final reminderAsync =
        ref.watch(customerReminderProvider(customer.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerBillingHistoryProvider(customer.id));
          ref.invalidate(customerReminderProvider(customer.id));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Customer Information Card
            _buildCustomerInfoCard(context, theme),
            const SizedBox(height: 16),

            // 2. Service Reminder Card (6 Months from previous service)
            _buildServiceReminderCard(context, theme, reminderAsync),
            const SizedBox(height: 20),

            // 3. Section Header: Service / Billing History
            _buildHistoryHeader(theme, historyAsync),
            const SizedBox(height: 12),

            // 3. Service History Content
            historyAsync.when(
              loading: () => Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                child: const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Loading service history...'),
                      ],
                    ),
                  ),
                ),
              ),
              error: (err, _) => Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load service history',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        err.toString(),
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () {
                          ref.invalidate(
                            customerBillingHistoryProvider(customer.id),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (history) {
                if (history.isEmpty) {
                  return Card(
                    elevation: 0,
                    color:
                        theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant
                                .withAlpha(160),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No service history yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Previous services and invoices for this customer will appear here.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: history.map((details) {
                    return _buildHistoryCard(context, details, theme);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (customer.vehicleName != null &&
                          customer.vehicleName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_car_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              customer.vehicleName!.trim(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.phone_android_rounded,
              label: 'Mobile',
              value: customer.mobile,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.directions_car_outlined,
              label: 'Vehicle',
              value: customer.vehicleName ?? 'Not provided',
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Customer Since',
              value: _formatCustomerDate(customer.createdDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceReminderCard(
    BuildContext context,
    ThemeData theme,
    AsyncValue<CustomerServiceReminder?> reminderAsync,
  ) {
    return reminderAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reminder) {
        if (reminder == null) {
          return Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No previous service recorded. The 6-month reminder activates after the first billed service.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final isDue = reminder.isDue;
        final dueDateFormatted =
            '${reminder.reminderDueDate.day.toString().padLeft(2, '0')}/${reminder.reminderDueDate.month.toString().padLeft(2, '0')}/${reminder.reminderDueDate.year}';
        final lastDateFormatted =
            '${reminder.lastServiceDate.day.toString().padLeft(2, '0')}/${reminder.lastServiceDate.month.toString().padLeft(2, '0')}/${reminder.lastServiceDate.year}';

        return Card(
          elevation: isDue ? 2 : 0,
          color: isDue
              ? theme.colorScheme.errorContainer.withAlpha(90)
              : theme.colorScheme.primaryContainer.withAlpha(70),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDue
                  ? theme.colorScheme.error.withAlpha(160)
                  : theme.colorScheme.primary.withAlpha(100),
              width: isDue ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDue
                          ? Icons.warning_amber_rounded
                          : Icons.access_time_rounded,
                      color: isDue
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDue
                                ? 'SERVICE DUE (6-Month Reminder)'
                                : 'Next Service Reminder',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDue
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            isDue
                                ? 'Overdue by ${reminder.daysOverdue} days'
                                : 'Due in ${reminder.daysRemaining} days (on $dueDateFormatted)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDue
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDue
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isDue ? 'DUE NOW' : 'ON TRACK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Previous Service: $lastDateFormatted',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Reminder Due: $dueDateFormatted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (isDue) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final vehicle = customer.vehicleName ?? 'your vehicle';
                            final text = Uri.encodeComponent(
                              'Hello ${customer.name}, your $vehicle is due for its 6-month periodic service at our garage. Please visit us to keep your vehicle in top running condition!',
                            );
                            final cleanPhone =
                                customer.mobile.replaceAll(RegExp(r'\D'), '');
                            final uri = Uri.parse(
                              'https://wa.me/$cleanPhone?text=$text',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.chat_bubble, size: 16),
                          label: const Text('WhatsApp Reminder'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () async {
                          final uri = Uri.parse('tel:${customer.mobile}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.call, size: 18),
                        tooltip: 'Call Customer',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryHeader(
    ThemeData theme,
    AsyncValue<List<InvoiceDetails>> historyAsync,
  ) {
    final count = historyAsync.asData?.value.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 22,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Service History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count ${count == 1 ? "service" : "services"}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    InvoiceDetails details,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceOverviewScreen(
                invoiceDetails: details,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Invoice Number & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Invoice #${details.invoice.invoiceNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        details.displayDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Service Description (if any)
              if (details.service.problemDesc != null &&
                  details.service.problemDesc!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.build_circle_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        details.service.problemDesc!.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const Divider(height: 20),

              // Parts Summary
              if (details.items.isNotEmpty) ...[
                const Text(
                  'Parts:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                ...details.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.partName} × ${item.quantity}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '₹${item.lineTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 6),
              ],

              // Labour Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Labour',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    '₹${details.labourCharge.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const Divider(height: 20),

              // Total Row & Tap Callout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total: ',
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Bill',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatCustomerDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      return '$day $month ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}