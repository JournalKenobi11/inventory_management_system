import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_drawer_button.dart';

import '../../billing/billing.dart';
import '../../customers/customers.dart';
import '../../purchases/purchases.dart';
import '../../salaries/salaries.dart';
import '../models/dashboard_summary.dart';
import '../providers/dashboard_provider.dart';
import '../services/dashboard_service.dart';
import 'dashboard_completed_services_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _periodMode = 'day';
  DateTime _anchorDate = DateTime.now();
  late DashboardDateRange _selectedRange;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _anchorDate = DateTime.now();
    _periodMode = 'day';
    _selectedRange = DashboardDateRange.singleDay(_anchorDate);
  }

  void _changePeriodMode(String mode) {
    setState(() {
      _periodMode = mode;
      switch (mode) {
        case 'day':
          _selectedRange = DashboardDateRange.singleDay(_anchorDate);
          break;
        case 'week':
          _selectedRange = DashboardDateRange.week(_anchorDate);
          break;
        case 'month':
          _selectedRange = DashboardDateRange.month(_anchorDate);
          break;
      }
    });
  }

  void _goToPrevious() {
    setState(() {
      switch (_periodMode) {
        case 'day':
          _anchorDate = _anchorDate.subtract(const Duration(days: 1));
          _selectedRange = DashboardDateRange.singleDay(_anchorDate);
          break;
        case 'week':
          _anchorDate = _anchorDate.subtract(const Duration(days: 7));
          _selectedRange = DashboardDateRange.week(_anchorDate);
          break;
        case 'month':
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month - 1, 1);
          _selectedRange = DashboardDateRange.month(_anchorDate);
          break;
      }
    });
  }

  void _goToNext() {
    setState(() {
      switch (_periodMode) {
        case 'day':
          _anchorDate = _anchorDate.add(const Duration(days: 1));
          _selectedRange = DashboardDateRange.singleDay(_anchorDate);
          break;
        case 'week':
          _anchorDate = _anchorDate.add(const Duration(days: 7));
          _selectedRange = DashboardDateRange.week(_anchorDate);
          break;
        case 'month':
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + 1, 1);
          _selectedRange = DashboardDateRange.month(_anchorDate);
          break;
      }
    });
  }

  void _jumpToToday() {
    setState(() {
      _anchorDate = DateTime.now();
      switch (_periodMode) {
        case 'day':
          _selectedRange = DashboardDateRange.singleDay(_anchorDate);
          break;
        case 'week':
          _selectedRange = DashboardDateRange.week(_anchorDate);
          break;
        case 'month':
          _selectedRange = DashboardDateRange.month(_anchorDate);
          break;
      }
    });
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _anchorDate = picked;
      switch (_periodMode) {
        case 'day':
          _selectedRange = DashboardDateRange.singleDay(picked);
          break;
        case 'week':
          _selectedRange = DashboardDateRange.week(picked);
          break;
        case 'month':
          _selectedRange = DashboardDateRange.month(picked);
          break;
      }
    });
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
        return DashboardDateRange.week(_anchorDate) == DashboardDateRange.week(now);
      case 'month':
        return _anchorDate.year == now.year && _anchorDate.month == now.month;
      default:
        return false;
    }
  }

  String _getPeriodTitle() {
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
        final yearStr = _anchorDate.year != now.year ? ' ${_anchorDate.year}' : '';
        return '$dayName, ${_anchorDate.day} ${_months[_anchorDate.month - 1]}$yearStr';

      case 'week':
        final isThisWeek = DashboardDateRange.week(_anchorDate) == DashboardDateRange.week(now);
        final s = _selectedRange.start;
        final e = _selectedRange.end;
        final prefix = isThisWeek ? 'This Week: ' : '';
        final yearStr = e.year != now.year ? ' ${e.year}' : '';
        if (s.month == e.month) {
          return '$prefix${s.day}–${e.day} ${_months[s.month - 1]}$yearStr';
        } else {
          return '$prefix${s.day} ${_months[s.month - 1]} – ${e.day} ${_months[e.month - 1]}$yearStr';
        }

      case 'month':
        final isThisMonth = _anchorDate.year == now.year && _anchorDate.month == now.month;
        final prefix = isThisMonth ? 'This Month: ' : '';
        return '$prefix${_months[_anchorDate.month - 1]} ${_anchorDate.year}';

      default:
        return '';
    }
  }

  void _refresh() {
    ref.invalidate(dashboardProvider(_selectedRange));
  }

  Future<void> _openBilling() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BillingScreen()));
    _refresh();
  }

  Future<void> _openAddStock() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PurchaseEntryScreen()));
    _refresh();
  }

  Future<void> _openSalaries() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EmployeeListScreen()));
    _refresh();
  }

  void _openCompletedServices() {
    DashboardCompletedServicesSheet.show(
      context: context,
      start: _selectedRange.start,
      end: _selectedRange.end,
      periodTitle: _getPeriodTitle(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider(_selectedRange));

    return Scaffold(
      appBar: AppBar(
        leading: appDrawerLeading(context),
        title: const Text('Dashboard'),
        actions: [
          _buildPendingJobsNotificationAction(context),
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
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isWide = width >= 800;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildQuickActionButtons(context),
              const SizedBox(height: 16),
              _buildPendingJobCardsAlert(),
              const SizedBox(height: 16),
              _buildDateControls(context),
              const SizedBox(height: 16),
              _buildSummaryGrid(summary, width),
              const SizedBox(height: 16),
              _buildServiceRemindersAlert(),
              const SizedBox(height: 24),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLowStockSection(summary)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTopSellingSection(summary)),
                  ],
                )
              else ...[
                _buildLowStockSection(summary),
                const SizedBox(height: 24),
                _buildTopSellingSection(summary),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPendingJobsNotificationAction(BuildContext context) {
    final pendingJobsAsync = ref.watch(pendingJobCardsProvider);
    final count = pendingJobsAsync.asData?.value.length ?? 0;

    return IconButton(
      tooltip: 'Work Orders & Advances',
      onPressed: () => PendingJobCardsSheet.show(context),
      icon: count > 0
          ? Badge.count(
              count: count,
              backgroundColor: Colors.red.shade700,
              child: const Icon(Icons.pending_actions_rounded),
            )
          : const Icon(Icons.pending_actions_rounded),
    );
  }

  Widget _buildPendingJobCardsAlert() {
    final pendingJobsAsync = ref.watch(pendingJobCardsProvider);

    return pendingJobsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (jobs) {
        if (jobs.isEmpty) {
          return const SizedBox.shrink();
        }

        final totalAdvance = jobs.fold<double>(
          0.0,
          (sum, j) => sum + j.advanceAmount,
        );

        return Card(
          elevation: 1,
          color: Colors.amber.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.amber.shade300,
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.engineering_rounded,
              color: Colors.amber.shade900,
              size: 28,
            ),
            title: Text(
              '${jobs.length} Active Work Order${jobs.length > 1 ? 's' : ''}'
              '${totalAdvance > 0 ? ' • ₹${_formatAmount(totalAdvance)} Advance Held' : ''}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
            ),
            subtitle: Text(
              '${jobs.first.problemDesc ?? "Service in progress"}. Tap to review, bill, or manage.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => PendingJobCardsSheet.show(context),
          ),
        );
      },
    );
  }

  Widget _buildServiceRemindersAlert() {
    final remindersAsync = ref.watch(customerServiceRemindersProvider);

    return remindersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reminders) {
        final dueReminders = reminders.where((r) => r.isDue).toList();
        if (dueReminders.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 1,
          color: Theme.of(context).colorScheme.errorContainer.withAlpha(90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.error.withAlpha(120),
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.alarm_on_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 28,
            ),
            title: Text(
              '${dueReminders.length} Customer${dueReminders.length > 1 ? 's' : ''} Due for Service',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            subtitle: const Text(
              'Periodic 90-day service reminder. Tap to review customer list.',
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerListScreen()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isVeryNarrow = width < 340;

    if (isVeryNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 46),
            child: FilledButton.icon(
              onPressed: _openBilling,
              icon: const Icon(Icons.receipt_long, size: 20),
              label: const Text(
                'New Bill',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 46),
            child: FilledButton.tonalIcon(
              onPressed: _openAddStock,
              icon: const Icon(Icons.add_box_rounded, size: 20),
              label: const Text(
                'Add Stock',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 46),
            child: FilledButton.tonalIcon(
              onPressed: _openSalaries,
              icon: const Icon(Icons.badge_rounded, size: 20),
              label: const Text(
                'Salaries',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: _openBilling,
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'New Bill',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: () => CreateJobCardSheet.show(context),
              icon: const Icon(Icons.engineering_rounded, size: 18),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Job Card',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: _openAddStock,
              icon: const Icon(Icons.add_box_rounded, size: 18),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Add Stock',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateControls(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
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
                    icon: Icon(Icons.today, size: 16),
                  ),
                  ButtonSegment<String>(
                    value: 'week',
                    label: Text('Week'),
                    icon: Icon(Icons.view_week, size: 16),
                  ),
                  ButtonSegment<String>(
                    value: 'month',
                    label: Text('Month'),
                    icon: Icon(Icons.calendar_month, size: 16),
                  ),
                ],
                selected: {_periodMode},
                onSelectionChanged: (newSelection) {
                  _changePeriodMode(newSelection.first);
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  onPressed: _goToPrevious,
                  tooltip: 'Previous $_periodMode',
                ),
                Expanded(
                  child: InkWell(
                    onTap: _pickCustomDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _getPeriodTitle(),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                size: 15,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                          if (!_isCurrentPeriod()) ...[
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: _jumpToToday,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Jump to Today',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  onPressed: _goToNext,
                  tooltip: 'Next $_periodMode',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(DashboardSummary summary, double width) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final crossAxisCount = width >= 900
        ? 4
        : width >= 600
            ? 3
            : 2;

    final double baseRatio = width < 360
        ? 1.35
        : width < 420
            ? 1.45
            : (width >= 900 ? 1.75 : 1.6);
    final double childAspectRatio =
        (baseRatio / textScale.clamp(1.0, 1.6)).clamp(1.1, 2.0);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: childAspectRatio,
      children: [
        _SummaryCard(
          title: 'Sales',
          value: _formatAmount(summary.totalSales),
          icon: Icons.point_of_sale_rounded,
          iconColor: Colors.blue.shade700,
          onTap: _openCompletedServices,
          onLongPress: _openCompletedServices,
        ),
        _SummaryCard(
          title: 'Expenses',
          value: _formatAmount(summary.totalExpenses),
          icon: Icons.money_off_rounded,
          iconColor: Colors.orange.shade800,
          subtitle: summary.stockPurchases > 0
              ? 'Stock: ${_formatAmount(summary.stockPurchases)}'
              : null,
        ),
        _SummaryCard(
          title: 'Profit',
          value: _formatAmount(summary.profit),
          icon: summary.profit >= 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          iconColor: summary.profit >= 0
              ? Colors.green.shade700
              : Colors.red.shade700,
        ),
        _SummaryCard(
          title: 'Services Completed',
          value: summary.servicesCompleted.toString(),
          icon: Icons.build_circle_rounded,
          iconColor: Colors.indigo.shade700,
          onTap: _openCompletedServices,
          onLongPress: _openCompletedServices,
        ),
        _SummaryCard(
          title: 'Inventory Value',
          value: _formatAmount(summary.inventoryValue),
          icon: Icons.inventory_2_rounded,
          iconColor: Colors.teal.shade700,
        ),
        _SummaryCard(
          title: 'Low Stock',
          value: summary.lowStockParts.length.toString(),
          icon: Icons.warning_amber_rounded,
          iconColor: summary.lowStockParts.isNotEmpty
              ? Colors.amber.shade900
              : Colors.grey.shade600,
        ),
      ],
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
                  title: Text(
                    part.partName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Part No: ${part.partNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                  title: Text(
                    part.partName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${part.quantitySold} units sold'),
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_formatAmount(part.revenue)),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = const Color(0xFF0D47A1),
    this.subtitle,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0.5,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  if (subtitle != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          subtitle!,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    )
                  else if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: theme.colorScheme.outline.withAlpha(120),
                    ),
                ],
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
