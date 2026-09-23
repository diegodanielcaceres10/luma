/// Resultado de interpretar la foto de un ticket/factura a través de la
/// Edge Function `gemini-image-reader` (Gemini API, tier gratuito).
///
/// Todos los campos son opcionales a propósito: el modelo puede no leer
/// alguno de los datos, y el usuario los completa o corrige a mano en el
/// formulario antes de guardar — este resultado nunca se guarda solo.
class ReceiptScanResult {
  final String? type;
  final double? amount;
  final DateTime? date;
  final String? description;
  final String? categoryName;

  const ReceiptScanResult({
    this.type,
    this.amount,
    this.date,
    this.description,
    this.categoryName,
  });

  factory ReceiptScanResult.fromMap(Map<String, dynamic> map) {
    return ReceiptScanResult(
      type: map['type'] as String?,
      amount: (map['amount'] as num?)?.toDouble(),
      date: _parseDate(map['date']),
      description: _cleanString(map['description']),
      categoryName: _cleanString(map['category']),
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
