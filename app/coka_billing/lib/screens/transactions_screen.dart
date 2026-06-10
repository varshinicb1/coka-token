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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = provider.orders;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cokaRed.withValues(alpha: 0.1),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  label: "Today's Sales",
                  icon: Icons.today,
                  value: '\u20B9${orders.where((o) => o.dateString == date_utils.DateUtils.getTodayDateString() && !o.isRefunded).fold(0.0, (s, o) => s + o.totalAmount).toStringAsFixed(0)}',
                  color: AppColors.cokaRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Total Orders',
                  icon: Icons.receipt,
                  value: '${orders.length}',
                  color: AppColors.cokaAmber,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Recent Orders',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${orders.length} total',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No orders yet',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders.reversed.toList()[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => ReceiptActionsDialog(
                              order: order,
                              provider: provider,
                            ),
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
                                  child: Text(
                                    '#${order.tokenNumber}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: order.isRefunded
                                          ? AppColors.errorRed
                                          : AppColors.cokaRed,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.itemsText
                                          .replaceAll('*', ' x ')
                                          .replaceAll('|', ', '),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${order.dateString} | ${order.paymentMethod}${order.isRefunded ? ' | REFUNDED' : ''}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\u20B9${order.totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: order.isRefunded
                                      ? AppColors.errorRed
                                      : AppColors.cokaRed,
                                ),
                              ),
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
}
