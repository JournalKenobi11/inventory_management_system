import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_drawer_button.dart';

import '../models/part.dart';
import '../providers/part_provider.dart';
import 'part_form_screen.dart';
import '../../purchases/purchases.dart';

class PartListScreen extends ConsumerStatefulWidget {
  const PartListScreen({super.key});

  @override
  ConsumerState<PartListScreen> createState() => _PartListScreenState();
}

class _PartListScreenState extends ConsumerState<PartListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partsAsync = ref.watch(partsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: appDrawerLeading(context),
        title: const Text('Inventory'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search parts',
                hintText: 'Part number, name or category',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(partsProvider.notifier).loadParts();
                          setState(() {});
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(partsProvider.notifier).searchParts(value);
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: partsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load inventory.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (parts) {
                if (parts.isEmpty) {
                  return const Center(child: Text('No parts found.'));
                }

                return RefreshIndicator(
                  onRefresh: () {
                    return ref.read(partsProvider.notifier).loadParts();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 88,
                    ),
                    itemCount: parts.length,
                    itemBuilder: (context, index) {
                      return _PartCard(
                        part: parts[index],
                        onEdit: () async {
                          final updated =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PartFormScreen(part: parts[index]),
                            ),
                          );

                          if (updated == true && mounted) {
                            await ref
                                .read(partsProvider.notifier)
                                .loadParts();
                          }
                        },
                        onAddStock: () async {
                          final added =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => PurchaseEntryScreen(
                                preselectedPart: parts[index],
                              ),
                            ),
                          );

                          if (added == true && mounted) {
                            await ref
                                .read(partsProvider.notifier)
                                .loadParts();
                          }
                        },
                        onViewHistory: () => _showStockHistory(parts[index]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const PartFormScreen()),
          );

          if (created == true && mounted) {
            await ref.read(partsProvider.notifier).loadParts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showStockHistory(Part part) async {
    final movements = await ref
        .read(partServiceProvider)
        .getStockMovements(part.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              part.partName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Stock Movement Ledger • Current: ${part.currentStock}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: movements.isEmpty
                      ? const Center(
                          child: Text(
                            'No stock movement history recorded yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: movements.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final m = movements[index];
                            final isPositive = m.quantityChange > 0;
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isPositive
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                child: Icon(
                                  isPositive
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  size: 18,
                                  color: isPositive
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    '${isPositive ? '+' : ''}${m.quantityChange}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPositive
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      m.movementType.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Balance: ${m.balanceAfter}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (m.notes != null && m.notes!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        m.notes!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      m.createdDate.length >= 16
                                          ? m.createdDate
                                              .substring(0, 16)
                                              .replaceAll('T', ' ')
                                          : m.createdDate,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PartCard extends StatelessWidget {
  final Part part;
  final VoidCallback? onEdit;
  final VoidCallback? onAddStock;
  final VoidCallback? onViewHistory;

  const _PartCard({
    required this.part,
    this.onEdit,
    this.onAddStock,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = part.currentStock <= part.lowStockThreshold;
    final isOutOfStock = part.currentStock == 0;
    final badgeColor = isOutOfStock
        ? Colors.red.shade700
        : (isLowStock ? Colors.orange.shade800 : Colors.green.shade700);
    final badgeBgColor = isOutOfStock
        ? Colors.red.shade50
        : (isLowStock ? Colors.orange.shade50 : Colors.green.shade50);
    final badgeBorderColor = isOutOfStock
        ? Colors.red.shade200
        : (isLowStock ? Colors.orange.shade200 : Colors.green.shade200);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLowStock
            ? BorderSide(color: badgeBorderColor, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          part.partName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Part No: ${part.partNumber}'),
                        if (part.category != null)
                          Text('Category: ${part.category}'),
                        const SizedBox(height: 4),
                        Text(
                            'Selling Price: ₹${part.sellingPrice.toStringAsFixed(2)}'),
                        Text(
                            'Purchase Price: ₹${part.purchasePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${part.currentStock}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeBorderColor),
                        ),
                        child: Text(
                          isLowStock ? 'LOW STOCK' : 'IN STOCK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.history, size: 20),
                    tooltip: 'Stock History',
                    onPressed: onViewHistory,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    onPressed: onAddStock,
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('+ Stock'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
