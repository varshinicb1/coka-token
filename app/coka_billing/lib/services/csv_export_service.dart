import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order.dart';

final _log = Logger('CsvExportService');

class CsvExportService {
  static Future<String> exportOrders(List<Order> orders) async {
    if (orders.isEmpty) return 'No orders to export';

    final header = ['Order ID', 'Token', 'Items', 'SubTotal', 'Total', 'Payment Method', 'Date', 'Operator', 'Refunded', 'Gateway Txn ID'];
    final rows = <List<String>>[header];

    for (final o in orders) {
      rows.add([
        o.id.toString(),
        o.tokenNumber,
        o.itemsText.replaceAll('|', '; ').replaceAll('*', ' x '),
        o.subTotal.toStringAsFixed(2),
        o.totalAmount.toStringAsFixed(2),
        o.paymentMethod,
        o.dateString,
        o.operatorName,
        o.isRefunded ? 'Yes' : 'No',
        o.gatewayTransactionId ?? '',
      ]);
    }

    final csv = const CsvEncoder().convert(rows);
    final bytes = utf8.encode(csv);

    final filename = 'COKA_Sales_Export_${DateTime.now().millisecondsSinceEpoch}.csv';

    try {
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: filename, mimeType: 'text/csv')],
        text: 'COKA Sales Export',
      );
    } catch (e, st) {
      _log.warning('CSV share failed', e, st);
    }

    return 'CSV exported: $filename';
  }
}
