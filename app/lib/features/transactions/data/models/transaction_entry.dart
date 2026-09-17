class TransactionCategory {
  final String? id;
  final String name;
  final String? color;
  final String? icon;

  const TransactionCategory({
    this.id,
    required this.name,
    this.color,
    this.icon,
  });

  factory TransactionCategory.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const TransactionCategory(name: 'Sin categoría');
    }
    return TransactionCategory(
      id: map['id'] as String?,
      name: map['name'] as String? ?? 'Sin categoría',
      color: map['color'] as String?,
      icon: map['icon'] as String?,
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

  const TransactionEntry({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    required this.category,
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
    );
  }
}
