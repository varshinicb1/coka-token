class BankStatementItem {
  final String statementId;
  final String dateString;
  final String description;
  final double amount;
  final String paymentType;
  final bool isMatched;
  final int? matchedOrderId;
  final String confidence;

  BankStatementItem({
    required this.statementId,
    required this.dateString,
    required this.description,
    required this.amount,
    required this.paymentType,
    this.isMatched = false,
    this.matchedOrderId,
    this.confidence = 'NONE',
  });

  BankStatementItem copyWith({
    String? statementId,
    String? dateString,
    String? description,
    double? amount,
    String? paymentType,
    bool? isMatched,
    int? matchedOrderId,
    String? confidence,
  }) =>
      BankStatementItem(
        statementId: statementId ?? this.statementId,
        dateString: dateString ?? this.dateString,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        paymentType: paymentType ?? this.paymentType,
        isMatched: isMatched ?? this.isMatched,
        matchedOrderId: matchedOrderId ?? this.matchedOrderId,
        confidence: confidence ?? this.confidence,
      );
}
