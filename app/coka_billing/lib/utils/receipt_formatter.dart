import '../models/order.dart';
import 'cart_serializer.dart';

class ReceiptFormatter {
  static List<String> generateReceiptLines(Order order) {
    final items = CartSerializer.deserialize(order.itemsText);
    final lines = <String>[];
    lines.add('##############################');
    lines.add('#    MARIO  x  COKA         #');
    lines.add('#  Coimbatore Original      #');
    lines.add('#  Kaalan Adda              #');
    lines.add('#  ${order.dateString}  ${_formatTime(order.timestamp)}  #');
    lines.add('##############################');
    lines.add('#      ★ TOKEN #${order.tokenNumber.padRight(10)}★     #');
    lines.add('##############################');
    lines.add('');
    lines.add('ITEM           QTY    AMOUNT');
    lines.add('~~~~  ~~~~  ~~~~  ~~~~~~~~');
    for (final item in items) {
      final name = item.name;
      final qtyStr = item.quantity.toString().padLeft(3);
      final amtStr = 'Rs.${(item.rate * item.quantity).toStringAsFixed(0).padLeft(5)}';
      if (name.length > 14) {
        lines.add(name);
        lines.add('${''.padRight(14)} $qtyStr  $amtStr');
      } else {
        lines.add('${name.padRight(14)} $qtyStr  $amtStr');
      }
    }
    lines.add('-----[#]-----[#]-----[#]-----');
    lines.add('Subtotal         Rs.${order.subTotal.toStringAsFixed(0).padLeft(7)}');
    lines.add('------------------------------');
    lines.add('TOTAL            Rs.${order.totalAmount.toStringAsFixed(0).padLeft(7)}');
    lines.add('------------------------------');
    lines.add('Payment: ${order.paymentMethod}');
    if (order.gatewayTransactionId != null) {
      lines.add('Txn: ${order.gatewayTransactionId}');
    }
    lines.add('------------------------------');
    lines.add('');
    lines.add('     ★ THANK YOU! ★');
    lines.add('   1-UP! VISIT AGAIN!');
    lines.add('##############################');
    lines.add('');
    return lines;
  }

  static List<String> generateKotLines(Order order) {
    final items = CartSerializer.deserialize(order.itemsText);
    final lines = <String>[];
    lines.add('##############################');
    lines.add('#      MARIO KITCHEN         #');
    lines.add('#  Coimbatore Original      #');
    lines.add('#  Kaalan Adda              #');
    lines.add('##############################');
    lines.add('#     ★ TOKEN #${order.tokenNumber.padRight(10)}★    #');
    lines.add('##############################');
    for (final item in items) {
      lines.add('${item.name} x${item.quantity}');
    }
    lines.add('-----[#]-----[#]-----[#]-----');
    lines.add(_formatTime(order.timestamp));
    lines.add('##############################');
    lines.add('');
    lines.add('');
    return lines;
  }

  static String _formatTime(int timestamp) {
    if (timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
