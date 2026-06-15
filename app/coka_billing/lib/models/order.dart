class Order {
  final int? id;
  final String tokenNumber;
  final String itemsText;
  final double subTotal;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final int timestamp;
  final String dateString;
  final String operatorName;
  final bool isRefunded;
  final String? gatewayTransactionId;
  final String? gatewayStatus;
  final bool reconciled;
  final int reconciledAt;
  final String? bankStatementMatchId;
  final int tokenSlot;
  final String tokenPhrase;

  Order({
    this.id,
    required this.tokenNumber,
    required this.itemsText,
    required this.subTotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    this.timestamp = 0,
    required this.dateString,
    required this.operatorName,
    this.isRefunded = false,
    this.gatewayTransactionId,
    this.gatewayStatus,
    this.reconciled = false,
    this.reconciledAt = 0,
    this.bankStatementMatchId,
    this.tokenSlot = 1,
    this.tokenPhrase = '',
  });

  Order copyWith({
    int? id,
    String? tokenNumber,
    String? itemsText,
    double? subTotal,
    double? taxAmount,
    double? totalAmount,
    String? paymentMethod,
    int? timestamp,
    String? dateString,
    String? operatorName,
    bool? isRefunded,
    String? gatewayTransactionId,
    String? gatewayStatus,
    bool? reconciled,
    int? reconciledAt,
    String? bankStatementMatchId,
    int? tokenSlot,
    String? tokenPhrase,
  }) =>
      Order(
        id: id ?? this.id,
        tokenNumber: tokenNumber ?? this.tokenNumber,
        itemsText: itemsText ?? this.itemsText,
        subTotal: subTotal ?? this.subTotal,
        taxAmount: taxAmount ?? this.taxAmount,
        totalAmount: totalAmount ?? this.totalAmount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        timestamp: timestamp ?? this.timestamp,
        dateString: dateString ?? this.dateString,
        operatorName: operatorName ?? this.operatorName,
        isRefunded: isRefunded ?? this.isRefunded,
        gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
        gatewayStatus: gatewayStatus ?? this.gatewayStatus,
        reconciled: reconciled ?? this.reconciled,
        reconciledAt: reconciledAt ?? this.reconciledAt,
        bankStatementMatchId:
            bankStatementMatchId ?? this.bankStatementMatchId,
        tokenSlot: tokenSlot ?? this.tokenSlot,
        tokenPhrase: tokenPhrase ?? this.tokenPhrase,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'tokenNumber': tokenNumber,
        'itemsText': itemsText,
        'subTotal': subTotal,
        'taxAmount': taxAmount,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'timestamp': timestamp,
        'dateString': dateString,
        'operatorName': operatorName,
        'isRefunded': isRefunded ? 1 : 0,
        'gatewayTransactionId': gatewayTransactionId,
        'gatewayStatus': gatewayStatus,
        'reconciled': reconciled ? 1 : 0,
        'reconciledAt': reconciledAt,
        'bankStatementMatchId': bankStatementMatchId,
        'tokenSlot': tokenSlot,
        'tokenPhrase': tokenPhrase,
      };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
        id: map['id'] as int?,
        tokenNumber: map['tokenNumber'] as String,
        itemsText: map['itemsText'] as String,
        subTotal: (map['subTotal'] as num).toDouble(),
        taxAmount: (map['taxAmount'] as num).toDouble(),
        totalAmount: (map['totalAmount'] as num).toDouble(),
        paymentMethod: map['paymentMethod'] as String,
        timestamp: map['timestamp'] as int? ?? 0,
        dateString: map['dateString'] as String,
        operatorName: map['operatorName'] as String,
        isRefunded: map['isRefunded'] == 1,
        gatewayTransactionId: map['gatewayTransactionId'] as String?,
        gatewayStatus: map['gatewayStatus'] as String?,
        reconciled: map['reconciled'] == 1,
        reconciledAt: map['reconciledAt'] as int? ?? 0,
        bankStatementMatchId: map['bankStatementMatchId'] as String?,
        tokenSlot: map['tokenSlot'] as int? ?? 1,
        tokenPhrase: map['tokenPhrase'] as String? ?? '',
      );
}
