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
    final marioRed = const Color(0xFFE52521);
    final marioGreen = const Color(0xFF049B4A);
    final marioYellow = const Color(0xFFFBD000);
    final marioBlue = const Color(0xFF0052CC);

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: marioRed, width: 2),
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
              gradient: LinearGradient(
                colors: [marioRed, marioRed.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: marioRed.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: marioYellow, size: compact ? 16 : 20),
                    const SizedBox(width: 6),
                    Text('MARIO x COKA',
                        style: TextStyle(color: Colors.white, fontSize: compact ? 14 : 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(width: 6),
                    Icon(Icons.star, color: marioYellow, size: compact ? 16 : 20),
                  ],
                ),
                const SizedBox(height: 2),
                Text('COIMBATORE ORIGINAL',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: compact ? 7 : 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text('KAALAN ADDA',
                    style: TextStyle(color: marioYellow, fontSize: compact ? 7 : 9, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ],
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24, vertical: compact ? 8 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [marioBlue.withValues(alpha: 0.08), marioGreen.withValues(alpha: 0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: marioBlue.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(compact ? 3 : 4),
                      decoration: BoxDecoration(
                        color: marioYellow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.star, color: marioRed, size: compact ? 12 : 14),
                    ),
                    const SizedBox(width: 8),
                    Text('TOKEN #${order.tokenNumber}',
                        style: TextStyle(fontSize: compact ? 22 : 30, fontWeight: FontWeight.w900, color: marioRed, letterSpacing: 1)),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.all(compact ? 3 : 4),
                      decoration: BoxDecoration(
                        color: marioYellow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.star, color: marioRed, size: compact ? 12 : 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${order.dateString}  |  ${_formatTime(order.timestamp)}',
                    style: TextStyle(fontSize: compact ? 9 : 10, color: Colors.grey[600])),
              ],
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: marioGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('ITEM', style: TextStyle(fontSize: compact ? 8 : 9, fontWeight: FontWeight.w900, color: marioGreen, letterSpacing: 1))),
                Expanded(child: Text('QTY', style: TextStyle(fontSize: compact ? 8 : 9, fontWeight: FontWeight.w900, color: marioGreen, letterSpacing: 1), textAlign: TextAlign.center)),
                Expanded(child: Text('RATE', style: TextStyle(fontSize: compact ? 8 : 9, fontWeight: FontWeight.w900, color: marioGreen, letterSpacing: 1), textAlign: TextAlign.right)),
                Expanded(child: Text('AMT', style: TextStyle(fontSize: compact ? 8 : 9, fontWeight: FontWeight.w900, color: marioGreen, letterSpacing: 1), textAlign: TextAlign.right)),
              ],
            ),
          ),
          Divider(color: marioYellow.withValues(alpha: 0.5), thickness: 1.5),
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
          Divider(color: marioYellow.withValues(alpha: 0.5), thickness: 1.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.arrow_forward_ios, color: marioGreen, size: 10),
              const Text('Subtotal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('\u20B9${order.subTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(Icons.arrow_back_ios, color: marioGreen, size: 10),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [marioRed, marioRed.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: marioRed.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                Row(
                  children: [
                    Icon(Icons.star, color: marioYellow, size: 14),
                    const SizedBox(width: 4),
                    Text('\u20B9${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(width: 4),
                    Icon(Icons.star, color: marioYellow, size: 14),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: marioGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: marioGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.credit_card, color: marioBlue, size: 14),
                Text(order.paymentMethod, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: marioBlue)),
                if (order.gatewayTransactionId != null)
                  Text('Txn: ${order.gatewayTransactionId}', style: TextStyle(fontSize: 8, color: Colors.grey[500])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: marioGreen.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: marioGreen.withValues(alpha: 0.15)),
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
                Text('SCAN TO PAY', style: TextStyle(fontSize: compact ? 7 : 9, color: marioGreen, letterSpacing: 2, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: marioYellow, size: compact ? 10 : 12),
                    const SizedBox(width: 4),
                    Text('\u20B9${order.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: compact ? 10 : 12, fontWeight: FontWeight.w700, color: marioRed)),
                    const SizedBox(width: 4),
                    Icon(Icons.star, color: marioYellow, size: compact ? 10 : 12),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [marioRed.withValues(alpha: 0.9), marioRed.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: marioYellow, size: compact ? 12 : 14),
                    const SizedBox(width: 6),
                    Text('1-UP! THANK YOU!', style: TextStyle(fontSize: compact ? 11 : 13, fontWeight: FontWeight.w900, color: marioYellow, letterSpacing: 1)),
                    const SizedBox(width: 6),
                    Icon(Icons.star, color: marioYellow, size: compact ? 12 : 14),
                  ],
                ),
                Text('GAME OVER - VISIT AGAIN', style: TextStyle(fontSize: compact ? 8 : 9, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 2)),
              ],
            ),
          ),
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
