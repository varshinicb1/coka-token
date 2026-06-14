import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/coka_logo_badge.dart';
import '../screens/billing_screen.dart';
import '../screens/bluetooth_pairing_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/users_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/reconciliation_screen.dart';
import '../screens/customer_display_screen.dart';
import '../utils/date_utils.dart' as date_utils;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  static const _navItems = <_NavItem>[
    _NavItem(Icons.dashboard, 'Home'),
    _NavItem(Icons.shopping_cart, 'Billing'),
    _NavItem(Icons.receipt_long, 'Transactions'),
    _NavItem(Icons.bar_chart, 'Reports'),
    _NavItem(Icons.inventory_2, 'Inventory'),
    _NavItem(Icons.money_off, 'Expenses'),
    _NavItem(Icons.people, 'Users'),
    _NavItem(Icons.settings, 'Settings'),
    _NavItem(Icons.account_balance, 'Reconciliation'),
    _NavItem(Icons.tv, 'Customer'),
  ];

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
        if (provider.btService.isSupported)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: Icon(
                provider.bluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: provider.bluetoothConnected
                    ? AppColors.successGreen
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              tooltip: provider.bluetoothConnected ? 'Bluetooth Connected' : 'Pair Bluetooth Printer',
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BluetoothPairingScreen(),
                  ),
                );
                if (result == true && context.mounted) {
                  provider.setBluetoothConnected(true);
                }
              },
            ),
          ),
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
    final items = _navItems.sublist(0, 5);
    return BottomNavigationBar(
      currentIndex: _selectedIndex < 5 ? _selectedIndex : 0,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: items.asMap().entries.map((entry) {
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
      case 0: return _buildHomeScreen(provider, theme);
      case 1: return BillingScreen(provider: provider);
      case 2: return TransactionsScreen(provider: provider);
      case 3: return ReportsScreen(provider: provider);
      case 4: return InventoryScreen(provider: provider);
      case 5: return ExpensesScreen(provider: provider);
      case 6: return UsersScreen(provider: provider);
      case 7: return SettingsScreen(provider: provider);
      case 8: return BankReconciliationScreen(provider: provider);
      case 9: return CustomerDisplayScreen(provider: provider);
      default: return _buildHomeScreen(provider, theme);
    }
  }

  Widget _buildHomeScreen(AppProvider provider, ThemeData theme) {
    final today = date_utils.DateUtils.getTodayDateString();
    final todayRevenue = provider.orders
      .where((o) => o.dateString == today && !o.isRefunded)
      .fold(0.0, (s, o) => s + o.totalAmount);
    final bestSellers = provider.getBestSellers(limit: 3, period: today);
    final lowStock = provider.getLowStockItems();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cokaRed, AppColors.cokaRed.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today\'s Revenue', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                const SizedBox(height: 4),
                Text('\u20B9${todayRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 8),
                Text('${provider.todayOrderCount} orders today',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _quickActionCard(context, Icons.shopping_cart, 'Billing', AppColors.cokaRed, () => setState(() => _selectedIndex = 1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionCard(context, Icons.receipt_long, 'Orders', AppColors.cokaAmber, () => setState(() => _selectedIndex = 2)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionCard(context, Icons.bar_chart, 'Reports', AppColors.successGreen, () => setState(() => _selectedIndex = 3)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionCard(context, Icons.inventory_2, 'Stock', AppColors.upiBlue, () => setState(() => _selectedIndex = 4)),
              ),
            ],
          ),
          if (lowStock.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cokaAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cokaAmber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.cokaAmber, size: 20),
                      const SizedBox(width: 8),
                      Text('Low Stock Alerts', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.cokaAmber)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...lowStock.take(5).map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(item['name'] as String, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text('${item['remaining']}/${item['opening']}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.cokaAmber, fontSize: 13)),
                        ],
                      ),
                  )),
                ],
              ),
            ),
          ],
          if (bestSellers.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Today\'s Best Sellers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            ...bestSellers.asMap().entries.map((entry) {
              final item = entry.value;
              final rank = entry.key + 1;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: rank <= 3 ? AppColors.cokaRed : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: Text('$rank',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                                color: rank <= 3 ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      Text('${item['quantity']} sold',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(width: 12),
                      Text('\u20B9${(item['revenue'] as double).toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.cokaRed)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _quickActionCard(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
