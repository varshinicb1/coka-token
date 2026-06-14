class Expense {
  final int? id;
  final String description;
  final double amount;
  final int timestamp;
  final String dateString;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    this.timestamp = 0,
    required this.dateString,
  });

  Expense copyWith({
    int? id,
    String? description,
    double? amount,
    int? timestamp,
    String? dateString,
  }) =>
      Expense(
        id: id ?? this.id,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        timestamp: timestamp ?? this.timestamp,
        dateString: dateString ?? this.dateString,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'amount': amount,
        'timestamp': timestamp,
        'dateString': dateString,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as int?,
        description: map['description'] as String,
        amount: (map['amount'] as num).toDouble(),
        timestamp: map['timestamp'] as int? ?? 0,
        dateString: map['dateString'] as String,
      );
}
