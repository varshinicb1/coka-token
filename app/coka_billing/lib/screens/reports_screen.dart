import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../utils/date_utils.dart' as date_utils;

class ReportsScreen extends StatefulWidget {
  final AppProvider provider;

  const ReportsScreen({super.key, required this.provider});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedPeriod = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  AppProvider get provider => widget.provider;

  List<dynamic> _getFilteredOrders() {
    final allOrders = provider.orders.where((o) => !o.isRefunded).toList();
    final today = date_utils.DateUtils.getTodayDateString();

    switch (_selectedPeriod) {
      case 1:
        final weekDates = <String>{};
        for (int i = 0; i < 7; i++) {
          final d = DateTime.now().subtract(Duration(days: i));
          weekDates.add(
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          );
        }
        return allOrders.where((o) => weekDates.contains(o.dateString)).toList();
      case 2:
        final now = DateTime.now();
        return allOrders.where((o) {
          final parts = o.dateString.split('-');
          if (parts.length != 3) return false;
          return parts[0] == now.year.toString() &&
              parts[1] == now.month.toString().padLeft(2, '0');
        }).toList();
      default:
        return allOrders.where((o) => o.dateString == today).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _getFilteredOrders();
    final totalSales = filtered.fold(0.0, (s, o) => s + o.totalAmount);
    final orderCount = filtered.length;
    final avgOrder = orderCount > 0 ? totalSales / orderCount : 0.0;

    final cashTotal = filtered
        .where((o) => o.paymentMethod == 'Cash')
        .fold(0.0, (s, o) => s + o.totalAmount);
    final upiTotal = filtered
        .where((o) => o.paymentMethod == 'UPI')
        .fold(0.0, (s, o) => s + o.totalAmount);
    final cardTotal = filtered
        .where((o) => o.paymentMethod == 'Card')
        .fold(0.0, (s, o) => s + o.totalAmount);
    final allTotal = cashTotal + upiTotal + cardTotal;

    final barData = provider.getDailySalesBreakdown(
      _selectedPeriod == 0 ? 1 : (_selectedPeriod == 1 ? 7 : 30),
    );
    final maxBarTotal =
        barData.fold(0.0, (s, d) => (d['total'] as double) > s ? (d['total'] as double) : s);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Revenue',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\u20B9${totalSales.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$orderCount Order${orderCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'This Week'),
                Tab(text: 'This Month'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Orders',
                  icon: Icons.receipt,
                  value: '$orderCount',
                  color: AppColors.cokaAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Avg Order',
                  icon: Icons.analytics,
                  value: '\u20B9${avgOrder.toStringAsFixed(0)}',
                  color: AppColors.cokaOrange,
                ),
              ),
            ],
          ),
          if (barData.isNotEmpty && maxBarTotal > 0) ...[
            const SizedBox(height: 20),
            Text(
              'Daily Sales',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: barData.map((d) {
                      final total = (d['total'] as num).toDouble();
                      final heightFactor =
                          maxBarTotal > 0 ? total / maxBarTotal : 0.0;
                      final label = d['date'] as String;
                      final shortLabel =
                          label.length >= 10 ? label.substring(5) : label;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height:
                                    100 * heightFactor.clamp(0.01, 1.0),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.5),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shortLabel,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Payment Breakdown',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _legendItem(theme.colorScheme.primary, 'Cash'),
                      _legendItem(AppColors.upiBlue, 'UPI'),
                      _legendItem(AppColors.cokaAmber, 'Card'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _paymentBar(
                        theme.colorScheme.primary,
                        allTotal > 0 ? cashTotal / allTotal : 0,
                        'Cash',
                      ),
                      const SizedBox(width: 8),
                      _paymentBar(
                        AppColors.upiBlue,
                        allTotal > 0 ? upiTotal / allTotal : 0,
                        'UPI',
                      ),
                      const SizedBox(width: 8),
                      _paymentBar(
                        AppColors.cokaAmber,
                        allTotal > 0 ? cardTotal / allTotal : 0,
                        'Card',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '\u20B9${cashTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '\u20B9${upiTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.upiBlue,
                        ),
                      ),
                      Text(
                        '\u20B9${cardTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cokaAmber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await provider.exportSalesCSV();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.file_download, size: 20),
              label: const Text('Export CSV'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _paymentBar(Color color, double heightFactor, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 120 * heightFactor.clamp(0.04, 1.0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
            border: Border(top: BorderSide(color: color, width: 2)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
