import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../widgets/app_dialogs.dart';

// =============================================================================
// BILLING SCREEN (Fully Functional)
// =============================================================================

class BillingScreen extends StatelessWidget {
  final AppProvider provider;
  const BillingScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showCartInline = constraints.maxWidth > 600;

        if (showCartInline) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildMenuPanel(context, theme)),
              SizedBox(
                width: 340,
                child: _buildCartPanel(context, theme),
              ),
            ],
          );
        }

        return Stack(
          children: [
            _buildMenuPanel(context, theme),
            Positioned(
              right: 16,
              bottom: 16,
              child: _buildCartFab(context, theme),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuPanel(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: provider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search menu items...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: provider.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => provider.setSearchQuery(''),
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        // Category filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: provider.categories.map((cat) {
              final selected = cat == provider.selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(cat, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                  selected: selected,
                  onSelected: (_) => provider.setSelectedCategory(cat),
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: theme.colorScheme.primary,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Menu items grid
        Expanded(
          child: provider.filteredMenuItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_menu, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text('No menu items found',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: provider.filteredMenuItems.length,
                      itemBuilder: (context, index) => _buildMenuItemCard(context, provider.filteredMenuItems[index], theme),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(BuildContext context, MenuItem item, ThemeData theme) {
    final inCart = provider.cart.any((c) => c.name == item.name);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => provider.addToCart(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(fontSize: 9, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\u20B9${item.rate.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: inCart ? AppColors.successGreen : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => provider.addToCart(item),
                      icon: Icon(inCart ? Icons.check : Icons.add, color: Colors.white),
                      iconSize: 18,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
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

  Widget _buildCartPanel(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.dividerTheme.color ?? Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerTheme.color ?? Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text('Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.cart.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (provider.cart.isNotEmpty)
                  TextButton(
                    onPressed: () => provider.clearCart(),
                    style: TextButton.styleFrom(foregroundColor: AppColors.errorRed, padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

          // Cart Items
          Expanded(
            child: provider.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_shopping_cart, size: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                        const SizedBox(height: 8),
                        Text('Cart is empty',
                            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                        const SizedBox(height: 4),
                        Text('Tap items to add',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: provider.cart.length,
                    itemBuilder: (context, index) => _buildCartItemRow(context, provider.cart[index], theme),
                  ),
          ),

          // Cart Summary + Checkout
          if (provider.cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerTheme.color ?? Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _summaryRow('Subtotal', provider.cartSubTotal, theme),
                  const SizedBox(height: 4),
                  _summaryRow('GST (5%)', provider.cartTaxAmount, theme),
                  Divider(color: theme.dividerTheme.color, height: 16),
                  _summaryRow('Total', provider.cartTotal, theme, bold: true, large: true),
                  const SizedBox(height: 12),

                  // Token Input
                  TextField(
                    controller: provider.tokenController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => provider.setTokenInput(v),
                    decoration: InputDecoration(
                      labelText: 'Token #',
                      prefixIcon: const Icon(Icons.confirmation_number, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment Method
                  Row(
                    children: [
                      Expanded(
                        child: _paymentChip(context, 'Cash', Icons.payments, AppColors.successGreen,
                            provider.selectedPaymentMethod == 'Cash', () => provider.setPaymentMethod('Cash')),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _paymentChip(context, 'UPI', Icons.qr_code, AppColors.upiBlue,
                            provider.selectedPaymentMethod == 'UPI', () => provider.setPaymentMethod('UPI')),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _paymentChip(context, 'Card', Icons.credit_card, AppColors.cokaAmber,
                            provider.selectedPaymentMethod == 'Card', () => provider.setPaymentMethod('Card')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Checkout Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: provider.cart.isEmpty ? null : () async {
                        await provider.checkout();
                        if (context.mounted && provider.activeOrderForReceipt != null) {
                          showDialog(
                            context: context,
                            builder: (_) => ReceiptActionsDialog(
                              order: provider.activeOrderForReceipt!,
                              provider: provider,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.receipt_long, size: 20),
                      label: Text(
                        'Checkout \u2022 \u20B9${provider.cartTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: AppColors.successGreen.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItemRow(BuildContext context, CartItem item, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('\u20B9${item.rate.toStringAsFixed(0)} each',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => provider.removeFromCart(item),
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: AppColors.errorRed,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: EdgeInsets.zero,
                  ),
                  SizedBox(
                    width: 28,
                    child: Text('${item.quantity}', textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  IconButton(
                    onPressed: () => provider.addToCart(
                      MenuItem(name: item.name, rate: item.rate, category: '', openingStock: 0),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: AppColors.successGreen,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: EdgeInsets.zero,
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      '\u20B9${item.total.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _paymentChip(BuildContext chipContext, String label, IconData icon, Color color, bool selected, VoidCallback onTap) {
    final chipTheme = Theme.of(chipContext);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : chipTheme.dividerTheme.color ?? Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: selected ? color : null),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? color : null)),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, ThemeData theme, {bool bold = false, bool large = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: large ? 15 : 12, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text('\u20B9${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: large ? 18 : 13,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              color: bold ? theme.colorScheme.primary : null,
            )),
      ],
    );
  }

  Widget _buildCartFab(BuildContext context, ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () => _showCartSheet(context),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.shopping_cart),
      label: Text('Cart (${provider.cart.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _showCartSheet(BuildContext context) {
    final theme = Theme.of(context);
    final screen = SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: _buildCartPanel(context, theme),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: screen),
          ],
        ),
      ),
    );
  }
}
