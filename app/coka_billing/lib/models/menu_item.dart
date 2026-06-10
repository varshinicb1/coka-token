class MenuItem {
  final int? id;
  final String name;
  final double rate;
  final String category;
  final int openingStock;
  final int usedStock;
  final int remainingStock;
  final String description;

  MenuItem({
    this.id,
    required this.name,
    required this.rate,
    required this.category,
    required this.openingStock,
    this.usedStock = 0,
    this.remainingStock = 0,
    this.description = '',
  });

  MenuItem copyWith({
    int? id,
    String? name,
    double? rate,
    String? category,
    int? openingStock,
    int? usedStock,
    int? remainingStock,
    String? description,
  }) =>
      MenuItem(
        id: id ?? this.id,
        name: name ?? this.name,
        rate: rate ?? this.rate,
        category: category ?? this.category,
        openingStock: openingStock ?? this.openingStock,
        usedStock: usedStock ?? this.usedStock,
        remainingStock: remainingStock ?? this.remainingStock,
        description: description ?? this.description,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'rate': rate,
        'category': category,
        'openingStock': openingStock,
        'usedStock': usedStock,
        'remainingStock': remainingStock,
        'description': description,
      };

  factory MenuItem.fromMap(Map<String, dynamic> map) => MenuItem(
        id: map['id'] as int?,
        name: map['name'] as String,
        rate: (map['rate'] as num).toDouble(),
        category: map['category'] as String,
        openingStock: map['openingStock'] as int,
        usedStock: map['usedStock'] as int? ?? 0,
        remainingStock: map['remainingStock'] as int? ?? 0,
        description: map['description'] as String? ?? '',
      );
}
