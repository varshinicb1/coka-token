import 'package:flutter_test/flutter_test.dart';
import 'package:coka_billing/models/order.dart';
import 'package:coka_billing/utils/receipt_formatter.dart';

Order _createOrder({
  int id = 1,
  String token = 'A1',
  String itemsText = 'Item1*2*100*1',
  double subTotal = 200.0,
  double taxAmount = 0.0,
  double totalAmount = 200.0,
  String paymentMethod = 'Cash',
  String dateString = '2024-01-15',
  int timestamp = 1705315200000,
  String operatorName = 'TestOp',
  bool isRefunded = false,
  String? gatewayTxnId,
}) {
  return Order(
    id: id,
    tokenNumber: token,
    itemsText: itemsText,
    subTotal: subTotal,
    taxAmount: taxAmount,
    totalAmount: totalAmount,
    paymentMethod: paymentMethod,
    dateString: dateString,
    timestamp: timestamp,
    operatorName: operatorName,
    isRefunded: isRefunded,
    gatewayTransactionId: gatewayTxnId,
  );
}

void main() {
  group('ReceiptFormatter', () {
    group('generateReceiptLines', () {
      test('includes COKA header', () {
        final order = _createOrder();
        final lines = ReceiptFormatter.generateReceiptLines(order);
        expect(lines[0], '==============================');
        expect(lines[1], '          COKA');
        expect(lines[2], '   Coimbatore Original');
        expect(lines[3], '     Kaalan Adda');
      });

      test('includes token number', () {
        final order = _createOrder(token: 'B3');
        final lines = ReceiptFormatter.generateReceiptLines(order);
        expect(lines, contains(contains('TOKEN #B3')));
      });

      test('includes date and time', () {
        final order = _createOrder(dateString: '2024-06-01', timestamp: 1717248000000);
        final lines = ReceiptFormatter.generateReceiptLines(order);
        expect(lines, contains(contains('2024-06-01')));
      });

      test('lists each item with name, qty, and amount', () {
        final order = _createOrder(itemsText: 'Burger*3*150*1|Fries*2*80*2');
        final lines = ReceiptFormatter.generateReceiptLines(order);
        final itemLine = lines.firstWhere((l) => l.contains('Burger'));
        expect(itemLine, contains('3'));
        expect(itemLine, contains('450'));
        final friesLine = lines.firstWhere((l) => l.contains('Fries'));
        expect(friesLine, contains('2'));
        expect(friesLine, contains('160'));
      });

      test('wraps long item names to next line', () {
        final order = _createOrder(itemsText: 'ExtraLongBurgerName*1*100*1');
        final lines = ReceiptFormatter.generateReceiptLines(order);
        final nameLine = lines.firstWhere((l) => l.contains('ExtraLongBurgerName'));
        expect(nameLine, 'ExtraLongBurgerName');
      });

      test('includes subtotal and total', () {
        final order = _createOrder(subTotal: 500.0, totalAmount: 500.0);
        final lines = ReceiptFormatter.generateReceiptLines(order);
        expect(lines, contains(contains('Subtotal')));
        expect(lines, contains(contains('TOTAL')));
      });

      test('does not include operator name', () {
        final order = _createOrder(operatorName: 'John');
        final lines = ReceiptFormatter.generateReceiptLines(order);
        expect(lines.where((l) => l.contains('John')).length, 0);
      });

      test('includes payment method', () {
        final order = _createOrder(paymentMethod: 'UPI');
        final lines = ReceiptFormatter.generateReceiptLines(order);
        expect(lines, contains(contains('Payment: UPI')));
      });

      test('includes gateway txn id when present', () {
        final order = _createOrder(gatewayTxnId: 'TXN123');
        final lines = ReceiptFormatter.generateReceiptLines(order);
        expect(lines, contains(contains('Txn: TXN123')));
      });

      test('does not include txn line when missing', () {
        final order = _createOrder();
        final lines = ReceiptFormatter.generateReceiptLines(order);
        expect(lines.where((l) => l.contains('Txn:')).length, 0);
      });

      test('includes Thank You footer', () {
        final order = _createOrder();
        final lines = ReceiptFormatter.generateReceiptLines(order);
        expect(lines, contains(contains('Thank You')));
      });

      test('returns consistent line count', () {
        final order = _createOrder(itemsText: 'A*1*10*1|B*2*20*2');
        final lines = ReceiptFormatter.generateReceiptLines(order);
        expect(lines.length, 24);
      });
    });

    group('generateKotLines', () {
      test('includes KOT header', () {
        final order = _createOrder();
        final lines = ReceiptFormatter.generateKotLines(order);
        expect(lines[1], '      KITCHEN KOT');
      });

      test('includes token number', () {
        final order = _createOrder(token: 'C5');
        final lines = ReceiptFormatter.generateKotLines(order);
        expect(lines, contains(contains('TOKEN #C5')));
      });

      test('lists each item with qty', () {
        final order = _createOrder(itemsText: 'Paneer*2*120*1|Naan*3*40*2');
        final lines = ReceiptFormatter.generateKotLines(order);
        final paneerLine = lines.firstWhere((l) => l.contains('Paneer'));
        expect(paneerLine, contains('x2'));
        final naanLine = lines.firstWhere((l) => l.contains('Naan'));
        expect(naanLine, contains('x3'));
      });

      test('does not truncate long names', () {
        final order = _createOrder(itemsText: 'VeryLongItemNameHere*1*100*1');
        final lines = ReceiptFormatter.generateKotLines(order);
        final itemLine = lines.firstWhere((l) => l.contains('VeryLongItemNameHere'));
        expect(itemLine, 'VeryLongItemNameHere x1');
      });

      test('ends with border', () {
        final order = _createOrder();
        final lines = ReceiptFormatter.generateKotLines(order);
        expect(lines, contains(contains('==============================')));
      });
    });
  });
}
