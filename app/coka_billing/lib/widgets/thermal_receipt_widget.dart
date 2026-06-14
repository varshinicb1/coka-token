import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/order.dart';
import '../utils/cart_serializer.dart';
import '../utils/upi_qr.dart';
import '../theme/app_colors.dart';

class ThermalReceiptWidget extends StatelessWidget {
  final Order order;
  final bool compact;
  final String upiId;
  final String merchantName;

  const ThermalReceiptWidget({
    super.key,
    required this.order,
    this.compact = false,
    this.upiId = 'coka@upi',
    this.merchantName = 'COKA',
  });

  @override
  Widget build(BuildContext context) {
    final items = CartSerializer.deserialize(order.itemsText);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (order.isRefunded)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.errorRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('REFUNDED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          Container(
            padding: EdgeInsets.all(compact ? 8 : 12),
            decoration: BoxDecoration(
              color: AppColors.cokaRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text('COKA',
                    style: TextStyle(color: Colors.white, fontSize: compact ? 16 : 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                Text('COIMBATORE ORIGINAL KAALAN ADDA',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: compact ? 7 : 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24, vertical: compact ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Text('TOKEN #${order.tokenNumber}',
                    style: TextStyle(fontSize: compact ? 24 : 32, fontWeight: FontWeight.w900, color: order.isRefunded ? AppColors.errorRed : AppColors.cokaRed, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('${order.dateString}  |  ${_formatTime(order.timestamp)}',
                    style: TextStyle(fontSize: compact ? 9 : 10, color: Colors.grey[600])),
              ],
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Row(
            children: [
              Expanded(flex: 3, child: Text('Item', style: TextStyle(fontSize: compact ? 9 : 10, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
              Expanded(child: Text('Qty', style: TextStyle(fontSize: compact ? 9 : 10, fontWeight: FontWeight.bold, color: Colors.grey[600]), textAlign: TextAlign.center)),
              Expanded(child: Text('Rate', style: TextStyle(fontSize: compact ? 9 : 10, fontWeight: FontWeight.bold, color: Colors.grey[600]), textAlign: TextAlign.right)),
              Expanded(child: Text('Amt', style: TextStyle(fontSize: compact ? 9 : 10, fontWeight: FontWeight.bold, color: Colors.grey[600]), textAlign: TextAlign.right)),
            ],
          ),
          const Divider(thickness: 1),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(item.name, style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w500))),
                Expanded(child: Text('${item.quantity}', style: TextStyle(fontSize: compact ? 10 : 11), textAlign: TextAlign.center)),
                Expanded(child: Text('\u20B9${item.rate.toStringAsFixed(0)}', style: TextStyle(fontSize: compact ? 10 : 11), textAlign: TextAlign.right)),
                Expanded(child: Text('\u20B9${(item.rate * item.quantity).toStringAsFixed(0)}', style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
          )),
          const Divider(thickness: 1),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Subtotal', style: TextStyle(fontSize: 12)),
            Text('\u20B9${order.subTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('GST (5%)', style: TextStyle(fontSize: 12)),
            Text('\u20B9${order.taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const Divider(thickness: 2),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text('\u20B9${order.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: order.isRefunded ? AppColors.errorRed : theme.colorScheme.primary)),
          ]),
          const SizedBox(height: 8),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: buildUpiQrPayload(
                    upiId: upiId,
                    merchantName: merchantName,
                    amount: order.totalAmount,
                    transactionRef: 'TOKEN${order.tokenNumber}',
                  ),
                  version: QrVersions.auto,
                  size: compact ? 100 : 130,
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 6),
                Text('SCAN TO PAY', style: TextStyle(fontSize: compact ? 7 : 9, color: Colors.grey[500], letterSpacing: 2, fontWeight: FontWeight.bold)),
                Text('\u20B9${order.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: compact ? 10 : 12, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Thank you! Visit Again!',
              style: TextStyle(fontSize: compact ? 10 : 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          if (order.isRefunded)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('REFUNDED ORDER', style: TextStyle(fontSize: 9, color: AppColors.errorRed, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
