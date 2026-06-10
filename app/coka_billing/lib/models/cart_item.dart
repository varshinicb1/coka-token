class CartItem {
  final String name;
  final double rate;
  final int quantity;

  const CartItem({
    required this.name,
    required this.rate,
    this.quantity = 1,
  });

  CartItem copyWith({
    String? name,
    double? rate,
    int? quantity,
  }) =>
      CartItem(
        name: name ?? this.name,
        rate: rate ?? this.rate,
        quantity: quantity ?? this.quantity,
      );

  double get total => rate * quantity;
}
