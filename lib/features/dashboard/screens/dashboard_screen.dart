import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_drawer_button.dart';

import '../../billing/screens/billing_screen.dart';
import '../models/dashboard_summary.dart';
import '../providers/dashboard_provider.dart';
import '../services/dashboard_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late DashboardDateRange _selectedRange;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedRange = DashboardDateRange.month(now);
  }

  Future<void> _selectDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedRange.start,
        end: _selectedRange.end,
      ),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedRange = DashboardDateRange(
        start: selected.start,
        end: selected.end,
      );
    });
  }

  void _selectThisMonth() {
    setState(() {
      _selectedRange = DashboardDateRange.month(DateTime.now());
    });
  }

  void _selectThisYear() {
    setState(() {
      _selectedRange = DashboardDateRange.year(DateTime.now());
    });
  }

  void _refresh() {
    ref.invalidate(dashboardProvider(_selectedRange));
  }

  void _openBilling() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BillingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider(_selectedRange));

    return Scaffold(
      appBar: AppBar(
        leading: appDrawerLeading(context),
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load dashboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            ),
          );
        },
        data: (summary) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider(_selectedRange));

              await ref.read(dashboardProvider(_selectedRange).future);
            },
            child: _buildDashboard(context, summary),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardSummary summary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBillingButton(),
        const SizedBox(height: 16),
        _buildDateControls(context),
        const SizedBox(height: 16),
        _buildSummaryGrid(summary),
        const SizedBox(height: 24),
        _buildLowStockSection(summary),
        const SizedBox(height: 24),
        _buildTopSellingSection(summary),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBillingButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: _openBilling,
        icon: const Icon(Icons.receipt_long, size: 26),
        label: const Text(
          'Billing',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDateControls(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _selectThisMonth,
                  child: const Text('This Month'),
                ),
                OutlinedButton(
                  onPressed: _selectThisYear,
                  child: const Text('This Year'),
                ),
                FilledButton.tonal(
                  onPressed: _selectDateRange,
                  child: const Text('Custom Range'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${_formatDate(_selectedRange.start)}'
              ' - '
              '${_formatDate(_selectedRange.end)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(DashboardSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 900
            ? 4
            : width >= 600
            ? 3
            : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.65,
          children: [
            _SummaryCard(
              title: 'Sales',
              value: _formatAmount(summary.totalSales),
              icon: Icons.point_of_sale,
            ),
            _SummaryCard(
              title: 'Expenses',
              value: _formatAmount(summary.totalExpenses),
              icon: Icons.money_off,
            ),
            _SummaryCard(
              title: 'Profit',
              value: _formatAmount(summary.profit),
              icon: Icons.trending_up,
            ),
            _SummaryCard(
              title: 'Services Completed',
              value: summary.servicesCompleted.toString(),
              icon: Icons.build,
            ),
            _SummaryCard(
              title: 'Inventory Value',
              value: _formatAmount(summary.inventoryValue),
              icon: Icons.inventory_2,
            ),
            _SummaryCard(
              title: 'Low Stock',
              value: summary.lowStockParts.length.toString(),
              icon: Icons.warning_amber,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLowStockSection(DashboardSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Low Stock',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (summary.lowStockParts.isEmpty)
              const Text('No parts are currently low on stock.')
            else
              ...summary.lowStockParts.map((part) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber),
                  title: Text(part.partName),
                  subtitle: Text('Part No: ${part.partNumber}'),
                  trailing: Text(
                    '${part.currentStock} / '
                    '${part.lowStockThreshold}',
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSellingSection(DashboardSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Selling Parts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (summary.topSellingParts.isEmpty)
              const Text('No parts sold in this period.')
            else
              ...summary.topSellingParts.asMap().entries.map((entry) {
                final index = entry.key;
                final part = entry.value;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(part.partName),
                  subtitle: Text('${part.quantitySold} units sold'),
                  trailing: Text(_formatAmount(part.revenue)),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
