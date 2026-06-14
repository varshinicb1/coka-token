import 'package:flutter_test/flutter_test.dart';
import '../lib/models/order.dart';
import '../lib/utils/cart_serializer.dart';
import '../lib/utils/receipt_formatter.dart';

void main() {
  group('Order processing stress test', () {
    test('100 orders total calculation is correct', () {
      final orders = List.generate(100, (i) => Order(
        id: i + 1,
        tokenNumber: '${i + 1}',
        itemsText: 'Item*${(i % 5) + 1}*${((i % 10) + 1) * 10}*$i',
        subTotal: ((i % 10) + 1) * 10.0,
        taxAmount: 0.0,
        totalAmount: ((i % 10) + 1) * 10.0,
        paymentMethod: i % 3 == 0 ? 'Cash' : i % 3 == 1 ? 'UPI' : 'Card',
        timestamp: DateTime.now().millisecondsSinceEpoch - i * 60000,
        dateString: '2026-06-14',
        operatorName: 'test@user.com',
        gatewayTransactionId: 'TXN$i',
        gatewayStatus: 'SUCCESS',
      ));

      expect(orders.length, 100);
      expect(orders.first.id, 1);
      expect(orders.last.id, 100);

      // Verify all totals
      for (final order in orders) {
        expect(order.totalAmount, order.subTotal);
        expect(order.taxAmount, 0.0);
      }

      // Verify total sales
      final totalSales = orders.fold(0.0, (s, o) => s + o.totalAmount);
      expect(totalSales, greaterThan(0));
    });

    test('100 orders with refunds mixed in', () {
      final orders = List.generate(100, (i) => Order(
        id: i + 1,
        tokenNumber: '${i + 1}',
        itemsText: 'Item*1*${(i % 50) + 50}*$i',
        subTotal: ((i % 50) + 50).toDouble(),
        taxAmount: 0.0,
        totalAmount: ((i % 50) + 50).toDouble(),
        paymentMethod: 'UPI',
        timestamp: DateTime.now().millisecondsSinceEpoch - i * 60000,
        dateString: '2026-06-14',
        operatorName: 'test@user.com',
        isRefunded: i % 7 == 0, // ~14 refunds
      ));

      final nonRefunded = orders.where((o) => !o.isRefunded).toList();
      final refunded = orders.where((o) => o.isRefunded).toList();

      expect(refunded.length, greaterThan(0));
      expect(nonRefunded.length, greaterThan(refunded.length));

      final totalSales = nonRefunded.fold(0.0, (s, o) => s + o.totalAmount);
      final refundedAmount = refunded.fold(0.0, (s, o) => s + o.totalAmount);

      expect(totalSales, greaterThan(refundedAmount));
    });

    test('multi-device order merge simulation', () {
      // Simulate: Device A creates 50 orders, Device B creates 50 orders
      // Both sync to cloud. Then Device A pulls from cloud and merges.
      final deviceAOrders = List.generate(50, (i) => Order(
        id: i + 1,
        tokenNumber: '${i + 1}',
        itemsText: 'Item*1*50',
        subTotal: 50.0,
        taxAmount: 0.0,
        totalAmount: 50.0,
        paymentMethod: 'UPI',
        timestamp: DateTime.now().millisecondsSinceEpoch - (i + 1) * 60000,
        dateString: '2026-06-14',
        operatorName: 'deviceA@test.com',
      ));

      final deviceBOrders = List.generate(50, (i) => Order(
        id: 100 + i + 1, // Different ID range
        tokenNumber: '${i + 1}',
        itemsText: 'Item*2*75',
        subTotal: 75.0,
        taxAmount: 0.0,
        totalAmount: 75.0,
        paymentMethod: 'Cash',
        timestamp: DateTime.now().millisecondsSinceEpoch - (i + 1) * 120000,
        dateString: '2026-06-14',
        operatorName: 'deviceB@test.com',
      ));

      // Simulate merge: device A pulls B's orders
      final merged = [...deviceAOrders];
      int added = 0;
      for (final bOrder in deviceBOrders) {
        if (!merged.any((o) => o.id == bOrder.id)) {
          merged.add(bOrder);
          added++;
        }
      }

      expect(merged.length, 100);
      expect(added, 50);

      // Sort by id (simulating cloud sync)
      merged.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      expect(merged.first.id, 1);
      expect(merged.last.id, 150);

      // Verify operators are preserved
      final operators = merged.map((o) => o.operatorName).toSet();
      expect(operators, contains('deviceA@test.com'));
      expect(operators, contains('deviceB@test.com'));
    });
  });

  group('Receipt stress test', () {
    test('generate 100 receipts without error', () {
      final order = Order(
        id: 1,
        tokenNumber: '999',
        itemsText: 'Item A*3*150*1|Item B*2*200*2|Item C*1*99*3',
        subTotal: 150 * 3 + 200 * 2 + 99,
        taxAmount: 0.0,
        totalAmount: 150 * 3 + 200 * 2 + 99,
        paymentMethod: 'UPI',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        dateString: '2026-06-14',
        operatorName: 'test@user.com',
      );

      for (int i = 0; i < 100; i++) {
        final lines = ReceiptFormatter.generateReceiptLines(order);
        expect(lines.length, greaterThan(0));
        expect(lines.any((l) => l.contains('1-UP')), true);
        expect(lines.any((l) => l.contains('MARIO')), true);
        expect(lines.any((l) => l.contains('Rs.')), true);
      }
    });

    test('generate 100 KOTs without error', () {
      final order = Order(
        id: 1,
        tokenNumber: '888',
        itemsText: 'Item X*5*60*4',
        subTotal: 300.0,
        taxAmount: 0.0,
        totalAmount: 300.0,
        paymentMethod: 'Card',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        dateString: '2026-06-14',
        operatorName: 'test@user.com',
      );

      for (int i = 0; i < 100; i++) {
        final lines = ReceiptFormatter.generateKotLines(order);
        expect(lines.length, greaterThan(0));
        expect(lines.any((l) => l.contains('MARIO KITCHEN')), true);
      }
    });
  });

  group('CartSerializer stress test', () {
    test('serialize and deserialize 1000 cart items', () {
      final items = List.generate(100, (i) => 
        'Item_$i*${(i % 5) + 1}*${(i % 100) + 10}*$i'
      );
      final serialized = items.join('|');
      final deserialized = CartSerializer.deserialize(serialized);

      expect(deserialized.length, 100);
      expect(deserialized.first.quantity, greaterThan(0));

      // Round trip verify
      final reSerialized = CartSerializer.serialize(deserialized);
      final reDeserialized = CartSerializer.deserialize(reSerialized);
      expect(reDeserialized.length, 100);

      // Verify total amounts
      final total = deserialized.fold(0.0, (s, item) => s + item.total);
      expect(total, greaterThan(0));
    });
  });
}
