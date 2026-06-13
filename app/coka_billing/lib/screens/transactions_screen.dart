import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/app_dialogs.dart';
import '../utils/date_utils.dart' as date_utils;

class TransactionsScreen extends StatefulWidget {
  final AppProvider provider;

  const TransactionsScreen({super.key, required this.provider});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  AppProvider get provider => widget.provider;
  final _searchController = TextEditingController();
  String _paymentFilter = 'All';
  String _dateFilter = 'Today';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Order> get _filteredOrders {
    var orders = provider.orders;

    if (_dateFilter == 'Today') {
      final today = date_utils.DateUtils.getTodayDateString();
      orders = orders.where((o) => o.dateString == today).toList();
    } else if (_dateFilter == 'This Week') {
      final weekDates = <String>{};
      for (int i = 0; i < 7; i++) {
        final d = DateTime.now().subtract(Duration(days: i));
        weekDates.add('${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      }
      orders = orders.where((o) => weekDates.contains(o.dateString)).toList();
    }

    if (_paymentFilter != 'All') {
      orders = orders.where((o) => o.paymentMethod == _paymentFilter).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      orders = orders.where((o) =>
        o.tokenNumber.toLowerCase().contains(query) ||
        o.itemsText.toLowerCase().contains(query) ||
        o.operatorName.toLowerCase().contains(query)
      ).toList();
    }

    return orders..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = _filteredOrders;
    final todayTotal = orders.where((o) => !o.isRefunded).fold(0.0, (s, o) => s + o.totalAmount);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.cokaRed.withValues(alpha: 0.1), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  label: _dateFilter == 'Today' ? "Today's Sales" : 'Filtered Sales',
                  icon: Icons.today,
                  value: '\u20B9${todayTotal.toStringAsFixed(0)}',
                  color: AppColors.cokaRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Orders',
                  icon: Icons.receipt,
                  value: '${orders.length}',
                  color: AppColors.cokaAmber,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by token, item, or staff...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() {}); })
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _filterChip('Today', theme, _dateFilter == 'Today'),
              _filterChip('This Week', theme, _dateFilter == 'This Week'),
              _filterChip('All Time', theme, _dateFilter == 'All Time'),
              const SizedBox(width: 8),
              _filterChip('All', theme, _paymentFilter == 'All'),
              _filterChip('Cash', theme, _paymentFilter == 'Cash'),
              _filterChip('UPI', theme, _paymentFilter == 'UPI'),
              _filterChip('Card', theme, _paymentFilter == 'Card'),
            ],
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                      const SizedBox(height: 12),
                      Text('No orders found', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => ReceiptActionsDialog(order: order, provider: provider),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: order.isRefunded
                                      ? AppColors.errorRed.withValues(alpha: 0.1)
                                      : AppColors.cokaRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text('#${order.tokenNumber}',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14,
                                          color: order.isRefunded ? AppColors.errorRed : AppColors.cokaRed)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.itemsText.replaceAll('*', ' x ').replaceAll('|', ', '),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${order.dateString} | ${order.paymentMethod} | ${order.operatorName}${order.isRefunded ? ' | REFUNDED' : ''}',
                                      style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                    ),
                                  ],
                                ),
                              ),
                              Text('\u20B9${order.totalAmount.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16,
                                      color: order.isRefunded ? AppColors.errorRed : AppColors.cokaRed)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, ThemeData theme, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        selected: selected,
        onSelected: (_) {
          setState(() {
            if (label == 'Today' || label == 'This Week' || label == 'All Time') {
              _dateFilter = label;
            } else {
              _paymentFilter = label;
            }
          });
        },
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        checkmarkColor: theme.colorScheme.primary,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
