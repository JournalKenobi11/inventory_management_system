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
  late DateTime _anchorDate;
  String _periodMode = 'month';

  static const _months = [
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
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _anchorDate = DateTime.now();
    _periodMode = 'month';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changePeriodMode(String mode) {
    setState(() {
      _periodMode = mode;
      switch (mode) {
        case 'day':
          ref.read(selectedReportRangeProvider.notifier).setSingleDay(_anchorDate);
          break;
        case 'week':
          ref.read(selectedReportRangeProvider.notifier).setWeek(_anchorDate);
          break;
        case 'month':
          ref.read(selectedReportRangeProvider.notifier).setMonth(_anchorDate);
          break;
        case 'year':
          ref.read(selectedReportRangeProvider.notifier).setYear(_anchorDate);
          break;
      }
    });
  }

  void _goToPrevious() {
    setState(() {
      switch (_periodMode) {
        case 'day':
          _anchorDate = _anchorDate.subtract(const Duration(days: 1));
          ref.read(selectedReportRangeProvider.notifier).setSingleDay(_anchorDate);
          break;
        case 'week':
          _anchorDate = _anchorDate.subtract(const Duration(days: 7));
          ref.read(selectedReportRangeProvider.notifier).setWeek(_anchorDate);
          break;
        case 'month':
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month - 1, 1);
          ref.read(selectedReportRangeProvider.notifier).setMonth(_anchorDate);
          break;
        case 'year':
          _anchorDate = DateTime(_anchorDate.year - 1, 1, 1);
          ref.read(selectedReportRangeProvider.notifier).setYear(_anchorDate);
          break;
      }
    });
  }

  void _goToNext() {
    setState(() {
      switch (_periodMode) {
        case 'day':
          _anchorDate = _anchorDate.add(const Duration(days: 1));
          ref.read(selectedReportRangeProvider.notifier).setSingleDay(_anchorDate);
          break;
        case 'week':
          _anchorDate = _anchorDate.add(const Duration(days: 7));
          ref.read(selectedReportRangeProvider.notifier).setWeek(_anchorDate);
          break;
        case 'month':
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + 1, 1);
          ref.read(selectedReportRangeProvider.notifier).setMonth(_anchorDate);
          break;
        case 'year':
          _anchorDate = DateTime(_anchorDate.year + 1, 1, 1);
          ref.read(selectedReportRangeProvider.notifier).setYear(_anchorDate);
          break;
      }
    });
  }

  void _jumpToToday() {
    setState(() {
      _anchorDate = DateTime.now();
      if (_periodMode == 'custom') {
        _periodMode = 'month';
      }
      switch (_periodMode) {
        case 'day':
          ref.read(selectedReportRangeProvider.notifier).setSingleDay(_anchorDate);
          break;
        case 'week':
          ref.read(selectedReportRangeProvider.notifier).setWeek(_anchorDate);
          break;
        case 'month':
          ref.read(selectedReportRangeProvider.notifier).setMonth(_anchorDate);
          break;
        case 'year':
          ref.read(selectedReportRangeProvider.notifier).setYear(_anchorDate);
          break;
      }
    });
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _anchorDate = picked;
      switch (_periodMode) {
        case 'day':
          ref.read(selectedReportRangeProvider.notifier).setSingleDay(picked);
          break;
        case 'week':
          ref.read(selectedReportRangeProvider.notifier).setWeek(picked);
          break;
        case 'month':
          ref.read(selectedReportRangeProvider.notifier).setMonth(picked);
          break;
        case 'year':
          ref.read(selectedReportRangeProvider.notifier).setYear(picked);
          break;
        case 'custom':
          _periodMode = 'day';
          ref.read(selectedReportRangeProvider.notifier).setSingleDay(picked);
          break;
      }
    });
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
      setState(() {
        _periodMode = 'custom';
        _anchorDate = selected.start;
      });
      ref
          .read(selectedReportRangeProvider.notifier)
          .setCustomRange(selected.start, selected.end);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCurrentPeriod() {
    final now = DateTime.now();
    switch (_periodMode) {
      case 'day':
        return _isSameDay(_anchorDate, now);
      case 'week':
        final currentWeek = ReportDateRange.week(now);
        final selectedWeek = ReportDateRange.week(_anchorDate);
        return currentWeek.start == selectedWeek.start &&
            currentWeek.end == selectedWeek.end;
      case 'month':
        return _anchorDate.year == now.year && _anchorDate.month == now.month;
      case 'year':
        return _anchorDate.year == now.year;
      default:
        return false;
    }
  }

  String _getPeriodTitle(ReportDateRange selectedRange) {
    final now = DateTime.now();
    switch (_periodMode) {
      case 'day':
        if (_isSameDay(_anchorDate, now)) {
          return 'Today, ${_anchorDate.day} ${_months[_anchorDate.month - 1]}';
        }
        final yesterday = now.subtract(const Duration(days: 1));
        if (_isSameDay(_anchorDate, yesterday)) {
          return 'Yesterday, ${_anchorDate.day} ${_months[_anchorDate.month - 1]}';
        }
        final tomorrow = now.add(const Duration(days: 1));
        if (_isSameDay(_anchorDate, tomorrow)) {
          return 'Tomorrow, ${_anchorDate.day} ${_months[_anchorDate.month - 1]}';
        }
        final dayName = _weekdays[_anchorDate.weekday - 1];
        final yearStr =
            _anchorDate.year != now.year ? ' ${_anchorDate.year}' : '';
        return '$dayName, ${_anchorDate.day} ${_months[_anchorDate.month - 1]}$yearStr';

      case 'week':
        final currentWeek = ReportDateRange.week(now);
        final isThisWeek = currentWeek.start == selectedRange.start &&
            currentWeek.end == selectedRange.end;
        final s = selectedRange.start;
        final e = selectedRange.end;
        final prefix = isThisWeek ? 'This Week: ' : '';
        final yearStr = e.year != now.year ? ' ${e.year}' : '';
        if (s.month == e.month) {
          return '$prefix${s.day}–${e.day} ${_months[s.month - 1]}$yearStr';
        } else {
          return '$prefix${s.day} ${_months[s.month - 1]} – ${e.day} ${_months[e.month - 1]}$yearStr';
        }

      case 'month':
        return '${_months[_anchorDate.month - 1]} ${_anchorDate.year}';

      case 'year':
        return 'Year ${_anchorDate.year}';

      case 'custom':
      default:
        final s = selectedRange.start;
        final e = selectedRange.end;
        if (s == e) {
          return '${s.day} ${_months[s.month - 1]} ${s.year}';
        }
        return '${s.day} ${_months[s.month - 1]} ${s.year} – ${e.day} ${_months[e.month - 1]} ${e.year}';
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
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
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(ReportDateRange selectedRange) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'day',
                    label: Text('Day'),
                  ),
                  ButtonSegment<String>(
                    value: 'week',
                    label: Text('Week'),
                  ),
                  ButtonSegment<String>(
                    value: 'month',
                    label: Text('Month'),
                  ),
                  ButtonSegment<String>(
                    value: 'year',
                    label: Text('Year'),
                  ),
                ],
                selected: _periodMode == 'custom' ? <String>{} : {_periodMode},
                emptySelectionAllowed: true,
                onSelectionChanged: (newSelection) {
                  if (newSelection.isNotEmpty) {
                    _changePeriodMode(newSelection.first);
                  }
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 4),
                  ),
                  textStyle: WidgetStatePropertyAll(
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  onPressed: _periodMode == 'custom' ? null : _goToPrevious,
                  tooltip: 'Previous $_periodMode',
                ),
                Expanded(
                  child: InkWell(
                    onTap: _periodMode == 'custom'
                        ? _pickCustomDateRange
                        : _pickCustomDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _getPeriodTitle(selectedRange),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                          if (!_isCurrentPeriod()) ...[
                            const SizedBox(height: 3),
                            InkWell(
                              onTap: _jumpToToday,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Jump to Today',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  onPressed: _periodMode == 'custom' ? null : _goToNext,
                  tooltip: 'Next $_periodMode',
                ),
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: _periodMode == 'custom'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _pickCustomDateRange,
                  tooltip: 'Custom Date Range',
                ),
              ],
            ),
          ],
        ),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final cardSales = _MetricCard(
              title: 'Total Sales',
              value: '₹${report.sales.totalSales.toStringAsFixed(2)}',
              subtitle: '${report.sales.invoiceCount} invoices',
              color: Colors.blue.shade700,
              icon: Icons.point_of_sale,
            );
            final cardExpenses = _MetricCard(
              title: 'Total Expenses',
              value: '₹${report.expenses.totalExpenses.toStringAsFixed(2)}',
              subtitle:
                  'Biz: ₹${report.expenses.totalBusinessExpenses.toStringAsFixed(0)}',
              color: Colors.orange.shade800,
              icon: Icons.receipt_long,
            );
            final cardProfit = _MetricCard(
              title: 'Net Profit',
              value: '₹${profit.netProfit.toStringAsFixed(2)}',
              subtitle:
                  'Margin: ${profit.profitMarginPercentage.toStringAsFixed(1)}%',
              color: isProfitable
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              icon: isProfitable ? Icons.trending_up : Icons.trending_down,
            );
            final cardJobs = _MetricCard(
              title: 'Jobs Done',
              value: '${report.servicesCompleted}',
              subtitle:
                  'Avg Inv: ₹${report.sales.averageInvoiceValue.toStringAsFixed(0)}',
              color: Colors.purple.shade700,
              icon: Icons.car_repair,
            );

            if (constraints.maxWidth >= 720) {
              return Row(
                children: [
                  Expanded(child: cardSales),
                  const SizedBox(width: 12),
                  Expanded(child: cardExpenses),
                  const SizedBox(width: 12),
                  Expanded(child: cardProfit),
                  const SizedBox(width: 12),
                  Expanded(child: cardJobs),
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cardSales),
                    const SizedBox(width: 12),
                    Expanded(child: cardExpenses),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: cardProfit),
                    const SizedBox(width: 12),
                    Expanded(child: cardJobs),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _buildProfitTallyCard(context, report),
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
                    maxY: (() {
                      final maxSale = report.sales.trends
                          .map((t) => t.totalSales)
                          .reduce((a, b) => a > b ? a : b);
                      return maxSale > 0 ? maxSale * 1.2 : 100.0;
                    })(),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 440;
                if (isNarrow) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCol(
                              title: 'Total Parts',
                              value: '${report.inventory.totalPartCount}',
                            ),
                          ),
                          Expanded(
                            child: _SummaryCol(
                              title: 'Total Stock Units',
                              value: '${report.inventory.totalStockUnits}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCol(
                              title: 'Inventory Value',
                              value:
                                  '₹${report.inventory.totalInventoryValue.toStringAsFixed(2)}',
                            ),
                          ),
                          Expanded(
                            child: _SummaryCol(
                              title: 'Low Stock Items',
                              value: '${report.inventory.lowStockCount}',
                              color: report.inventory.lowStockCount > 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _SummaryCol(
                        title: 'Total Parts',
                        value: '${report.inventory.totalPartCount}',
                      ),
                    ),
                    Expanded(
                      child: _SummaryCol(
                        title: 'Total Stock Units',
                        value: '${report.inventory.totalStockUnits}',
                      ),
                    ),
                    Expanded(
                      child: _SummaryCol(
                        title: 'Inventory Value',
                        value:
                            '₹${report.inventory.totalInventoryValue.toStringAsFixed(2)}',
                      ),
                    ),
                    Expanded(
                      child: _SummaryCol(
                        title: 'Low Stock Items',
                        value: '${report.inventory.lowStockCount}',
                        color: report.inventory.lowStockCount > 0
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfitTallyCard(
    BuildContext context,
    ComprehensiveReport report,
  ) {
    final profit = report.profit;
    final isGrossProfitable = profit.grossProfit >= 0;
    final isCashProfitable = profit.cashProfit >= 0;
    final totalCashOutflows =
        report.expenses.totalExpenses + profit.stockPurchases;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Operating Profit (Gross Profit)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Workshop Profit (Gross Profit)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTallyRow(
                  '1. Gross Customer Billing (Sales)',
                  '₹${profit.totalRevenue.toStringAsFixed(2)}',
                  isBold: true,
                ),
                _buildTallySubRow(
                  '• Parts Billed',
                  '₹${profit.partsRevenue.toStringAsFixed(2)}',
                ),
                _buildTallySubRow(
                  '• Labour Charges',
                  '₹${profit.labourRevenue.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 4),
                _buildTallyRow(
                  '2. Cost of Parts Used (COGS)',
                  '- ₹${profit.cogs.toStringAsFixed(2)}',
                  color: Colors.red.shade700,
                ),
                const Divider(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isGrossProfitable
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isGrossProfitable
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Proper Profit (Gross Markup + Labour)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          '₹${profit.grossProfit.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isGrossProfitable
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Card 2: Cash Drawer Flow
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.point_of_sale_outlined,
                        color: Colors.blue.shade900,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Cash Drawer Flow (In vs Out)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTallyRow(
                  '• Total Cash In (Customer Billings)',
                  '+ ₹${profit.totalRevenue.toStringAsFixed(2)}',
                  color: Colors.green.shade700,
                  isBold: true,
                ),
                _buildTallyRow(
                  '• Total Cash Out (Purchases & Overhead)',
                  '- ₹${totalCashOutflows.toStringAsFixed(2)}',
                  color: Colors.red.shade700,
                  isBold: true,
                ),
                _buildTallySubRow(
                  '• Supplier Stock Restocking',
                  '₹${profit.stockPurchases.toStringAsFixed(2)}',
                ),
                _buildTallySubRow(
                  '• Shop Expenses & Salaries',
                  '₹${report.expenses.totalExpenses.toStringAsFixed(2)}',
                ),
                const Divider(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCashProfitable
                        ? Colors.blue.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCashProfitable
                          ? Colors.blue.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Net Cash Flow in Drawer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          '₹${profit.cashProfit.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isCashProfitable
                                ? Colors.blue.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 Note: Workshop Profit shows gross earnings on completed jobs (Parts Markup + Labour). Cash Flow reflects physical cash remaining in drawer after stocking parts.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTallyRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTallySubRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 1, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${cust.customerMobile}${cust.vehicleName != null ? ' • ${cust.vehicleName}' : ''}\n${cust.serviceCount} service(s)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            trailing: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '₹${cust.totalSpent.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Part #${part.partNumber}${part.category != null ? ' • ${part.category}' : ''}\nStock: ${part.currentStock}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            trailing: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '₹${part.totalRevenue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Monthly: ₹${item.monthlySalary.toStringAsFixed(0)} • Payments: ${item.paymentCount}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Paid: ₹${item.paidAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    if (item.pendingAmount > 0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Pending: ₹${item.pendingAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
