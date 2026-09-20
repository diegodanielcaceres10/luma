class TransactionCategory {
  final String? id;
  final String name;
  final String? color;

  const TransactionCategory({
    this.id,
    required this.name,
    this.color,
  });

  factory TransactionCategory.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const TransactionCategory(name: 'Sin categoría');
    }
    return TransactionCategory(
      id: map['id'] as String?,
      name: map['name'] as String? ?? 'Sin categoría',
      color: map['color'] as String?,
    );
  }
}

class TransactionAccount {
  final String? id;
  final String name;
  final String? color;

  const TransactionAccount({
    this.id,
    required this.name,
    this.color,
  });

  factory TransactionAccount.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const TransactionAccount(name: 'Sin cuenta');
    }
    return TransactionAccount(
      id: map['id'] as String?,
      name: map['name'] as String? ?? 'Sin cuenta',
      color: map['color'] as String?,
    );
  }
}

class TransactionEntry {
  final String id;
  final String type; // income | expense
  final double amount;
  final String? description;
  final DateTime date;
  final TransactionCategory category;
  final TransactionAccount account;

  /// true en las dos filas que arma una transferencia entre cuentas
  /// propias (ver [TransactionViewModel.createTransfer]): el dinero no
  /// entra ni sale de verdad, así que [TransactionViewModel._sumByType] y
  /// [TransactionViewModel._breakdownOf] la excluyen de todo total de
  /// ingresos/gastos y del desglose por categoría.
  final bool isTransfer;

  const TransactionEntry({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    required this.category,
    required this.account,
    this.isTransfer = false,
  });

  bool get isIncome => type == 'income';

  factory TransactionEntry.fromMap(Map<String, dynamic> map) {
    return TransactionEntry(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      category: TransactionCategory.fromMap(
        map['categories'] as Map<String, dynamic>?,
      ),
      account: TransactionAccount.fromMap(
        map['accounts'] as Map<String, dynamic>?,
      ),
      isTransfer: map['is_transfer'] as bool? ?? false,
    );
  }
}
