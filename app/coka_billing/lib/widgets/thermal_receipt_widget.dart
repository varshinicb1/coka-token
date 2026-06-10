import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/cart_serializer.dart';
import '../theme/app_colors.dart';

class ThermalReceiptWidget extends StatelessWidget {
  final Order order;

  const ThermalReceiptWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final items = CartSerializer.deserialize(order.itemsText);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cokaRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'COKA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'COIMBATORE ORIGINAL KAALAN ADDA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Token Number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Text(
                  'TOKEN #${order.tokenNumber}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.cokaRed,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.dateString}  |  ${_formatTime(order.timestamp)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Items Table Header
          Row(
            children: [
              Expanded(flex: 3, child: Text('Item', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
              Expanded(child: Text('Qty', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]), textAlign: TextAlign.center)),
              Expanded(child: Text('Rate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]), textAlign: TextAlign.right)),
              Expanded(child: Text('Amt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]), textAlign: TextAlign.right)),
            ],
          ),
          const Divider(thickness: 1),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                Expanded(child: Text('${item.quantity}', style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                Expanded(child: Text('₹${item.rate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                Expanded(child: Text('₹${(item.rate * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
          )),
          const Divider(thickness: 1),

          // Totals
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Subtotal', style: TextStyle(fontSize: 12)),
            Text('₹${order.subTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('GST (5%)', style: TextStyle(fontSize: 12)),
            Text('₹${order.taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const Divider(thickness: 2),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text('₹${order.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
          ]),
          const SizedBox(height: 8),

          // Payment Info
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment: ${order.paymentMethod}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                if (order.gatewayTransactionId != null)
                  Text('Txn: ${order.gatewayTransactionId}', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Footer
          Text(
            'Thank you! Visit Again!',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            'Operator: ${order.operatorName}',
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
