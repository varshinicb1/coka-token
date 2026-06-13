class CartItem {
  final int? itemId;
  final String name;
  final double rate;
  final int quantity;

  const CartItem({
    this.itemId,
    required this.name,
    required this.rate,
    this.quantity = 1,
  });

  CartItem copyWith({
    int? itemId,
    String? name,
    double? rate,
    int? quantity,
  }) =>
      CartItem(
        itemId: itemId ?? this.itemId,
        name: name ?? this.name,
        rate: rate ?? this.rate,
        quantity: quantity ?? this.quantity,
      );

  double get total => rate * quantity;
}
