import 'package:flutter_test/flutter_test.dart';
import 'package:coka_billing/models/cart_item.dart';
import 'package:coka_billing/utils/cart_serializer.dart';

void main() {
  group('CartSerializer', () {
    test('serialize empty list returns empty string', () {
      expect(CartSerializer.serialize([]), '');
    });

    test('serialize single item', () {
      final items = [CartItem(name: 'Tea', rate: 10.0, quantity: 2)];
      expect(CartSerializer.serialize(items), 'Tea*2*10.0*');
    });

    test('serialize multiple items', () {
      final items = [
        CartItem(name: 'Tea', rate: 10.0, quantity: 2),
        CartItem(name: 'Coffee', rate: 15.0, quantity: 1),
      ];
      expect(CartSerializer.serialize(items), 'Tea*2*10.0*|Coffee*1*15.0*');
    });

    test('serialize item with id', () {
      final items = [CartItem(itemId: 5, name: 'Tea', rate: 10.0, quantity: 1)];
      expect(CartSerializer.serialize(items), 'Tea*1*10.0*5');
    });

    test('deserialize empty string returns empty list', () {
      expect(CartSerializer.deserialize(''), []);
    });

    test('deserialize single item', () {
      final result = CartSerializer.deserialize('Tea*2*10.0*');
      expect(result.length, 1);
      expect(result[0].name, 'Tea');
      expect(result[0].quantity, 2);
      expect(result[0].rate, 10.0);
      expect(result[0].itemId, isNull);
    });

    test('deserialize multiple items', () {
      final result = CartSerializer.deserialize('Tea*2*10.0*|Coffee*1*15.0*');
      expect(result.length, 2);
      expect(result[0].name, 'Tea');
      expect(result[1].name, 'Coffee');
    });

    test('deserialize item with id', () {
      final result = CartSerializer.deserialize('Tea*1*10.0*5');
      expect(result.length, 1);
      expect(result[0].itemId, 5);
    });

    test('deserialize malformed entry returns empty list', () {
      final result = CartSerializer.deserialize('incomplete');
      expect(result, isEmpty);
    });

    test('round trip', () {
      final original = [
        CartItem(itemId: 1, name: 'Kaalan', rate: 79.0, quantity: 3),
        CartItem(name: 'Puri', rate: 89.0, quantity: 2),
      ];
      final serialized = CartSerializer.serialize(original);
      final deserialized = CartSerializer.deserialize(serialized);
      expect(deserialized.length, original.length);
      for (var i = 0; i < original.length; i++) {
        expect(deserialized[i].name, original[i].name);
        expect(deserialized[i].quantity, original[i].quantity);
        expect(deserialized[i].rate, original[i].rate);
        expect(deserialized[i].itemId, original[i].itemId);
      }
    });
  });
}
