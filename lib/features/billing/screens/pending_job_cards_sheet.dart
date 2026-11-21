import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customers/customers.dart';
import '../models/service.dart';
import '../providers/billing_provider.dart';
import 'billing_screen.dart';
import 'create_job_card_sheet.dart';

class PendingJobCardsSheet extends ConsumerWidget {
  const PendingJobCardsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PendingJobCardsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pendingJobsAsync = ref.watch(pendingJobCardsProvider);
    final customersAsync = ref.watch(customersProvider);
    final customers = customersAsync.asData?.value ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
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
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Work Orders & Advances',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          pendingJobsAsync.when(
                            data: (jobs) {
                              final validJobs = jobs.whereType<Service>().toList();
                              final totalAdvance = validJobs.fold<double>(
                                0.0,
                                (sum, j) => sum + j.advanceAmount,
                              );
                              return Text(
                                '${validJobs.length} open job${validJobs.length == 1 ? '' : 's'} • ₹${totalAdvance.toStringAsFixed(0)} advance held',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => CreateJobCardSheet.show(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Job'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Content list
              Expanded(
                child: pendingJobsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error loading work orders: $err'),
                  ),
                  data: (jobs) {
                    final validJobs = jobs.whereType<Service>().toList();
                    if (validJobs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 56,
                              color: theme.colorScheme.outline.withAlpha(100),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Active Work Orders',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All customer jobs are billed & completed.',
                              style: TextStyle(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => CreateJobCardSheet.show(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Create New Job Card'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: validJobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final job = validJobs[index];
                        final customer = customers.cast<Customer?>().firstWhere(
                              (c) => c?.id == job.customerId,
                              orElse: () => null,
                            );

                        return _PendingJobCardItem(
                          job: job,
                          customer: customer,
                          onBill: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BillingScreen(
                                  existingPendingJob: job,
                                  initialCustomer: customer,
                                ),
                              ),
                            );
                          },
                          onCancel: () => _confirmCancel(context, ref, job),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    Service job,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Work Order?'),
        content: Text(
          job.advanceAmount > 0
              ? 'This job card has an advance of ₹${job.advanceAmount.toStringAsFixed(0)} recorded. Make sure any advance received has been refunded or settled before cancelling.'
              : 'Are you sure you want to cancel this pending work order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(billingServiceProvider).cancelJobCard(job.id);
      ref.invalidate(pendingJobCardsProvider);
      ref.invalidate(customerPendingJobCardsProvider(job.customerId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job card cancelled.')),
        );
      }
    }
  }
}

class _PendingJobCardItem extends StatelessWidget {
  final Service job;
  final Customer? customer;
  final VoidCallback onBill;
  final VoidCallback onCancel;

  const _PendingJobCardItem({
    required this.job,
    required this.customer,
    required this.onBill,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingDate = DateTime.tryParse(job.serviceDate);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(90),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    customer != null && customer!.name.isNotEmpty
                        ? customer!.name[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer?.name ?? 'Unknown Customer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (customer?.vehicleName != null &&
                          customer!.vehicleName!.isNotEmpty)
                        Text(
                          customer!.vehicleName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                if (bookingDate != null)
                  Text(
                    '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Work Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                job.problemDesc ?? 'Service in progress',
                style: const TextStyle(fontSize: 13, height: 1.3),
              ),
            ),

            if (job.advanceNotes != null && job.advanceNotes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.advanceNotes!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Advance Badge & Action Buttons
            Row(
              children: [
                if (job.advanceAmount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_rounded,
                          size: 15,
                          color: Colors.green.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${job.advanceAmount.toStringAsFixed(0)} Advance (${job.advancePaymentMode ?? 'Cash'})',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No Advance',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Cancel Job',
                  visualDensity: VisualDensity.compact,
                  onPressed: onCancel,
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: onBill,
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Complete & Bill'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
