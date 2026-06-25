import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../utils/cart_serializer.dart';

class PdfReceiptService {
  static Future<File?> generateReceiptPdf(Order order) async {
    final items = CartSerializer.deserialize(order.itemsText);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('COKA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Coimbatore Original'),
            pw.Text('Kaalan Adda'),
            pw.Text('${order.dateString}  ${_formatTime(order.timestamp)}', style: const pw.TextStyle(fontSize: 9)),
            pw.Divider(),
            pw.Text('TOKEN #${order.tokenNumber}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text(order.tokenPhrase, style: const pw.TextStyle(fontSize: 10)),
            pw.Divider(),
            if (order.offerName != null) ...[
              pw.Text(' ** ${order.offerName} **', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
              pw.Text('    BUY 2 GET 1 FREE!', style: pw.TextStyle(color: PdfColors.orange)),
              pw.SizedBox(height: 4),
            ],
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Qty  Amt', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ],
            ),
            pw.Divider(thickness: 0.5),
            ...items.map((item) {
              final isFree = item.rate == 0;
              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(item.name.length > 20 ? '${item.name.substring(0, 20)}...' : item.name, style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    isFree ? 'FREE' : '${item.quantity}  Rs.${(item.rate * item.quantity).toStringAsFixed(0)}',
                    style: pw.TextStyle(fontSize: 9, color: isFree ? PdfColors.green : null),
                  ),
                ],
              );
            }),
            pw.Divider(thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Rs.${order.subTotal.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            if (order.discountAmount > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('B2G1 Discount', style: pw.TextStyle(fontSize: 10, color: PdfColors.green)),
                  pw.Text('-Rs.${order.discountAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, color: PdfColors.green)),
                ],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('Rs.${order.totalAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Divider(),
            pw.Text('Payment: ${order.paymentMethod}', style: const pw.TextStyle(fontSize: 9)),
            if (order.gatewayTransactionId != null)
              pw.Text('Txn: ${order.gatewayTransactionId}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 8),
            pw.Text('Thank You!', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    try {
      final dir = kIsWeb ? Directory.systemTemp : await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/receipt_${order.tokenNumber}_${order.timestamp}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> sharePdf(Order order) async {
    final file = await generateReceiptPdf(order);
    if (file == null) return false;
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'COKA Receipt #${order.tokenNumber}'),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static String _formatTime(int timestamp) {
    if (timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
