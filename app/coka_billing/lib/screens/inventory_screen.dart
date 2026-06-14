import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/app_dialogs.dart';
import '../models/menu_item.dart';

class InventoryScreen extends StatelessWidget {
  final AppProvider provider;

  const InventoryScreen({super.key, required this.provider});

  int get _lowStockCount => provider.menuItems.where((e) => e.remainingStock > 0 && e.remainingStock <= 5).length;

  int get _outOfStockCount => provider.menuItems.where((e) => e.remainingStock <= 0).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = provider.menuItems;

    return Scaffold(
      body: Column(
        children: [
          _buildStatsRow(theme),
          Expanded(child: items.isEmpty ? _buildEmptyState(context, theme) : _buildList(context, theme, items)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.cokaRed,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Total Items',
              value: '${provider.menuItems.length}',
              icon: Icons.inventory_2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              label: 'Low Stock',
              value: '$_lowStockCount',
              icon: Icons.warning_amber_rounded,
              color: AppColors.cokaAmber,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              label: 'Out of Stock',
              value: '$_outOfStockCount',
              icon: Icons.highlight_off,
              color: AppColors.cokaRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Inventory is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first menu item',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, ThemeData theme, List<MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Inventory List',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${items.length} item${items.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildItemCard(context, theme, items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, ThemeData theme, MenuItem item) {
    final progress = item.openingStock > 0 ? (item.remainingStock / item.openingStock).clamp(0.0, 1.0) : 0.0;

    final (String badgeText, Color badgeColor, Color badgeBg) = switch (item.remainingStock) {
      <= 0 => ('Out', AppColors.cokaRed, AppColors.cokaRed.withValues(alpha: 0.12)),
      <= 5 => ('Low', AppColors.cokaAmber, AppColors.cokaAmber.withValues(alpha: 0.12)),
      _ => ('OK', AppColors.successGreen, AppColors.successGreen.withValues(alpha: 0.12)),
    };

    final progressColor = switch (item.remainingStock) {
      <= 0 => AppColors.cokaRed,
      <= 5 => AppColors.cokaAmber,
      _ => AppColors.successGreen,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () => _showItemActions(context, item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + stock badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(progressColor),
                ),
              ),
              const SizedBox(height: 8),
              // Bottom row: rate/category + stock count
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 2),
                  Text(
                    item.rate.toStringAsFixed(2),
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.category_outlined, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      item.category,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.inventory, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 2),
                  Text(
                    '${item.remainingStock}/${item.openingStock}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AddMenuItemDialog(),
    );
  }

  void _showItemActions(BuildContext context, MenuItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          item.name,
          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Stock: ${item.remainingStock}/${item.openingStock}\nRate: \u20B9${item.rate.toStringAsFixed(2)}',
          style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              showDialog(
                context: context,
                builder: (_) => AddMenuItemDialog(existingItem: item),
              );
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AppProvider>().quickRestock(item);
            },
            child: Text(
              'Restock',
              style: TextStyle(color: AppColors.successGreen),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              showDialog(
                context: context,
                builder: (_) => ConfirmActionDialog(
                  title: 'Delete Item',
                  message: 'Are you sure you want to delete "${item.name}"?',
                  onConfirm: () => context.read<AppProvider>().deleteMenuItem(item),
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.cokaRed),
            ),
          ),
        ],
      ),
    );
  }
}
