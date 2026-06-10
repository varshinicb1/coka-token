import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/app_dialogs.dart';
import '../models/expense.dart';

class ExpensesScreen extends StatelessWidget {
  final AppProvider provider;

  const ExpensesScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = provider.expenses;
    final totalExpenses = expenses.fold<double>(
      0.0,
      (sum, e) => sum + e.amount,
    );

    return Scaffold(
      body: expenses.isEmpty
          ? _buildEmptyState(theme)
          : _buildContent(context, theme, expenses, totalExpenses),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddExpenseDialog(),
        ),
        backgroundColor: AppColors.cokaRed,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses recorded',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add an expense',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, List<Expense> expenses, double total) {
    final sorted = List<Expense>.from(expenses)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: StatCard(
            label: 'Total Expenses',
            value: '\u{20B9}${total.toStringAsFixed(2)}',
            icon: Icons.money_off,
            color: AppColors.cokaRed,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Expense Entries',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cokaRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sorted.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cokaRed,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: sorted.length,
            itemBuilder: (_, index) {
              final expense = sorted[index];
              return Dismissible(
                key: ValueKey(expense.id ?? expense.hashCode),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context, expense),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.description,
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                expense.dateString,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\u{20B9}${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cokaRed,
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

  Future<bool> _confirmDelete(BuildContext context, Expense expense) async {
    bool didConfirm = false;
    await showDialog(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: 'Delete Expense',
        message: 'Delete "${expense.description}" for \u{20B9}${expense.amount.toStringAsFixed(2)}?',
        onConfirm: () => didConfirm = true,
      ),
    );
    if (didConfirm) {
      await provider.deleteExpense(expense);
      return true;
    }
    return false;
  }
}
