/// A movement read from a bank statement screenshot. The model output is
/// untrusted, so [fromMap] drops anything malformed instead of guessing.
class ScannedMovement {
  /// 'income' or 'expense'.
  final String type;

  /// Always positive; the direction lives in [type].
  final double amount;

  /// Null when the date could not be read.
  final DateTime? date;

  final String? description;

  const ScannedMovement({
    required this.type,
    required this.amount,
    this.date,
    this.description,
  });

  /// Amount with the sign the pending list uses: expenses are negative.
  double get signedAmount => type == 'expense' ? -amount : amount;

  ScannedMovement copyWith({
    String? type,
    double? amount,
    DateTime? date,
    String? description,
  }) {
    return ScannedMovement(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }

  /// Returns null when [map] is not a usable movement.
  static ScannedMovement? fromMap(Object? map) {
    if (map is! Map) return null;

    final type = map['type'];
    if (type != 'income' && type != 'expense') return null;

    final amount = map['amount'];
    if (amount is! num || !amount.isFinite || amount <= 0) return null;

    final rawDate = map['date'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;

    final rawDescription = map['description'];
    final description =
        rawDescription is String && rawDescription.trim().isNotEmpty
            ? rawDescription.trim()
            : null;

    return ScannedMovement(
      type: type as String,
      amount: (amount * 100).round() / 100,
      date: date,
      description: description,
    );
  }

  /// Reads the `movements` list of the Edge Function response. Anything that
  /// is not a list yields an empty result.
  static List<ScannedMovement> listFromResponse(Object? data) {
    if (data is! Map) return const [];
    final raw = data['movements'];
    if (raw is! List) return const [];
    return raw.map(fromMap).whereType<ScannedMovement>().toList();
  }
}

/// A movement already known to the account (saved or queued), used to flag
/// scanned lines that may be duplicates. [amount] is signed.
typedef KnownMovement = ({double amount, DateTime date});

/// True when [movement] matches a [known] one on amount (to the cent) and on
/// calendar day. Movements without a date are never flagged.
bool isPossibleDuplicate(
  ScannedMovement movement,
  Iterable<KnownMovement> known,
) {
  final date = movement.date;
  if (date == null) return false;

  final cents = (movement.signedAmount * 100).round();
  return known.any(
    (k) =>
        (k.amount * 100).round() == cents &&
        k.date.year == date.year &&
        k.date.month == date.month &&
        k.date.day == date.day,
  );
}
