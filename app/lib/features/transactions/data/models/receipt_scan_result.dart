/// Parsed receipt photo data. Fields are nullable because the model may miss
/// some; the user reviews them in the form before anything is saved.
class ReceiptScanResult {
  final String? type;
  final double? amount;
  final DateTime? date;
  final String? description;

  const ReceiptScanResult({
    this.type,
    this.amount,
    this.date,
    this.description,
  });

  factory ReceiptScanResult.fromMap(Map<String, dynamic> map) {
    return ReceiptScanResult(
      type: map['type'] as String?,
      amount: (map['amount'] as num?)?.toDouble(),
      date: _parseDate(map['date']),
      description: _cleanString(map['description']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String? _cleanString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
