String buildUpiQrPayload({
  required String upiId,
  required String merchantName,
  double amount = 0,
  String transactionNote = '',
  String transactionRef = '',
  String currency = 'INR',
}) {
  final params = <String, String>{
    'pa': upiId,
    'pn': merchantName,
  };
  if (amount > 0) params['am'] = amount.toStringAsFixed(2);
  if (transactionNote.isNotEmpty) params['tn'] = transactionNote;
  if (transactionRef.isNotEmpty) params['tr'] = transactionRef;
  params['cu'] = currency;

  return 'upi://pay?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
}
