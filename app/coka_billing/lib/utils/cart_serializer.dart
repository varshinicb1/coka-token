import '../models/cart_item.dart';

class CartSerializer {
  static String serialize(List<CartItem> items) {
    return items.map((e) => '${e.name}*${e.quantity}*${e.rate}*${e.itemId ?? ''}').join('|');
  }

  static List<CartItem> deserialize(String itemsText) {
    if (itemsText.isEmpty) return [];
    return itemsText.split('|').map((part) {
      final segments = part.split('*');
      if (segments.length >= 3) {
        return CartItem(
          name: segments[0],
          quantity: int.tryParse(segments[1]) ?? 1,
          rate: double.tryParse(segments[2]) ?? 0.0,
          itemId: segments.length >= 4 ? int.tryParse(segments[3]) : null,
        );
      }
      return null;
    }).whereType<CartItem>().toList();
  }
}
