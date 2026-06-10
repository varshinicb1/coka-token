import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/coka_logo_badge.dart';
import '../widgets/thermal_receipt_widget.dart';
import '../screens/billing_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/users_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/reconciliation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _showingReceipt = false;

  static const _navItems = <_NavItem>[
    _NavItem(Icons.shopping_cart, 'Billing'),
    _NavItem(Icons.receipt_long, 'Transactions'),
    _NavItem(Icons.bar_chart, 'Reports'),
    _NavItem(Icons.inventory_2, 'Inventory'),
    _NavItem(Icons.money_off, 'Expenses'),
    _NavItem(Icons.people, 'Users'),
    _NavItem(Icons.settings, 'Settings'),
    _NavItem(Icons.account_balance, 'Reconciliation'),
  ];



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkReceipt();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkReceipt();
  }

  void _checkReceipt() {
    final provider = context.read<AppProvider>();
    if (provider.activeOrderForReceipt != null && !_showingReceipt) {
      _showingReceipt = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showReceiptDialog(provider));
    }
    if (provider.activeOrderForReceipt == null) {
      _showingReceipt = false;
    }
  }

  void _showReceiptDialog(AppProvider provider) {
    if (!mounted || provider.activeOrderForReceipt == null) return;
    final order = provider.activeOrderForReceipt!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ThermalReceiptWidget(order: order),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await provider.printOrderReceipt(order);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Receipt sent to printer')),
                      );
                    }
                  },
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print Receipt'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        provider.clearActiveReceipt();
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await provider.printOrderReceipt(order);
                        provider.clearActiveReceipt();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print & Close'),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;

        return Scaffold(
          appBar: _buildAppBar(provider, theme, isWide),
          body: SafeArea(
            child: isWide
                ? _buildWideLayout(provider, theme)
                : _buildNarrowLayout(provider, theme),
          ),
          bottomNavigationBar: isWide ? null : _buildBottomNav(theme),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(AppProvider provider, ThemeData theme, bool isWide) {
    return AppBar(
      title: Row(
        children: [
          const CokaLogoBadge(size: 32),
          const SizedBox(width: 10),
          const Text(
            'COKA BILLING',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
          ),
          if (isWide) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                provider.currentUser?.role ?? 'STAFF',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ),
          ],
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            provider.isCloudSynced ? Icons.cloud_done : Icons.cloud_off,
            color: provider.isCloudSynced ? AppColors.successGreen : AppColors.cokaAmber,
            size: 20,
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') provider.logout();
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.currentUser?.username ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(provider.currentUser?.role ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      )),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Text(
              (provider.currentUser?.username.isNotEmpty == true
                      ? provider.currentUser!.username[0].toUpperCase()
                      : 'U'),
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWideLayout(AppProvider provider, ThemeData theme) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          labelType: NavigationRailLabelType.all,
          destinations: _buildNavDestinations(),
          backgroundColor: theme.colorScheme.surface,
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _buildContent(provider, theme)),
      ],
    );
  }

  Widget _buildNarrowLayout(AppProvider provider, ThemeData theme) {
    return _buildContent(provider, theme);
  }

  BottomNavigationBar _buildBottomNav(ThemeData theme) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: _navItems.asMap().entries.map((entry) {
        final item = entry.value;
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }

  List<NavigationRailDestination> _buildNavDestinations() {
    return _navItems.map((item) {
      return NavigationRailDestination(
        icon: Icon(item.icon),
        selectedIcon: Icon(item.icon),
        label: Text(item.label, style: const TextStyle(fontSize: 11)),
      );
    }).toList();
  }

  Widget _buildContent(AppProvider provider, ThemeData theme) {

    switch (_selectedIndex) {
      case 0: return BillingScreen(provider: provider);
      case 1: return TransactionsScreen(provider: provider);
      case 2: return ReportsScreen(provider: provider);
      case 3: return InventoryScreen(provider: provider);
      case 4: return ExpensesScreen(provider: provider);
      case 5: return UsersScreen(provider: provider);
      case 6: return SettingsScreen(provider: provider);
      case 7: return BankReconciliationScreen(provider: provider);
      default: return BillingScreen(provider: provider);
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
