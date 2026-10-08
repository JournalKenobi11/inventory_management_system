import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_drawer_button.dart';

import '../models/part.dart';
import '../providers/part_provider.dart';
import 'part_form_screen.dart';

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
      body: Column(
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
                      bottom: 16,
                    ),
                    itemCount: parts.length,
                    itemBuilder: (context, index) {
                      return _PartCard(part: parts[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
}

class _PartCard extends StatelessWidget {
  final Part part;

  const _PartCard({required this.part});

  @override
  Widget build(BuildContext context) {
    final isLowStock = part.currentStock <= part.lowStockThreshold;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          part.partName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Part No: ${part.partNumber}'),
              if (part.category != null) Text('Category: ${part.category}'),
              const SizedBox(height: 4),
              Text('Selling Price: ₹${part.sellingPrice.toStringAsFixed(2)}'),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${part.currentStock}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isLowStock ? Theme.of(context).colorScheme.error : null,
              ),
            ),
            Text(
              isLowStock ? 'LOW STOCK' : 'STOCK',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isLowStock ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
