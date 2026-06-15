import '../models/order.dart';
import 'cart_serializer.dart';

class ReceiptFormatter {
  static List<String> generateReceiptLines(Order order) {
    final items = CartSerializer.deserialize(order.itemsText);
    final lines = <String>[];
    lines.add('==============================');
    lines.add('          COKA');
    lines.add('   Coimbatore Original');
    lines.add('     Kaalan Adda');
    lines.add('  ${order.dateString}  ${_formatTime(order.timestamp)}');
    lines.add('==============================');
    lines.add('       TOKEN #${order.tokenNumber}');
    lines.add('  ${order.tokenPhrase}');
    lines.add('==============================');
    lines.add('');
    lines.add('Item              Qty  Amt');
    for (final item in items) {
      final name = item.name;
      final rateLine = '${item.quantity.toString().padLeft(3)}  Rs.${(item.rate * item.quantity).toStringAsFixed(0).padLeft(5)}';
      if (name.length > 16) {
        lines.add(name);
        lines.add('${''.padRight(16)} $rateLine');
      } else {
        lines.add('${name.padRight(16)} $rateLine');
      }
    }
    lines.add('------------------------------');
    lines.add('Subtotal          Rs.${order.subTotal.toStringAsFixed(0).padLeft(7)}');
    lines.add('------------------------------');
    lines.add('TOTAL             Rs.${order.totalAmount.toStringAsFixed(0).padLeft(7)}');
    lines.add('------------------------------');
    lines.add('Payment: ${order.paymentMethod}');
    if (order.gatewayTransactionId != null) {
      lines.add('Txn: ${order.gatewayTransactionId}');
    }
    lines.add('------------------------------');
    lines.add('');
    lines.add('         Thank You!');
    lines.add('==============================');
    lines.add('');
    return lines;
  }

  static List<String> generateKotLines(Order order) {
    final items = CartSerializer.deserialize(order.itemsText);
    final lines = <String>[];
    lines.add('==============================');
    lines.add('      KITCHEN KOT');
    lines.add('   Coimbatore Original');
    lines.add('     Kaalan Adda');
    lines.add('==============================');
    lines.add('      TOKEN #${order.tokenNumber}');
    lines.add('  ${order.tokenPhrase}');
    lines.add('------------------------------');
    for (final item in items) {
      lines.add('${item.name} x${item.quantity}');
    }
    lines.add('------------------------------');
    lines.add(_formatTime(order.timestamp));
    lines.add('------------------------------');
    lines.add('         *** KOT ***');
    lines.add('==============================');
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
