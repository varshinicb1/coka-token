import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order.dart';

class CsvExportService {
  static Future<String> exportOrders(List<Order> orders) async {
    if (orders.isEmpty) return 'No orders to export';

    final header = ['Order ID', 'Token', 'Items', 'SubTotal', 'GST Tax', 'Total', 'Payment Method', 'Date', 'Operator', 'Refunded', 'Gateway Txn ID'];
    final rows = <List<String>>[header];

    for (final o in orders) {
      rows.add([
        o.id.toString(),
        o.tokenNumber,
        o.itemsText.replaceAll('|', '; ').replaceAll('*', ' x '),
        o.subTotal.toStringAsFixed(2),
        o.taxAmount.toStringAsFixed(2),
        o.totalAmount.toStringAsFixed(2),
        o.paymentMethod,
        o.dateString,
        o.operatorName,
        o.isRefunded ? 'Yes' : 'No',
        o.gatewayTransactionId ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final filename = 'COKA_Sales_Export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);

    try {
      await Share.shareXFiles([XFile(file.path)], text: 'COKA Sales Export');
    } catch (_) {}

    return 'CSV exported: $filename';
  }
}
