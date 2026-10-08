import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_drawer_button.dart';

import '../models/report_models.dart';
import '../providers/report_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDateRange() async {
    final currentRange = ref.read(selectedReportRangeProvider);
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(
        start: currentRange.start,
        end: currentRange.end,
      ),
    );

    if (selected != null) {
      ref
          .read(selectedReportRangeProvider.notifier)
          .setCustomRange(selected.start, selected.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRange = ref.watch(selectedReportRangeProvider);
    final reportAsync = ref.watch(currentComprehensiveReportProvider);

    return Scaffold(
      appBar: AppBar(
        leading: appDrawerLeading(context),
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(comprehensiveReportProvider);
              ref.invalidate(inventorySummaryProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Financials'),
            Tab(icon: Icon(Icons.pie_chart_outline), text: 'Expenses'),
            Tab(icon: Icon(Icons.people_outline), text: 'Top Customers'),
            Tab(icon: Icon(Icons.build_circle_outlined), text: 'Top Parts'),
            Tab(icon: Icon(Icons.badge_outlined), text: 'Salaries'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(selectedRange),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error loading reports: $err',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(comprehensiveReportProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (report) => TabBarView(
                controller: _tabController,
                children: [
                  _FinancialOverviewTab(report: report),
                  _ExpenseBreakdownTab(report: report),
                  _TopCustomersTab(report: report),
                  _TopPartsTab(report: report),
                  _SalarySummaryTab(report: report),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(ReportDateRange selectedRange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedRange.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('This Month'),
                onPressed: () => ref
                    .read(selectedReportRangeProvider.notifier)
                    .setThisMonth(),
              ),
              ActionChip(
                label: const Text('This Year'),
                onPressed: () => ref
                    .read(selectedReportRangeProvider.notifier)
                    .setThisYear(),
              ),
              ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Custom'),
                onPressed: _pickCustomDateRange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinancialOverviewTab extends StatelessWidget {
  final ComprehensiveReport report;

  const _FinancialOverviewTab({required this.report});

  @override
  Widget build(BuildContext context) {
    final profit = report.profit;
    final isProfitable = profit.netProfit >= 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Sales',
                value: '₹${report.sales.totalSales.toStringAsFixed(2)}',
                subtitle: '${report.sales.invoiceCount} invoices',
                color: Colors.blue.shade700,
                icon: Icons.point_of_sale,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Total Expenses',
                value: '₹${report.expenses.totalExpenses.toStringAsFixed(2)}',
                subtitle:
                    'Biz: ₹${report.expenses.totalBusinessExpenses.toStringAsFixed(0)}',
                color: Colors.orange.shade800,
                icon: Icons.receipt_long,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Net Profit',
                value: '₹${profit.netProfit.toStringAsFixed(2)}',
                subtitle:
                    'Margin: ${profit.profitMarginPercentage.toStringAsFixed(1)}%',
                color: isProfitable
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                icon: isProfitable ? Icons.trending_up : Icons.trending_down,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Jobs Done',
                value: '${report.servicesCompleted}',
                subtitle:
                    'Avg Inv: ₹${report.sales.averageInvoiceValue.toStringAsFixed(0)}',
                color: Colors.purple.shade700,
                icon: Icons.car_repair,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Sales Trend',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (report.sales.trends.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('No sales records in selected date range.'),
              ),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY:
                        report.sales.trends
                            .map((t) => t.totalSales)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2,
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < report.sales.trends.length) {
                              final label =
                                  report.sales.trends[idx].periodLabel;
                              final short = label.length > 5
                                  ? label.substring(label.length - 5)
                                  : label;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  short,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(
                      report.sales.trends.length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: report.sales.trends[i].totalSales,
                            color: Colors.blue.shade600,
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Inventory Valuation Snapshot',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryCol(
                  title: 'Total Parts',
                  value: '${report.inventory.totalPartCount}',
                ),
                _SummaryCol(
                  title: 'Total Stock Units',
                  value: '${report.inventory.totalStockUnits}',
                ),
                _SummaryCol(
                  title: 'Inventory Value',
                  value:
                      '₹${report.inventory.totalInventoryValue.toStringAsFixed(2)}',
                ),
                _SummaryCol(
                  title: 'Low Stock Items',
                  value: '${report.inventory.lowStockCount}',
                  color: report.inventory.lowStockCount > 0
                      ? Colors.red
                      : Colors.green,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpenseBreakdownTab extends StatelessWidget {
  final ComprehensiveReport report;

  const _ExpenseBreakdownTab({required this.report});

  @override
  Widget build(BuildContext context) {
    final categories = report.expenses.categories;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Business Expenses',
                value:
                    '₹${report.expenses.totalBusinessExpenses.toStringAsFixed(2)}',
                subtitle: 'Operational overhead',
                color: Colors.amber.shade900,
                icon: Icons.business_center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Salary Expenses',
                value:
                    '₹${report.expenses.totalSalaryExpenses.toStringAsFixed(2)}',
                subtitle: 'Staff payroll',
                color: Colors.teal.shade800,
                icon: Icons.badge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (categories.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No business expenses recorded.')),
            ),
          )
        else ...[
          SizedBox(
            height: 220,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: List.generate(categories.length, (i) {
                      final cat = categories[i];
                      final colors = [
                        Colors.blue,
                        Colors.orange,
                        Colors.green,
                        Colors.purple,
                        Colors.red,
                        Colors.teal,
                        Colors.amber,
                        Colors.cyan,
                      ];
                      final color = colors[i % colors.length];
                      return PieChartSectionData(
                        value: cat.amount,
                        title: '${cat.percentage.toStringAsFixed(0)}%',
                        color: color,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Expense Breakdown by Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...categories.map(
            (cat) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    cat.category.isNotEmpty
                        ? cat.category[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(
                  cat.category,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${cat.count} transactions'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${cat.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${cat.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TopCustomersTab extends StatelessWidget {
  final ComprehensiveReport report;

  const _TopCustomersTab({required this.report});

  @override
  Widget build(BuildContext context) {
    final customers = report.topCustomers;

    if (customers.isEmpty) {
      return const Center(
        child: Text('No customer billing history in selected period.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final cust = customers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: index < 3 ? Colors.amber.shade700 : null,
              foregroundColor: index < 3 ? Colors.white : null,
              child: Text('#${index + 1}'),
            ),
            title: Text(
              cust.customerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${cust.customerMobile}${cust.vehicleName != null ? ' • ${cust.vehicleName}' : ''}\n${cust.serviceCount} service(s)',
            ),
            isThreeLine: true,
            trailing: Text(
              '₹${cust.totalSpent.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopPartsTab extends StatelessWidget {
  final ComprehensiveReport report;

  const _TopPartsTab({required this.report});

  @override
  Widget build(BuildContext context) {
    final parts = report.topParts;

    if (parts.isEmpty) {
      return const Center(child: Text('No parts sold in selected period.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parts.length,
      itemBuilder: (context, index) {
        final part = parts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(child: Text('${part.quantitySold}x')),
            title: Text(
              part.partName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Part #${part.partNumber}${part.category != null ? ' • ${part.category}' : ''}\nStock: ${part.currentStock}',
            ),
            isThreeLine: true,
            trailing: Text(
              '₹${part.totalRevenue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SalarySummaryTab extends StatelessWidget {
  final ComprehensiveReport report;

  const _SalarySummaryTab({required this.report});

  @override
  Widget build(BuildContext context) {
    final salaries = report.salaries;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Paid',
                value: '₹${salaries.totalPaid.toStringAsFixed(2)}',
                subtitle: 'Disbursed in period',
                color: Colors.green.shade800,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Total Pending',
                value: '₹${salaries.totalPending.toStringAsFixed(2)}',
                subtitle: 'Awaiting payment',
                color: Colors.orange.shade800,
                icon: Icons.pending_actions,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Staff Payroll Summary',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (salaries.items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No employees registered.')),
            ),
          )
        else
          ...salaries.items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    item.employeeName.isNotEmpty
                        ? item.employeeName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(
                  item.employeeName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Monthly: ₹${item.monthlySalary.toStringAsFixed(0)} • Payments: ${item.paymentCount}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Paid: ₹${item.paidAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (item.pendingAmount > 0)
                      Text(
                        'Pending: ₹${item.pendingAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCol extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const _SummaryCol({required this.title, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
